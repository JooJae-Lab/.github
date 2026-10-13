<#
.SYNOPSIS
  JooJae-Lab 브랜치 전략(룰셋 + 검사 워크플로 + 머지 설정)을 레포에 적용한다.

.EXAMPLE
  ./scripts/apply-rules.ps1 -Repo my-app                          # 전체 룰 적용
  ./scripts/apply-rules.ps1 -Repo my-app -Rules main,feature      # 골라서 적용
  ./scripts/apply-rules.ps1 -Repo my-app -Rules hotfix -Remove    # 골라서 제거
  ./scripts/apply-rules.ps1 -All                                  # 모든 public 레포에 전체 적용
  ./scripts/apply-rules.ps1 -Repo my-app -Ci on                   # CI(verify) 필수 체크 강제 등록
  ./scripts/apply-rules.ps1 -Repo my-app -FilesOnly               # 룰 없이 파일만 추가 (새 레포 초기 세팅 전)

  추가 파일: .github/workflows/branch-policy.yml, auto-back-merge.yml,
             .claude/settings.json (이 레포에서만 joojae 플러그인 활성화, AI 첨부 문구 끄기)

  CI 필수 체크 (-Ci): auto(기본) 는 레포 워크플로에 `verify` 잡이 있으면 main/release/feature 룰에 필수 체크로 등록

.NOTES
  필요: GitHub CLI(gh) 로그인 + 레포 Admin 권한
  Free 플랜에서는 public 레포에서만 룰셋이 강제된다.
#>
param(
  [string]$Repo,
  [string[]]$Rules = @('main', 'release', 'feature', 'hotfix'),
  [switch]$Remove,
  [switch]$SkipWorkflows,
  [switch]$FilesOnly,
  [switch]$All,
  [ValidateSet('auto', 'on', 'off')]
  [string]$Ci = 'auto',
  [string]$Org = 'JooJae-Lab'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

if (-not $Repo -and -not $All) {
  throw '-Repo <레포이름> 또는 -All 을 지정하세요.'
}

# "main,feature" 처럼 한 문자열로 넘어온 경우도 처리
$Rules = $Rules -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$invalid = $Rules | Where-Object { $_ -notin 'main', 'release', 'feature', 'hotfix' }
if ($invalid) { throw "알 수 없는 룰: $($invalid -join ', ') (가능: main, release, feature, hotfix)" }

function Invoke-Gh {
  param([Parameter(ValueFromRemainingArguments)][string[]]$GhArgs)
  $out = & gh @GhArgs 2>&1
  if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
  return $out
}

# 머지 방식 등 레포 기본 설정
function Set-RepoSettings($full, $visibility) {
  Invoke-Gh api -X PATCH "repos/$full" `
    -F allow_merge_commit=true -F allow_squash_merge=true -F allow_rebase_merge=false `
    -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE `
    -f squash_merge_commit_message=COMMIT_MESSAGES | Out-Null
  if ($visibility -eq 'public') {
    '{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}' |
      gh api -X PATCH "repos/$full" --input - | Out-Null
  }
  Write-Host '  ✓ 머지 설정 (Merge/Squash 허용, Rebase 비활성, 머지 후 브랜치 자동 삭제)'
}

# 검사/백머지 워크플로와 Claude Code 레포 설정을 기본 브랜치에 추가 (룰셋 적용 전에 해야 직접 커밋 가능)
function Add-Workflows($full) {
  $files = @(Get-ChildItem "$root/templates/workflows" -Filter *.yml | ForEach-Object {
      @{ Source = $_; Path = ".github/workflows/$($_.Name)"; Message = "ci: $($_.BaseName) 워크플로 추가" } })
  $files += @{ Source = Get-Item "$root/templates/claude/settings.json"; Path = '.claude/settings.json'; Message = 'chore: Claude Code 레포 설정 추가' }
  foreach ($item in $files) {
    $file = $item.Source
    $path = $item.Path
    & gh api "repos/$full/contents/$path" --silent 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Host "  - $path 이미 있음"; continue }
    $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($file.FullName))
    try {
      Invoke-Gh api -X PUT "repos/$full/contents/$path" `
        -f "message=$($item.Message)" -f "content=$content" | Out-Null
      Write-Host "  ✓ $path 추가"
    }
    catch {
      Write-Warning "  $path 추가 실패 (main 룰이 이미 걸려 있으면 PR 로 추가하세요): $_"
    }
  }
}

# 레포 워크플로 중 `verify` 잡이 있는지 확인 (CI 최종 판정 잡 이름 규칙)
function Test-CiVerifyJob($full) {
  $files = @(& gh api "repos/$full/contents/.github/workflows" --jq '.[] | select(.name | test("\\.ya?ml$")) | .path' 2>$null)
  if ($LASTEXITCODE -ne 0) { return $false }
  foreach ($path in $files) {
    $content = & gh api "repos/$full/contents/$path" -H 'Accept: application/vnd.github.raw' 2>$null
    if (($content -join "`n") -match '(?m)^\s{2}verify:\s*$') { return $true }
  }
  return $false
}

# 룰셋 JSON 에 CI 필수 체크(verify) 추가한 임시 파일 경로 반환
function Get-RulesetFile($name, $requireCi) {
  $json = "$root/rulesets/$name.json"
  if (-not $requireCi -or $name -eq 'hotfix') { return $json }
  $ruleset = Get-Content $json -Raw | ConvertFrom-Json
  $checks = ($ruleset.rules | Where-Object { $_.type -eq 'required_status_checks' }).parameters.required_status_checks
  $checks += [pscustomobject]@{ context = 'verify' }
  ($ruleset.rules | Where-Object { $_.type -eq 'required_status_checks' }).parameters.required_status_checks = $checks
  $tmp = Join-Path ([IO.Path]::GetTempPath()) "ruleset-$name-$PID.json"
  $ruleset | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8NoBOM $tmp
  return $tmp
}

function Set-Rulesets($full, $requireCi) {
  $existing = @(Invoke-Gh api "repos/$full/rulesets?includes_parents=false" | ConvertFrom-Json)
  foreach ($name in $Rules) {
    $found = $existing | Where-Object { $_.name -eq $name -and $_.source_type -eq 'Repository' }
    if ($Remove) {
      if ($found) { Invoke-Gh api -X DELETE "repos/$full/rulesets/$($found.id)" | Out-Null; Write-Host "  ✓ 룰 '$name' 제거" }
      else { Write-Host "  - 룰 '$name' 없음" }
      continue
    }
    $json = Get-RulesetFile $name $requireCi
    try {
      if ($found) {
        Invoke-Gh api -X PUT "repos/$full/rulesets/$($found.id)" --input $json | Out-Null
        Write-Host "  ✓ 룰 '$name' 업데이트"
      }
      else {
        Invoke-Gh api -X POST "repos/$full/rulesets" --input $json | Out-Null
        Write-Host "  ✓ 룰 '$name' 생성"
      }
    }
    catch {
      Write-Warning "  룰 '$name' 적용 실패: $_"
    }
  }
}

$targets = if ($All) {
  Invoke-Gh repo list $Org --visibility public --no-archived --limit 1000 --json name --jq '.[].name' |
    Where-Object { $_ -ne '.github' }
}
else { @($Repo) }

foreach ($name in $targets) {
  $full = "$Org/$name"
  $info = Invoke-Gh api "repos/$full" | ConvertFrom-Json
  Write-Host "`n▶ $full ($($info.visibility))"
  if ($info.visibility -ne 'public') {
    Write-Warning '  private 레포: Free 플랜에서는 룰셋이 강제되지 않습니다.'
  }
  if (-not $Remove) {
    Set-RepoSettings $full $info.visibility
    if (-not $SkipWorkflows) { Add-Workflows $full }
  }
  if ($FilesOnly) { continue }
  $requireCi = $false
  if (-not $Remove) {
    $requireCi = switch ($Ci) { 'on' { $true } 'off' { $false } default { Test-CiVerifyJob $full } }
    if ($requireCi) { Write-Host '  ✓ CI 필수 체크 등록 (verify)' }
    elseif ($Ci -eq 'auto') { Write-Host '  - CI(verify 잡) 없음 → 필수 체크 미등록. CI 를 만든 뒤 다시 실행하세요' }
  }
  Set-Rulesets $full $requireCi
}
Write-Host "`n완료"

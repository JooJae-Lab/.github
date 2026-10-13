# 브랜치 전략 & 협업 가이드

JooJae-Lab 의 모든 레포에 적용되는 브랜치 전략, PR 규칙, 룰 적용 방법을 정리한 문서입니다.

## 1. 한눈에 보기

```
main ◀── release/v1.3.0 ◀── feature/v1.3.0 ◀── feat/login-page
  │          (Merge)            (Merge)      ◀── fix/login-api   (Squash)
  │
  └──▶ hotfix/v1.2.1 ──▶ main   (main 에서 바로 따서 바로 PR)
                          │
                          └──▶ 백머지 PR (main → 진행 중인 feature/release, 자동 생성)
```

## 2. 브랜치 종류

| 브랜치 | 형식 | 역할 | 어디서 만드나 |
|---|---|---|---|
| `main` | 고정 | 배포된(운영) 코드 | - |
| `release/vX.Y.Z` | `release/v1.3.0` | 배포 준비(QA) 브랜치 | `main` |
| `feature/vX.Y.Z` | `feature/v1.3.0` | 해당 버전의 개발 통합 브랜치 | `main` |
| 작업 브랜치 | `feat/…`, `fix/…`, `refactor/…`, `chore/…`, `docs/…`, `test/…`, `style/…`, `perf/…`, `ci/…`, `build/…` | 실제 작업 단위 | `feature/vX.Y.Z` |
| `hotfix/vX.Y.Z` | `hotfix/v1.2.1` | 운영 긴급 수정 | `main` |

- 모든 레포의 기본 브랜치는 **`main`** 입니다. (`master` 사용 안 함)
- 버전은 항상 **`v` + 숫자 3자리** (`v1.3.0`) 형식입니다. 배포 태그도 `v1.3.0` 으로 답니다.
- 작업 브랜치 이름은 소문자 + 하이픈 권장: `feat/login-page`, `fix/login-api`

## 3. PR 규칙

| PR 방향 | 리뷰 | 머지 방식 |
|---|---|---|
| 작업 브랜치 → `feature/vX.Y.Z` | 필요 없음 | **Squash** |
| `feature/vX.Y.Z` → `release/vX.Y.Z` (같은 버전) | 필요 없음 | **Merge commit** |
| `release/vX.Y.Z` → `main` | **1명 이상 승인** (본인 제외) | **Merge commit** |
| `hotfix/vX.Y.Z` → `main` | **1명 이상 승인** (본인 제외) | **Merge commit** |
| `main` → `feature/*`, `release/*` (백머지) | 필요 없음 | **Merge commit** (Squash 금지) |

- 모든 PR 은 **`branch-policy / check`** 와 (CI 가 있는 레포는) **`verify`** 통과가 필수입니다. → [9. 커밋 컨벤션](#9-커밋pr-컨벤션), [10. CI](#10-ci)
- 위 표 이외의 방향으로 PR 을 열면 `branch-policy / check` 가 실패하고 머지할 수 없습니다.
  - 잘못 연 PR 은 닫고 올바른 방향으로 다시 여세요. 검사 결과는 커밋 단위로 남기 때문에, 같은 브랜치로 연 올바른 PR 도 계속 막혀 있다면 커밋을 하나 더 push 하세요. (`git commit --allow-empty -m "chore: retrigger checks" && git push`)
- `main`, `release/*`, `feature/*` 에는 **직접 push 불가** (PR 로만), **force push · 삭제 불가**.
- `hotfix/*` 는 직접 push 가능 (force push 만 불가).
- GitHub 은 PR 작성자가 자기 PR 을 승인할 수 없습니다. 그래서 `main` 으로 가는 PR 은 반드시 다른 사람이 리뷰합니다.
- **Owner 만** 긴급 시 리뷰 없이 `main` 에 머지할 수 있습니다. (PR 화면의 "Merge without waiting for requirements to be met")
- Owner 우회는 `main` 에만 있습니다. `release`/`feature`/`hotfix` 룰은 Owner 도 똑같이 지켜야 합니다.
- 머지된 작업 브랜치는 자동 삭제됩니다. `release/*`, `feature/*` 는 삭제 금지라 남습니다.
  지난 버전 브랜치를 정리하려면 레포 **Settings → Rules → Rulesets** 에서 해당 룰을 잠시 `Disabled` 로 바꾸고 삭제한 뒤 다시 `Active` 로 돌려놓으세요.

## 4. 작업 흐름

### 4-1. 새 버전 개발 시작

```bash
git fetch origin
git switch -c feature/v1.3.0 origin/main
git push -u origin feature/v1.3.0
```

### 4-2. 일반 작업

```bash
git switch feature/v1.3.0 && git pull
git switch -c feat/login-page
# 작업 & 커밋
git push -u origin feat/login-page
```
→ PR: `feat/login-page` → `feature/v1.3.0`, **Squash and merge**

### 4-3. 릴리즈

```bash
git fetch origin
git switch -c release/v1.3.0 origin/main
git push -u origin release/v1.3.0
```
1. PR: `feature/v1.3.0` → `release/v1.3.0`, **Create a merge commit**
2. QA 중 수정이 필요하면 `feature/v1.3.0` 에서 작업 브랜치로 고치고 다시 1번
3. PR: `release/v1.3.0` → `main`, 리뷰 1명 승인 후 **Create a merge commit**
4. 태그 & 릴리즈 노트: Releases → Draft a new release → 태그 `v1.3.0` (target: `main`)

### 4-4. 핫픽스

```bash
git fetch origin
git switch -c hotfix/v1.2.1 origin/main
# 수정 & 커밋
git push -u origin hotfix/v1.2.1
```
1. PR: `hotfix/v1.2.1` → `main`, 리뷰 1명 승인 후 **Create a merge commit**
2. 태그 `v1.2.1` 릴리즈
3. **백머지**: 머지 즉시 hotfix 보다 높은 버전(개발 중인 버전)의 `feature/v*`, `release/v*` 로 가는 `main → …` PR 이 자동으로 열립니다. **Create a merge commit** 으로 머지하세요.
4. 로컬에서는 해당 브랜치에서 `git pull` 만 하면 됩니다. 작업 중인 `feat/*` 에도 반영하려면 `git merge origin/feature/v1.3.0`.

## 5. 백머지 (back-merge)

`main` 에 먼저 들어간 수정(핫픽스)을 진행 중인 `feature/*`, `release/*` 에 반영하는 것입니다.
안 하면 다음 릴리즈에서 고친 버그가 되살아나거나 충돌이 납니다.

- 자동 PR 이 생성되면 **Merge commit** 으로 머지 (Squash 하면 git 이 같은 변경으로 인식하지 못해 나중에 충돌)
- 자동 PR 에 충돌이 있으면 로컬에서 해결:

```bash
git fetch origin
git switch -c chore/back-merge-v1.2.1 origin/feature/v1.3.0
git merge origin/main      # 충돌 해결 후 commit
git push -u origin chore/back-merge-v1.2.1
```
→ 자동 PR 은 닫고, `chore/back-merge-v1.2.1` → `feature/v1.3.0` 을 **Merge commit** 으로 머지

## 6. 권한

| 역할 | 대상 | 권한 |
|---|---|---|
| Owner | org 관리자 | org 설정, 결제, 멤버 관리 + 모든 레포 |
| Member | 그 외 멤버 | 모든 레포 Admin (생성, 삭제, 설정, 룰 변경). org 설정 불가 |

## 7. 룰 적용 (레포마다)

GitHub Free 플랜에서는 **public 레포에서만** 룰셋이 강제됩니다. private 레포는 이 문서를 관례로 지킵니다.
룰은 레포마다 따로 걸리므로, **새 레포를 만들면 아래 스크립트를 한 번 실행**하세요.

준비: [GitHub CLI](https://cli.github.com/) 설치 후 `gh auth login`, 이 레포 clone

```powershell
git clone https://github.com/JooJae-Lab/.github.git joojae-github
cd joojae-github

./scripts/apply-rules.ps1 -Repo my-app                         # 기본 룰 전체 적용
./scripts/apply-rules.ps1 -Repo my-app -Rules main,feature     # 원하는 룰만 골라서 적용
./scripts/apply-rules.ps1 -Repo my-app -Rules hotfix -Remove   # 특정 룰 제거
./scripts/apply-rules.ps1 -All                                 # 모든 public 레포에 일괄 적용
./scripts/apply-rules.ps1 -Repo my-app -Ci off                 # CI 필수 체크 빼고 적용 (기본 auto)
```

스크립트가 하는 일:
1. 머지 설정: Merge commit · Squash 허용, Rebase 비활성, 머지 후 브랜치 자동 삭제, (public) 비밀값 유출 차단
2. `.github/workflows/branch-policy.yml`, `auto-back-merge.yml` 추가
3. 선택한 룰셋 생성/업데이트
4. 레포 워크플로에 `verify` 잡이 있으면 `main`·`release`·`feature` 룰에 필수 체크로 등록 (`-Ci auto`)

| 룰 이름 | 대상 | 내용 |
|---|---|---|
| `main` | 기본 브랜치 | PR 필수, 승인 1명, Merge commit 만, `branch-policy / check`·`verify` 필수, force push·삭제 금지, Owner 우회 허용 |
| `release` | `release/v*` | PR 필수, Merge commit 만, `branch-policy / check`·`verify` 필수, force push·삭제 금지 |
| `feature` | `feature/v*` | PR 필수, Squash·Merge 허용, `branch-policy / check`·`verify` 필수, force push·삭제 금지 |
| `hotfix` | `hotfix/v*` | force push 금지 (직접 push 는 허용) |

레포별로 다르게 하고 싶으면 스크립트로 일부만 적용하거나, 레포 **Settings → Rules → Rulesets** 에서 직접 수정하세요.
룰 원본은 [`rulesets/`](../rulesets), 공용 워크플로는 [`.github/workflows/`](../.github/workflows) 에 있습니다.

## 8. 비밀값 주의 (public 레포)

- `.env`, API 키, 토큰은 절대 커밋하지 않습니다. `.gitignore` 에 추가하세요.
- CI 용 비밀값은 레포 **Settings → Secrets and variables → Actions** 에 저장합니다.
- 실수로 올렸다면 커밋을 지워도 이미 노출된 것이므로 **즉시 키를 폐기하고 재발급**하세요.

## 9. 커밋·PR 컨벤션

```
<타입>(<범위>): <한국어 설명> (<작업 ID>)
```

- 예: `feat: 로그인 화면 추가 (P1-3)`, `fix(auth): 세션 만료 시 무한 리다이렉트 수정`, `release: v1.2.0`
- 타입: `feat` `fix` `refactor` `perf` `style` `docs` `test` `chore` `ci` `build` `revert` `release`
- 설명은 한국어, 명사형 종결(`추가`, `구현`, `수정`), 마침표 없음
- **PR 제목도 같은 형식**입니다. 작업 → feature 는 Squash 라 PR 제목이 그대로 커밋 메시지가 됩니다
- PR 본문: `## 개요` / `## 변경 사항` / `## 검증` / `## 참고` (개조식)
- **AI 첨부 문구 금지**: `Co-Authored-By: Claude …`, `Generated with [Claude Code]` 등 AI 도구 서명을 커밋·PR 에 넣지 않습니다

`branch-policy / check` 가 PR 마다 검사하는 것:

| 검사 | 실패 예 |
|---|---|
| PR 방향 | `feat/x` → `main` |
| PR 제목 형식 | `Update stuff` |
| PR 안의 모든 커밋 제목 형식 (GitHub 머지 커밋 `Merge …` 제외) | `update stuff` |
| PR 본문·커밋의 AI 첨부 문구 | `Co-Authored-By: Claude …` |

- 봇(dependabot 등)이 연 PR 은 제목·커밋 검사를 건너뜁니다
- 커밋 메시지를 고치려면 `git commit --amend` 또는 `git rebase -i` 후 `git push --force-with-lease` (작업 브랜치에서만)
- 상세 규칙: [joojae-conventions 커밋 규칙](https://github.com/JooJae-Lab/claude-plugins/blob/main/plugins/joojae-conventions/skills/conventions/references/commit.md)

## 10. CI

CI 는 프로젝트마다 다르므로 **레포에서 직접** 만듭니다. 대신 이름 규칙 하나만 지킵니다.

- **최종 판정 잡 이름은 `verify`** — 다른 검사 잡들을 `needs` 로 모아서 하나라도 실패하면 실패
- 템플릿: [`templates/ci/ci.yml`](../templates/ci/ci.yml) (Node/pnpm 예시, 스택에 맞게 수정)
- CI 를 추가한 뒤 `./scripts/apply-rules.ps1 -Repo <레포>` 를 다시 실행하면 `verify` 가 필수 체크가 되어 **CI 실패 시 머지가 막힙니다**
- CI 를 `main` 에 추가하면 진행 중인 `feature/*`·`release/*` 에도 반영(백머지)해야 그 브랜치 PR 에서 CI 가 돕니다. 반영 전에는 `verify` 가 오지 않아 머지가 막힙니다
- 액션 버전은 정확한 버전으로 고정합니다 (`actions/checkout@v7.0.1`)

## 11. Claude Code

[JooJae-Lab/claude-plugins](https://github.com/JooJae-Lab/claude-plugins) 에 팀 공용 플러그인이 있습니다.

| 플러그인 | 내용 |
|---|---|
| `joojae-conventions` | 코드·주석·커밋·브랜치 규칙 상시 적용, AI 첨부 문구 차단, `/joojae-conventions:commit` · `:pr` · `:setup` |
| `joojae-team` | PDCA(Plan→Design→Do→Check→Act) 작업 흐름 `/joojae-team:pdca`, 에이전트 팀, PROMPT.md |

**새 레포에 자동으로 들어가지 않습니다.** 레포 안에 `.claude/settings.json` 파일이 있어야 그 레포에서 플러그인이 켜집니다.
이 파일은 아래 체크리스트 2번의 스크립트가 넣어줍니다. 그 뒤 레포를 Claude Code 로 열면 플러그인 설치 안내가 뜨고, 수락하면 끝입니다.

- PC 전체에 설치(`/plugin install`)하지 않습니다. 개인 레포(예: field-note)에는 org 규칙이 들어가면 안 되기 때문입니다
- 혹시 켜져도 레포 주소가 `github.com/JooJae-Lab/...` 가 아니면 플러그인은 아무 동작도 하지 않습니다
- 플러그인이 바뀌면 `/plugin marketplace update joojae-plugins` 로 갱신

### 새 레포 체크리스트

1. GitHub 에서 org 레포 생성 (public 권장, README 포함, 기본 브랜치 `main`)
2. `./scripts/apply-rules.ps1 -Repo <레포> -FilesOnly` → PR 검사·백머지 워크플로와 `.claude/settings.json` 추가 (룰은 아직 안 걸림)
3. clone 후 Claude Code 실행 → 플러그인 설치 안내 수락 → `/joojae-conventions:setup` (CLAUDE.md, .editorconfig 등) → 필요하면 CI(`verify` 잡) 작성 → `main` 에 커밋·push
4. `./scripts/apply-rules.ps1 -Repo <레포>` → 브랜치 룰 + CI 필수 체크 적용 (이후 `main` 직접 push 불가)
5. `feature/v0.1.0` 만들고 작업 시작
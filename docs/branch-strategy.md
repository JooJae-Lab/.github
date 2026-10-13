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
```

스크립트가 하는 일:
1. 머지 설정: Merge commit · Squash 허용, Rebase 비활성, 머지 후 브랜치 자동 삭제, (public) 비밀값 유출 차단
2. `.github/workflows/branch-policy.yml`, `auto-back-merge.yml` 추가
3. 선택한 룰셋 생성/업데이트

| 룰 이름 | 대상 | 내용 |
|---|---|---|
| `main` | 기본 브랜치 | PR 필수, 승인 1명, Merge commit 만, 검사 통과 필수, force push·삭제 금지, Owner 우회 허용 |
| `release` | `release/v*` | PR 필수, Merge commit 만, 검사 통과 필수, force push·삭제 금지 |
| `feature` | `feature/v*` | PR 필수, Squash·Merge 허용, 검사 통과 필수, force push·삭제 금지 |
| `hotfix` | `hotfix/v*` | force push 금지 (직접 push 는 허용) |

레포별로 다르게 하고 싶으면 스크립트로 일부만 적용하거나, 레포 **Settings → Rules → Rulesets** 에서 직접 수정하세요.
룰 원본은 [`rulesets/`](../rulesets), 공용 워크플로는 [`.github/workflows/`](../.github/workflows) 에 있습니다.

## 8. 비밀값 주의 (public 레포)

- `.env`, API 키, 토큰은 절대 커밋하지 않습니다. `.gitignore` 에 추가하세요.
- CI 용 비밀값은 레포 **Settings → Secrets and variables → Actions** 에 저장합니다.
- 실수로 올렸다면 커밋을 지워도 이미 노출된 것이므로 **즉시 키를 폐기하고 재발급**하세요.

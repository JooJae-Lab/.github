# JooJae-Lab/.github

org 공용 설정 레포입니다.

| 경로 | 내용 |
|---|---|
| `profile/README.md` | org 첫 화면(Overview) 소개 |
| `docs/branch-strategy.md` | **브랜치 전략 & 협업 가이드** |
| `pull_request_template.md` | 모든 레포의 기본 PR 템플릿 |
| `.github/workflows/` | 공용 재사용 워크플로 (브랜치 검사, 자동 백머지) |
| `templates/workflows/` | 각 레포에 들어가는 호출용 워크플로 |
| `rulesets/` | 룰셋 정의 (main / release / feature / hotfix) |
| `scripts/apply-rules.ps1` | 레포에 룰 적용 스크립트 |

새 레포를 만들면: `./scripts/apply-rules.ps1 -Repo <레포이름>`

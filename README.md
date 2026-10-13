# JooJae-Lab/.github

org 공용 설정 레포입니다.

| 경로 | 내용 |
|---|---|
| `profile/README.md` | org 첫 화면(Overview) 소개 |
| `docs/branch-strategy.md` | **브랜치 전략 & 협업 가이드** (커밋 컨벤션, CI, Claude Code 포함) |
| `pull_request_template.md` | 모든 레포의 기본 PR 템플릿 |
| `.github/workflows/` | 공용 재사용 워크플로 (PR 규칙 검사, 자동 백머지) |
| `templates/workflows/` | 각 레포에 들어가는 호출용 워크플로 (스크립트가 자동 추가) |
| `templates/ci/ci.yml` | CI 템플릿 (최종 잡 이름 `verify`) |
| `rulesets/` | 룰셋 정의 (main / release / feature / hotfix) |
| `scripts/apply-rules.ps1` | 레포에 룰 적용 스크립트 |

Claude Code 플러그인(컨벤션·PDCA 에이전트 팀)은 [JooJae-Lab/claude-plugins](https://github.com/JooJae-Lab/claude-plugins) 에 있습니다.

새 레포를 만들면: [새 레포 체크리스트](docs/branch-strategy.md#새-레포-체크리스트)

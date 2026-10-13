# JooJae-Lab 👋

## 📌 협업 규칙

- **[브랜치 전략 & 협업 가이드](https://github.com/JooJae-Lab/.github/blob/main/docs/branch-strategy.md)** ← 작업 전에 꼭 읽어주세요
- **[Claude Code 플러그인](https://github.com/JooJae-Lab/claude-plugins)** — 컨벤션 상시 적용, PDCA 에이전트 팀

```
main ◀── release/vX.Y.Z ◀── feature/vX.Y.Z ◀── feat/*, fix/* ...
main ◀── hotfix/vX.Y.Z
```

| PR | 리뷰 | 머지 방식 |
|---|---|---|
| 작업 브랜치 → `feature/vX.Y.Z` | - | Squash |
| `feature/vX.Y.Z` → `release/vX.Y.Z` | - | Merge commit |
| `release/vX.Y.Z`, `hotfix/vX.Y.Z` → `main` | 1명 이상 | Merge commit |

커밋·PR 제목: `타입: 한국어 설명` (예: `feat: 로그인 화면 추가`) · AI 첨부 문구 금지 · CI(`verify`) 통과 필수

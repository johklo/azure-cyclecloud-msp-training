# Azure CycleCloud MSP 교육 환경

Cloud MSP 운영 담당자에게 **Azure CycleCloud** 운영법을 가르치기 위한
**실습 환경(IaC) + 한국어 교육 가이드** 모음입니다.

## 구성
```
cyclecloud/
├─ infra/            # Bicep IaC (서버 환경 배포)
│  ├─ main.bicep
│  └─ README.md      # 배포/삭제 방법
├─ docs/             # 한국어 교육 가이드 (아래 목차)
│  ├─ README.md
│  ├─ 01-환경-개요.md
│  ├─ 02-포털-사용법.md
│  ├─ 03-신규-클러스터-생성.md
│  ├─ 04-노드-증감설-사이즈변경.md
│  ├─ 05-스토리지-디스크-마운트.md
│  ├─ 06-트러블슈팅-로그.md
│  └─ 07-데모-런북.md
└─ keys/             # SSH 키 (커밋 금지)
```

## 교육 범위 (요청 사항 매핑)
| 요청 사항 | 문서 |
|-----------|------|
| CycleCloud 신규 생성 | `docs/03-신규-클러스터-생성.md` |
| 노드 증/감설, 노드 사이즈 변경 | `docs/04-노드-증감설-사이즈변경.md` |
| Storage account, Disk 마운트 | `docs/05-스토리지-디스크-마운트.md` |
| CycleCloud 포털 사용 방법 | `docs/02-포털-사용법.md` |
| 기본 트러블슈팅 (로그 확인) | `docs/06-트러블슈팅-로그.md` |

## 배포된 실습 환경
| 항목 | 값 |
|------|-----|
| 포털 | https://cc-cyclecloud-ekwphu.koreacentral.cloudapp.azure.com |
| 리소스 그룹 | `rg-cyclecloud-training` (Korea Central) |
| 서버 VM | `cc-server` (20.196.213.145) |

## 시작하기
1. 가이드 목차부터 읽기 → [docs/README.md](docs/README.md)
2. 환경을 새로 만들거나 삭제하려면 → [infra/README.md](infra/README.md)

## 지원 (Azure SRE 팀)
이동훈 · 김태진 · 지민근

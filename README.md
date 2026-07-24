# Azure CycleCloud MSP 교육 환경 & KT 현황 가이드

Cloud MSP 운영 담당자 및 KT CycleCloud 엔지니어를 위한 **Azure CycleCloud** 최초 구축 및 운영법, **KT 구축 현황 브리핑 PPTX**, **Bicep IaC 배포 스크립트**, 그리고 **12개 모듈 한국어 실습 가이드 + 69개 스크린샷** 모음입니다.

---

## 📂 디렉터리 구조
```
cyclecloud/
├─ infra/                      # Bicep IaC & 원클릭 배포/삭제 스크립트
│  ├─ main.bicep               # Azure 인프라 템플릿
│  ├─ deploy-lab.ps1 / .sh     # 원클릭 환경 구축 스크립트
│  ├─ destroy-lab.ps1 / .sh    # 서버 일시 중지 / 리소스 그룹 삭제 스크립트
│  └─ README.md                # 인프라 설명서
├─ docs/                       # 강의 PPTX & 12개 실습 가이드 (마크다운)
│  ├─ Cyclecloud_MSP_Training.pptx # 11슬라이드 발표용 PowerPoint 파일
│  ├─ README.md                # 교육 마스터 목차
│  ├─ 01-환경-개요.md
│  ├─ 03-신규-클러스터-생성.md     # 최초 클러스터 구축 및 초기 설정 가이드
│  ├─ 04-노드-증감설-사이즈변경.md
│  ├─ 05-스토리지-디스크-마운트.md
│  ├─ 06-cluster-init-및-커스텀-스크립트.md
│  ├─ 07-Job-Accounting-설정.md
│  ├─ 08-사용자-관리.md
│  ├─ 09-파티션-관리-및-추가.md
│  ├─ 10-GPU-모니터링-구축.md
│  ├─ 11-트러블슈팅-로그.md
│  ├─ 12-데모-런북.md
│  ├─ 13-버전-확인.md
│  ├─ 14-Slurm-사용-가이드.md
│  └─ images/                  # 69개 실습 스크린샷 (10개 주제별 분류)
└─ keys/                       # SSH 키 보관 폴더
```

---

## 📋 교육 범위 및 요청 사항 매핑

| 요청 사항 및 KT 현황 | 담당 문서 / 발표 자료 |
|---------------------|----------------------|
| **1. 강의용 PPTX 및 KT 현황 공유** | [`docs/Cyclecloud_MSP_Training.pptx`](docs/Cyclecloud_MSP_Training.pptx) |
| **2. 최초 클러스터 구축 및 초기 설정** | [`docs/03-신규-클러스터-생성.md`](docs/03-신규-클러스터-생성.md) |
| **3. 노드 증/감설, 사이즈 변경** | [`docs/04-노드-증감설-사이즈변경.md`](docs/04-노드-증감설-사이즈변경.md) |
| **4. Storage Account, Disk 마운트** | [`docs/05-스토리지-디스크-마운트.md`](docs/05-스토리지-디스크-마운트.md) |
| **5. CycleCloud 포털 사용 방법** | [`docs/03-신규-클러스터-생성.md`](docs/03-신규-클러스터-생성.md) |
| **6. cluster-init & cloud-init 규칙** | [`docs/06-cluster-init-및-커스텀-스크립트.md`](docs/06-cluster-init-및-커스텀-스크립트.md) |
| **7. Slurm Job Accounting (MySQL)** | [`docs/07-Job-Accounting-설정.md`](docs/07-Job-Accounting-설정.md) |
| **8. Built-in 사용자 및 키페어 관리** | [`docs/08-사용자-관리.md`](docs/08-사용자-관리.md) |
| **9. GPU 모니터링 (Prometheus/Grafana)**| [`docs/10-GPU-모니터링-구축.md`](docs/10-GPU-모니터링-구축.md) |
| **10. 기본 트러블슈팅 및 로그 확인** | [`docs/11-트러블슈팅-로그.md`](docs/11-트러블슈팅-로그.md) |

---

## ⚡ 시작하기

1. **강의자료/실습 가이드 마스터 목차**: [docs/README.md](docs/README.md)
2. **원클릭 인프라 자동 배포**: `cd infra; .\deploy-lab.ps1`

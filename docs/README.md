# Azure CycleCloud 운영 교육 가이드 (MSP & KT 현황)

Azure CycleCloud 실습 환경과 KT 운영 지침을 정리한 MSP 운영 담당자용 교육 가이드입니다.

---

## 🎯 대상 독자
- Azure CycleCloud를 처음 접하는 MSP / 운영 담당자
- HPC(고성능 컴퓨팅) 클러스터를 Azure 상에서 구축, 운영, 엔지니어링하는 담당자
- KT CycleCloud 운영 및 기술 지원 담당자

---

## 👥 기술 지원 담당 (Azure SRE 팀)
- **이동훈** (Azure SRE팀)
- **김태진** (Azure SRE팀)
- **지민근** (Azure SRE팀)

---

## 💻 실습 및 강의 교육 자료 (PPTX & IaC)

| 구분 | 파일 / 경로 | 설명 |
|------|-------------|------|
| **강의 발표자료 (PPTX)** | [`docs/Cyclecloud_MSP_Training.pptx`](Cyclecloud_MSP_Training.pptx) | 최초 클러스터 구축, 아키텍처, KT 현황 브리핑 발표용 11슬라이드 PPT |
| **Bicep 자동 배포** | [`infra/deploy-lab.ps1`](../infra/deploy-lab.ps1) / [`deploy-lab.sh`](../infra/deploy-lab.sh) | 실습 리소스 전체 자동 구성 스크립트 |
| **자동 정리 스크립트** | [`infra/destroy-lab.ps1`](../infra/destroy-lab.ps1) | 실습 완료 후 서버 일시 중지(Deallocate) 및 삭제 스크립트 |
| **실습 캡처 이미지** | [`docs/images/`](images/) | 69개 웹 포털 GUI 및 터미널 실습 스크린샷 모음 |

---

## 📍 실습 환경 접속 정보

| 항목 | 값 |
|------|-----|
| **CycleCloud 포털 URL** | `https://cc-cyclecloud-ekwphu.koreacentral.cloudapp.azure.com` |
| **서버 공인 IP** | `20.196.213.145` |
| **Azure 리전** | `Korea Central` (한국 중부) |
| **리소스 그룹** | `rg-cyclecloud-training` |
| **서버 VM 사양** | `cc-server` (Standard_D4s_v5) |
| **SSH 관리자 계정** | `azureadmin` |
| **SSH 키 경로** | `keys/cyclecloud_rsa` |
| **스토리지 계정 (Locker)** | `cclkekwphusd3i` (컨테이너 `cyclecloud`) |

---

## 📚 교육 커리큘럼 및 실습 목차 (13개 모듈)

### Part 1 & 2. 개요, 최초 구축 및 포털 관리
1. [01. 환경 개요 및 아키텍처 (KT 현황 포함)](01-환경-개요.md)
2. [02. Cluster-Init 및 커스텀 스크립트 (cloud-init vs cluster-init)](02-cluster-init-및-커스텀-스크립트.md)
3. [13. 버전 확인 (CycleCloud / Slurm)](13-버전-확인.md)
4. **[03. CycleCloud 신규 생성 및 최초 클러스터 구축 (First-Time Setup)](03-신규-클러스터-생성.md)**
5. [04. 노드 증/감설, 사이즈 변경 & Scale-in 방지](04-노드-증감설-사이즈변경.md)
6. [05. Storage Account / Disk 마운트 (OS Disk, Blob, Lustre)](05-스토리지-디스크-마운트.md)
7. [15. 디스크 사이즈 변경 (OS/부팅 디스크)](15-디스크-사이즈-변경.md)
8. [14. Slurm 사용 가이드 (노드 유형 · 명령어 · 작업 제출)](14-Slurm-사용-가이드.md)

### Part 3. 심화 구성 & 엔지니어링
9. [07. Slurm Job Accounting 구축 (MySQL Flexible Server)](07-Job-Accounting-설정.md)
10. [08. 사용자 관리 (Built-in Users & Keypair)](08-사용자-관리.md)
11. [09. 파티션 관리 및 추가 (azure.conf)](09-파티션-관리-및-추가.md)
12. [10. 모니터링 (Prometheus + Grafana)](10-모니터링.md)

### Part 4. 운영 & 트러블슈팅
11. [11. 기본 트러블슈팅 및 로그 확인 (Triage Matrix)](11-트러블슈팅-로그.md)
12. [12. 데모 런북 (진행자 체크리스트)](12-데모-런북.md)

### 부록 (심화)
- [부록. CycleCloud Prometheus 모니터링 구축 (전반)](부록-Prometheus-모니터링.md) — 내장 Monitoring 탭 + Azure Monitor Workspace(Managed Prometheus) + Managed Grafana + Exporter(9100/9101/9400) + Self-hosted 대안

---

## 🛠️ 인프라 재배포 (IaC)
실습 환경을 새로 만들거나 정리하려면 [`infra/README.md`](../infra/README.md) 를 참조하십시오.

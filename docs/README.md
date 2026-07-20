# Azure CycleCloud 운영 교육 가이드 (MSP용)

이 문서는 **Azure CycleCloud** 를 처음 다루는 Cloud MSP 운영 담당자가
실습 환경에서 직접 따라 하며 익힐 수 있도록 작성된 교육 가이드입니다.

## 대상 독자
- CycleCloud 를 처음 접하는 MSP / 운영 담당자
- HPC(고성능 컴퓨팅) 클러스터를 Azure 위에서 운영해야 하는 담당자

## 지원 담당 (Azure SRE 팀)
- 이동훈 (Azure SRE팀)
- 김태진 (Azure SRE팀)
- 지민근 (Azure SRE팀)

## 실습 환경 접속 정보
| 항목 | 값 |
|------|-----|
| CycleCloud 포털 | https://cc-cyclecloud-ekwphu.koreacentral.cloudapp.azure.com |
| 서버 공인 IP | 20.196.213.145 |
| 리전 | Korea Central (한국 중부) |
| 리소스 그룹 | `rg-cyclecloud-training` |
| 서버 VM | `cc-server` (Standard_D4s_v5) |
| SSH 관리자 계정 | `azureadmin` |
| SSH 키 | `keys/cyclecloud_rsa` (리포지토리 내 보관) |
| 스토리지 계정(Locker) | `cclkekwphusd3i` |

> ⚠️ 포털은 배포 직후 자체 서명(self-signed) 인증서를 사용하므로 브라우저 경고가
> 표시됩니다. "고급 → 계속 진행"으로 접속하면 됩니다. (운영 환경에서는 정식 인증서를 권장)

## 목차 (실습 순서)
1. [환경 개요 및 아키텍처](01-환경-개요.md)
2. [CycleCloud 포털 사용 방법](02-포털-사용법.md)
3. [CycleCloud 신규 클러스터 생성](03-신규-클러스터-생성.md)
4. [노드 증설/감설 및 노드 사이즈 변경](04-노드-증감설-사이즈변경.md)
5. [Storage Account / Disk 마운트](05-스토리지-디스크-마운트.md)
6. [기본 트러블슈팅 및 로그 확인](06-트러블슈팅-로그.md)
7. [데모 런북 (진행자용 체크리스트)](07-데모-런북.md)

## 인프라 재배포 (IaC)
이 실습 환경은 Bicep 으로 코드화되어 있어 언제든지 재생성/삭제할 수 있습니다.
자세한 내용은 [../infra/README.md](../infra/README.md) 를 참고하세요.

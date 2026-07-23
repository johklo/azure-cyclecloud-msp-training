# CycleCloud 슬라이드 생성용 LLM 프롬프트 (복사·붙여넣기 템플릿)

> 사용법: 아래 `=== PROMPT START ===` 부터 `=== PROMPT END ===` 사이 전체를 복사하여 LLM에 붙여넣으세요.
> `【편집】` 로 표시된 부분만 원하는 값으로 바꾸면 됩니다. 나머지는 그대로 둬도 동작합니다.

---

=== PROMPT START ===

# 역할
너는 Azure HPC/CycleCloud 전문 프레젠테이션 작성가이자 python-pptx 코드 생성기다.
아래 요구사항과 근거 사실만을 바탕으로, **바로 실행 가능한 python-pptx 스크립트 하나**를 출력한다.

# 목표
Azure CycleCloud를 소개·설명하는 PowerPoint 덱을 만든다.
- 대상 청중: 【편집: 예) 고객사(KT)의 CycleCloud를 대신 운영·지원하는 Cloud MSP 운영/SRE 담당자】
- 덱의 목적: 【편집: 예) MSP가 CycleCloud를 운영·지원하기 위해 알아야 할 핵심 온보딩】
- 강조점: 【편집: 예) 운영 작업 절차, 주의사항(노드 재시작/RI), 트러블슈팅】
- 슬라이드 수: 【편집: 예) 11장 내외】
- 언어/어투: 한국어, 명료하고 간결하게 (불필요한 수식어 배제, 실무 중심).

# 청중 관점 규칙 (중요)
- 이 덱은 "제품 판매용 가치제안"이 아니라 **"운영·지원 주체가 무엇을 어떻게 해야 하는가"** 관점이다.
  (청중이 최종 고객이면 가치제안 관점으로, MSP/운영자면 운영 관점으로 톤을 맞춘다 — 위 '대상 청중'에 따름)
- 추측하지 말고 아래 '근거 사실'에 있는 내용만 사용한다. 모르는 수치·버전은 지어내지 않는다.

# 근거 사실 (이 내용만 사용)

## A. CycleCloud 개요
- Azure에서 HPC(고성능 컴퓨팅) 클러스터를 생성·관리하고 수요에 따라 자동 증설/감설(오토스케일)하는 관리 서비스.
- 지원 스케줄러: Slurm, OpenPBS, LSF, HTCondor, Grid Engine 등. 통합 제어: 웹 포털 GUI / CLI(cyclecloud, azslurm) / REST API.

## B. 아키텍처 3계층
1) 컨트롤 플레인: CycleCloud Server VM(cc-server), 웹 포털(HTTPS 443), cycle_server 서비스, cyclecloud CLI,
   System-assigned Managed Identity(구독 범위 노드 프로비저닝, 시크릿 없이).
2) 스케줄러 & 계산 노드: 스케줄러 노드(Slurm Master, slurmctld, azslurm), 실행 노드=VMSS(수요 시 자동 생성, 유휴 시 자동 감설),
   공유 저장소 /shared·/sched(NFS).
3) 스토리지 & Locker: Blob Storage(Locker)에 템플릿·cluster-init 스크립트 보관, 데이터용 Blob NFS/Azure Files,
   Azure Managed Lustre(고성능 병렬), 노드 OS Disk.

## C. 오토스케일 라이프사이클
Job 제출(sbatch/srun) → CycleCloud가 큐 감지 → 노드 자동 증설(Off→Acquiring→Preparing→Ready, cluster-init 적용) →
Job 실행 → 완료·유휴 시 노드 자동 감설(비용 절감).

## D. MSP 지원 범위(요청 항목) ↔ 실습 모듈 매핑
- ① 신규 생성(서버·클러스터 구축) → Module 03
- ② 노드 증/감설·사이즈(VM SKU) 변경 → Module 04
- ③ Storage Account·Disk 마운트 → Module 05
- ④ 포털 사용 방법 → Module 02
- ⑤ 기본 트러블슈팅(로그 확인) → Module 11
- 심화: 06 cluster-init, 07 Job Accounting, 08 사용자 관리, 09 파티션, 10 GPU 모니터링, 12 데모 런북

## E. 운영 인터페이스 & 접근
- 웹 포털(GUI): 클러스터 생성/Edit/Start/Terminate, 노드 상태, Autoscale, Users/Accounting/Monitoring 탭.
- CLI: cyclecloud show_cluster/show_nodes/start_cluster/terminate_cluster/project upload; azslurm resume/suspend/scale.
- SSH 키 없는 접근: Azure Portal의 '명령 실행(Run Command)' 또는 `az vm run-command invoke` — RBAC 권한만으로 로그 확인.

## F. 핵심 운영 작업 요약
- 신규 생성: Locker용 Managed Identity·Storage 준비 → Marketplace 이미지로 CycleCloud VM 배포 →
  설정 마법사(Site·License·관리자·구독 등록; VM 시스템 ID에 Contributor + Storage Blob Data Contributor 부여) →
  Slurm 템플릿으로 클러스터 생성 & Start.
- 노드 증/감설: Autoscale Max Cores 조정 또는 azslurm resume/suspend.
- 사이즈 변경: 템플릿 VM SKU 변경 → import_cluster --force → azslurm scale(재시작 없이 반영).
  (수동 azure.conf 편집은 scale 시 되돌아감)
- 스토리지 마운트: Blob NFS/Azure Files/Managed Lustre; OS Disk(BootDiskSize) 변경 시 노드 Terminate/Start 필요; cluster-init로 표준화.
- 사용자 관리: Built-in/AD/LDAP/Entra ID 지원(KT는 Built-in), 포털 Users 탭, Keypair(pem) 등록, jetpack이 노드 OS 계정 생성.

## G. 반드시 알아야 할 주의사항 (KT 환경)
- [최우선] 노드 재시작 최소화: GPU VM 용량(capa) 부족으로 재시작/재생성 시 재할당(Acquiring) 실패 가능. KT GPU VM은 RI 적용.
- 올바른 재부팅: **할당을 유지한 채 OS만 재부팅**(`az vm restart` / 포털 Restart / 노드 `sudo reboot`).
  절대 피할 것: Stop(Deallocate)→Start, CycleCloud Terminate, `azslurm suspend`(=노드 삭제) — 용량 재획득 실패 위험.
  Slurm 노드는 drain → in-place 재부팅 → resume 순서. deallocate 불가피 시 사전 quota 확인 +
  On-demand Capacity Reservation 또는 Azure Capa 팀 일정 조율. (RI는 요금 할인일 뿐 물리 용량 보장 아님)
- Scale-in 방지: Slurm 기본 Suspend time 300초, UI 'keep_alive' 오작동 사례 → slurm.conf에 `SuspendExcParts=hpc`.
- cloud-init 금지·cluster-init 사용: cloud-init 수정 시 'does not match ... attribute: CloudInit' 오류로 노드 할당 실패,
  전체 클러스터 재기동 필요. cluster-init(converge)는 재부팅 없이 반영. Locker에 4~5개 스크립트(scale-in·NVIDIA 드라이버·마운트).

## H. 트러블슈팅
- 3단계 Triage: ① 포털 노드 Status 메시지 → ② 서버 `/opt/cycle_server/logs/cycle_server.log` → ③ 노드 `jetpack.log`/`cloud-init-output.log`.
- 도구: `sinfo -R`, `azslurm retry_failed_nodes`, `systemctl restart slurmd`, `/opt/cycle/capture_logs.sh`(지원 번들), healthagent 자동 DRAIN(60s).

## I. 지원 에스컬레이션 & 필수 버전 3종
- 지원 요청 시 ① CycleCloud 버전(UI 우측 상단 '?') ② Slurm 버전(Cluster Edit>Advanced) ③ jetpack(slurm) 프로젝트 버전(노드 CLI) 모두 필요.
- 이유: 버그/호환성/미지원 판별, 재현 환경 구성, 업그레이드 경로 산정의 기준.
- KT 버전 현황(참고, 변동 가능):
  - Mexico Central: CycleCloud 8.9.0-3754 / Slurm 25.11.4 / jetpack slurm 4.0.8 · 학습노드 128 + GPU 4
  - Korea Central: CycleCloud 8.7.3-3438 / Slurm 23.11.19-1 / jetpack slurm 3.0.12 · 학습노드 6 + GPU 1

# 슬라이드 구성 (기본안 — 필요 시 청중/목적에 맞게 조정)
1. 타이틀(제목·부제·발표주체)
2. 대상 청중에 맞는 도입(청중이 MSP면 '지원 범위 D', 최종고객이면 '온프레미스 한계 vs 클라우드 HPC')
3. CycleCloud란(A) / 아키텍처(B)
4. 오토스케일 동작 방식(C) — 단계 카드 + 화살표
5. 운영 인터페이스 & 접근(E)
6. 핵심 운영 작업 ①: 신규 생성 · 노드 증감설/사이즈(F)
7. 핵심 운영 작업 ②: 스토리지 마운트 · 사용자 관리(F)
8. 주의사항(G) — 경고 색상 카드로 강조(노드 재시작/재부팅·RI·cloud-init)
9. 트러블슈팅 & 로그(H)
10. 에스컬레이션 & 버전(I)
11. 실습 매뉴얼 12모듈 & 온보딩 로드맵(D)
【편집: 슬라이드 추가/삭제/순서 변경 자유】

# 비주얼·레이아웃 규격 (python-pptx)
- 16:9, `prs.slide_width=Inches(13.333)`, `prs.slide_height=Inches(7.5)`, 빈 레이아웃 `prs.slide_layouts[6]` 사용.
- 색상(RGBColor): NAVY(15,34,64), BLUE(0,114,206), LIGHT_BG(245,247,250), DARK_TEXT(30,30,30), WHITE(255,255,255),
  GRAY(100,100,100), ACCENT_ORANGE(227,85,33), CARD_BG(235,240,248), CARD_BORDER(200,215,235),
  WARN_BG(254,243,235), WARN_BORDER(240,150,100), GREEN_BG(233,245,236), GREEN_BORDER(150,200,160), GREEN_TITLE(30,120,60).
- 공통 요소(헬퍼 함수로 구현):
  - 배경: 슬라이드 전체 사각형을 LIGHT_BG로(타이틀은 NAVY).
  - 헤더 바: 상단 높이 1.1인치 NAVY 사각형, 위에 작은 BLUE 카테고리 텍스트("AZURE CYCLECLOUD | ..."), 아래 흰색 22pt 제목.
  - 카드: ROUNDED_RECTANGLE, 제목 16pt bold + 불릿 항목 12pt. "  "(공백 2칸)로 시작하는 항목은 들여쓴 하위항목으로 처리.
  - 강조 카드는 WARN_BG/WARN_BORDER/ACCENT_ORANGE, 긍정/요약 카드는 GREEN_BG/GREEN_BORDER/GREEN_TITLE.
- 3열 카드 배치 예: left=0.6/4.7/8.8, width≈3.8~3.9; 2열은 0.6/6.8, width≈5.8/5.9; top=1.4, height≈5.5.

# 출력 형식 (엄수)
- **오직 하나의 완결된 python 코드 블록**만 출력한다(설명 문장 없이).
- 표준 라이브러리 + `python-pptx`만 사용. 외부 이미지·폰트 의존 금지.
- `build(output_path)` 함수 + `if __name__ == "__main__":` 에서 `build("CycleCloud_소개.pptx")` 호출.
- 콘솔 print는 ASCII만(Windows cp1252 인코딩 오류 방지). 파일명 변수만 한글 허용.
- 코드는 수정 없이 `python 파일명.py` 로 실행되어 .pptx가 생성되어야 한다.

# 제약
- 근거 사실에 없는 수치/제품명/버전은 만들지 않는다. 불확실하면 일반적 표현으로 대체.
- 슬라이드당 텍스트는 카드가 넘치지 않도록 간결하게(불릿 6~7개 이내).

이제 위 규격에 맞는 python-pptx 스크립트를 출력하라.

# 참조 파일 (저장소 접근이 가능한 경우 우선 활용)
> LLM/세션이 이 저장소(`johklo/azure-cyclecloud-msp-training`)에 접근 가능하면, 아래 파일을 직접 열어
> 최신 내용을 반영하라. 접근 불가하면 위 '근거 사실' 블록만으로 작성한다.
> 파일 내용과 위 근거 사실이 다르면 **저장소 파일을 우선**한다(문서가 최신).

## 실습 매뉴얼 (docs/, 슬라이드 내용의 1차 출처)
- `docs/README.md` — 12개 모듈 목차·구성(네비게이션 기준)
- `docs/01-환경-개요.md` — 아키텍처, KT 환경 현황, 버전 매트릭스
- `docs/02-포털-사용법.md` — 포털 사용 방법
- `docs/03-신규-클러스터-생성.md` — 서버·클러스터 신규 생성(설치 마법사)
- `docs/04-노드-증감설-사이즈변경.md` — 노드 증/감설·SKU 변경·azslurm scale·재부팅
- `docs/05-스토리지-디스크-마운트.md` — Blob NFS/Files/Lustre·OS Disk
- `docs/06-cluster-init-및-커스텀-스크립트.md` — cluster-init/커스텀 스크립트
- `docs/07-Job-Accounting-설정.md` — Slurm Job Accounting(MySQL)
- `docs/08-사용자-관리.md` — Built-in/AD/LDAP/Entra ID 사용자 관리
- `docs/09-파티션-관리-및-추가.md` — 파티션 관리·추가
- `docs/10-GPU-모니터링-구축.md` — Prometheus/Grafana GPU 모니터링
- `docs/11-트러블슈팅-로그.md` — 로그 진단·Triage·capture_logs
- `docs/12-데모-런북.md` — 진행자 데모 체크리스트

## 원본 브리핑/참고 자료 (KT 현황·시각 자료)
- `docs/Cyclecloud_260722.pptx` — KT 엔지니어 원본 브리핑(버전 현황·운영 특이사항 1차 출처)
- `docs/Cyclecloud_MSP_Training.pptx`, `docs/Cyclecloud_260722_Updated.pptx` — 교육/KT 현황 정리 덱
- `docs/CycleCloud_MSP_소개.pptx` — MSP 운영 온보딩 소개 덱(본 프롬프트 결과물의 참고 예시)
- `docs/Nvidia GPU and Infiniband Monitoring 1.pptx`, `docs/Fun CycleCloud for NGC_0528.pdf`,
  `docs/Using Slurm with Azure CycleCloud - October 2020 Fun Friday.pptx` — 보조 참고
- `docs/images/` 하위 폴더(스크린샷): `check-version`, `add-node`, `node_scaling`, `disk-resize`,
  `cluster-init`, `slurm_job_accounting`, `user-management`, `add-new-partition`,
  `gpu-monitoring`, `gpu-monitoring-v2` — 단계별 실제 포털 스크린샷(필요 시 슬라이드에 인용 가능)

## 비주얼 규격 참고 스크립트 (동일 톤 재현)
- `create_pptx.py` — 교육+KT 현황 덱 생성 스크립트(헬퍼 함수·색상 규격의 원본)
- `create_intro_pptx.py` — MSP 운영 온보딩 덱 생성 스크립트(본 규격의 직접 예시)

=== PROMPT END ===

---

## 참고: 이 저장소의 기존 산출물
- 실제 생성 스크립트 예시: `create_pptx.py`(교육+KT 현황 덱), `create_intro_pptx.py`(MSP 운영 온보딩 덱).
- 위 프롬프트는 이 두 스크립트와 동일한 비주얼 규격을 따르므로, 결과물이 기존 덱과 톤이 일치합니다.

# 14. Slurm 사용 가이드 (노드 유형 · 명령어 · 작업 제출)

CycleCloud로 배포한 Slurm 클러스터의 구성 요소와 일상 운영 명령어를 정리합니다. 대상은 Slurm을 처음 다루는 운영 담당자입니다.

---

## 14.1 Slurm 데몬과 노드 구성

Slurm은 SchedMD가 개발한 오픈소스 HPC 작업 스케줄러입니다. 클러스터는 다음 데몬으로 동작합니다.

| 데몬 | 실행 위치 | 역할 |
|------|-----------|------|
| **slurmctld** | 스케줄러 노드 | 중앙 컨트롤러. 자원 상태 감시, 작업 큐 관리, 자원 할당, 정책 적용 |
| **slurmd** | 계산 노드 | 노드별 1개. `slurmstepd`를 기동하고 로컬 자원을 `slurmctld`에 보고 |
| **slurmstepd** | 계산 노드 | 작업 단계(job step)별로 기동. 사용자 태스크 실행, I/O·시그널·계정 처리 |
| **slurmdbd** | 스케줄러 노드(옵션) | Job Accounting DB 데몬. 계정 정보 수집, 사용자/그룹 한도·fairshare 관리 (→ [07장](07-Job-Accounting-설정.md)) |

`slurmctld`가 중단되면 스케줄링 전체가 멈춥니다. 스케줄러 노드는 상시 1대 유지되며 Autoscale 대상이 아닙니다.

---

## 14.2 노드 유형과 파티션

Slurm의 **파티션(Partition)** 은 노드 집합에 대한 작업 큐입니다. CycleCloud에서는 파티션이 **NodeArray** 에 대응하며, 하나 이상의 VM Scale Set으로 배포됩니다.

| 파티션 | 워크로드 | VM 계열 | `slurm.hpc` |
|--------|----------|---------|-------------|
| **hpc** | 긴밀결합(MPI) 다중 노드 작업 | InfiniBand/RDMA(`HB`, `HC`, `ND`) | `true` — 단일 VMSS·근접배치 |
| **htc** | 느슨결합(독립 태스크) 배치 작업 | 범용(`D`, `F`) | `false` |
| **gpu** | GPU 작업 | `NC`, `ND`, `NG` | 용도에 따라 |

- `hpc` 파티션은 단일 VMSS 경계 안에서만 저지연 통신이 보장됩니다. **Max VMs per Scaleset** 값이 단일 MPI 작업의 최대 노드 규모를 제한합니다.
- 신규 파티션 추가는 [09장](09-파티션-관리-및-추가.md)을 참고하세요.

---

## 14.3 기본 명령어

명령은 클러스터의 어느 노드에서나 실행할 수 있습니다. 대부분 단축 옵션(`-p`)과 전체 옵션(`--partition=`)을 지원하며, `-v`를 반복하면 상세 로그가 출력됩니다(`-vvvv`).

| 명령 | 용도 |
|------|------|
| `sinfo` | 파티션·노드 상태 조회 |
| `squeue` | 작업 큐 조회 |
| `sbatch` | 스크립트를 배치 작업으로 제출 |
| `srun` | 작업 할당 후 job step 실행 (대화형/병렬) |
| `salloc` | 대화형 작업 할당 후 셸 시작 |
| `scancel` | 실행 중/대기 작업 취소 |
| `scontrol` | 스케줄러·노드 상태 조회 및 수정 |
| `sacct` | 완료된 작업의 Accounting 조회 (slurmdbd 필요) |

---

## 14.4 작업 제출

### 배치 작업 (`sbatch`)

작업 스크립트를 작성해 제출합니다. `#SBATCH` 지시문으로 자원을 요청합니다.

```bash
cat << 'EOF' > job.sh
#!/bin/bash
#SBATCH --job-name=test
#SBATCH --partition=htc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=result-%j.log

hostname
sleep 30
EOF

sbatch job.sh
```

명령을 직접 감싸 제출할 수도 있습니다.

```bash
sbatch --wrap="/bin/hostname" --partition=htc
```

### 대화형 작업 (`salloc`)

자원을 할당받아 대화형 셸에서 실행합니다.

```bash
salloc --partition=htc --nodes=1
```

### MPI 작업 (`srun`)

`hpc` 파티션에서 여러 노드에 태스크를 분산합니다.

```bash
sbatch --partition=hpc --nodes=2 --ntasks-per-node=2 --wrap="srun ./mpi_app"
```

Autoscale이 켜져 있으면 작업 제출 시 필요한 계산 노드가 자동으로 기동됩니다. 최초 기동에는 수 분이 걸립니다.

---

## 14.5 노드·큐 상태 확인

```bash
sinfo                 # 파티션별 노드 상태 요약
sinfo -N -l           # 노드별 상세
squeue                # 전체 작업 큐
squeue -u <사용자>    # 특정 사용자 작업
scontrol show node <노드명>
scontrol show job <작업ID>
```

`sinfo`의 노드 상태 접미 기호:

| 기호 | 의미 |
|------|------|
| `*` | 무응답. 지속되면 `DOWN`으로 전환 |
| `~` | 절전(power save) 상태 — 정지된 Autoscale 노드 |
| `#` | 기동/구성 중 |
| `%` | 정지 중 |

`idle~`는 CycleCloud가 회수한 정상 정지 상태이며, 작업 제출 시 자동 기동됩니다.

---

## 14.6 CycleCloud 연동 (Autoscale · 설정 변경)

### Autoscale 동작

CycleCloud Slurm은 Slurm의 **Elastic Computing(power save)** 기능을 사용합니다. Slurm이 필요한 노드를 이름으로 지정해 CycleCloud에 기동/정지를 요청합니다. 수동 제어는 다음 명령을 씁니다.

```bash
azslurm resume --node-list <노드명>
azslurm suspend --node-list <노드명>
```

CycleCloud 포털이나 `shutdown`으로 노드를 직접 정지하면 `DOWN` 상태가 되어 Slurm이 다시 기동하지 않습니다. 이 경우 수동으로 `idle`로 되돌립니다.

```bash
scontrol update nodename=<노드명> state=idle
```

### 설정 변경 반영

클러스터 구성(Autoscale 한도, VM 종류 등)을 바꾸면 스케줄러 노드에서 아래를 실행해 `slurm.conf`를 재생성하고 노드 목록을 갱신해야 합니다.

```bash
sudo -i
/opt/cycle/slurm/cyclecloud_slurm.sh apply_changes
```

> ⚠️ MPI(`hpc`) 파티션의 VM 크기·이미지·cloud-init을 바꾸면 실행 중 노드를 **먼저 종료**해야 합니다. 그렇지 않으면 신규 노드가 `This node doesn't match existing scaleset attribute` 오류로 기동에 실패합니다. `apply_changes`는 노드가 종료됐는지 확인합니다.

### 특정 노드·파티션 Autoscale 제외

CycleCloud "KeepAlive" 버튼은 Slurm 클러스터에 적용되지 않습니다. 대신 `/sched/slurm.conf`에 다음을 추가하고 `slurmctld`를 재시작합니다.

```bash
SuspendExcNodes=hpc-pg0-[1-2]   # 특정 노드 제외
SuspendExcParts=hpc             # 파티션 전체 제외
```

---

## 14.7 설정 파일

설정 파일은 `/sched/`에 위치하며 `/etc/slurm/`으로 심볼릭 링크됩니다. 스케줄러와 계산 노드에서 동일해야 합니다.

| 파일 | 관리 주체 |
|------|-----------|
| `/etc/slurm/slurm.conf` | CycleCloud가 스케줄러 최초 기동 시 생성 |
| `/etc/slurm/cyclecloud.conf` | `cyclecloud_slurm.sh`가 생성·관리. 수동 편집은 재실행 시 되돌려질 수 있음 |
| `/etc/slurm/azure.conf` | 파티션·노드 정의 (→ [09장](09-파티션-관리-및-추가.md)) |
| `/etc/slurm/topology.conf` | `cyclecloud_slurm.sh`가 생성·관리 |

검증해야 할 주요 `slurm.conf` 설정:

```ini
SchedulerType        = sched/backfill
SelectType           = select/cons_tres
SlurmctldParameters  = idle_on_node_suspend
JobSubmitPlugins     = job_submit/cyclecloud
PrivateData          = cloud
TreeWidth            = 65533
```

설정 파일을 수정한 뒤에는 즉시 반영합니다.

```bash
sudo scontrol reconfigure
```

---

## 14.8 트러블슈팅

### 로그 위치

| 위치 | 파일 |
|------|------|
| 스케줄러 | `/var/log/slurmctld/slurmctld.log` |
| 스케줄러 | `/var/log/slurmctld/resume.log`, `/var/log/slurmctld/suspend.log` |
| 스케줄러 | `/var/log/slurmctld/slurmdbd.log` (Accounting 사용 시) |
| 계산 노드 | `/var/log/slurmd/slurmd.log` |

Autoscale 문제는 `slurmctld.log`에서 `power_save` 항목으로 resume 호출 여부를, `resume.log`에서 기동 결과를 확인합니다.

### scontrol 주요 명령

```bash
scontrol reconfig                                  # 설정 재적용
scontrol show node <노드명>                        # 노드 정보
scontrol show job <작업ID>                         # 작업 정보
scontrol update nodename=<노드명> state=idle       # DOWN 노드 복구
```

### 자주 겪는 문제

| 증상 | 원인 / 조치 |
|------|-------------|
| Autoscale이 노드를 기동하지 않음 | 노드가 `DOWN` 상태. `scontrol update ... state=idle`로 복구 |
| 변경한 구성이 반영 안 됨 | 스케줄러에서 `cyclecloud_slurm.sh apply_changes` 실행 필요. 실행 중 노드는 종료 후 재기동 |
| 신규 노드가 기동 실패 (`match existing scaleset attribute`) | MPI 파티션 VM 변경 시 기존 노드 미종료. 노드 종료 후 재적용 |
| 작업 제출·로그 확인 방법 | [11장 트러블슈팅](11-트러블슈팅-로그.md) |

---

## 참고 자료

- [CycleCloud Slurm 통합 (Microsoft Learn)](https://learn.microsoft.com/azure/cyclecloud/slurm)
- [cyclecloud-slurm 프로젝트 (GitHub)](https://github.com/Azure/cyclecloud-slurm)
- [Slurm 공식 문서 (SchedMD)](https://slurm.schedmd.com/)

---

다음 단계: [4. 노드 증설/감설 및 노드 사이즈 변경](04-노드-증감설-사이즈변경.md)

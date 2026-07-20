# CycleCloud 교육 환경 인프라 (Bicep)

이 폴더는 실습용 Azure CycleCloud 서버 환경을 코드로 배포하는 Bicep 템플릿입니다.

## 배포되는 리소스
- VNet(`cc-vnet`) + 서브넷(`cyclecloud`, `compute`) + NSG(`cc-nsg`, 443/80/22)
- Public IP(`cc-pip`, DNS 레이블 포함)
- CycleCloud 8 서버 VM(`cc-server`, **시스템 할당 + 사용자 할당 관리 ID**)
- Locker 용 Storage Account + `cyclecloud` 컨테이너 (**공용 접근 차단**)
- Locker 용 사용자 할당 관리 ID(`cc-locker-id`) + Blob 데이터 권한
- Blob **프라이빗 엔드포인트** + Private DNS 존(`privatelink.blob.*`)
- 역할 할당: 서버 시스템 ID → RG `Contributor`, `cc-locker-id` → `Storage Blob Data Contributor`

> ℹ️ 이 구독은 Azure Policy 로 스토리지의 **공용 접근/공유 키 인증이 강제 차단**됩니다.
> 따라서 CycleCloud Locker 는 공유 키가 아닌 **관리 ID(Managed Identity)** 로 접근해야 하며,
> 서버·계산 노드가 Locker 에 도달하도록 **Blob 프라이빗 엔드포인트**가 필요합니다.
> 위 리소스와 역할 할당은 모두 Bicep 에 포함되어 자동 구성됩니다.

## 사전 준비
```powershell
az login
az account set --subscription <YOUR_SUBSCRIPTION_ID>
# 마켓플레이스 이미지 약관 동의 (최초 1회)
az vm image terms accept --urn azurecyclecloud:azure-cyclecloud:cyclecloud8-gen2:latest
# SSH 키 준비 (없으면 생성)
ssh-keygen -t rsa -b 4096 -f keys/cyclecloud_rsa -N ""
```

## 1. 리소스 그룹 생성
```powershell
az group create -n rg-cyclecloud-training -l koreacentral
```

## 2. 배포
```powershell
$pub = (Get-Content keys/cyclecloud_rsa.pub -Raw).Trim()
$myip = (Invoke-RestMethod "https://api.ipify.org")
az deployment group create `
  -g rg-cyclecloud-training -n cyclecloud-deploy `
  --template-file infra/main.bicep `
  --parameters adminSshPublicKey="$pub" allowedSshCidr="$myip/32"
```

## 3. CycleCloud 계정(구독) 등록 — 관리 ID Locker

포털 최초 설정 마법사 또는 CLI 로 Azure 구독을 등록할 때, Locker 인증을 **Managed Identity**
로 지정하고 `cc-locker-id` 를 사용해야 합니다. 배포 출력의 `lockerIdentityResourceId` 를 사용합니다.

- **포털**: Settings → **Add Subscription** → 인증에서 *Managed Identity* 선택 →
  Storage Locker 를 만들 때 **Locker Authentication = Managed Identity**, 자격증명으로 `cc-locker-id` 선택.
- 등록 시 서브넷은 `cc-vnet` / `compute`, 스토리지는 배포된 `cclk...` 계정을 지정합니다.

> ⚠️ Locker 를 **Shared Access Key** 로 만들면 정책상 스토리지 공유 키가 차단되어
> 노드가 `Staging resources (403)` 에서 실패합니다. 반드시 Managed Identity 를 사용하세요.
> 자세한 증상/해결은 [트러블슈팅](../docs/06-트러블슈팅-로그.md) 6.4 참조.

## 4. 출력값 확인 (포털 URL, Locker 관리 ID 등)
```powershell
az deployment group show -g rg-cyclecloud-training -n cyclecloud-deploy `
  --query properties.outputs
```

## 파라미터
| 이름 | 기본값 | 설명 |
|------|--------|------|
| `location` | RG 위치 | 리전 |
| `namePrefix` | `cc` | 리소스 이름 접두사 |
| `adminUsername` | `azureadmin` | 서버 관리자 |
| `adminSshPublicKey` | (필수) | SSH 공개키 |
| `vmSize` | `Standard_D4s_v5` | 서버 VM 크기 |
| `imageVersion` | `latest` | CycleCloud 이미지 버전 |
| `allowedSshCidr` | `*` | SSH 허용 소스(내 IP/32 권장) |
| `allowedHttpsCidr` | `Internet` | 포털 443 허용 소스 |

## 환경 삭제 (과금 정리)
```powershell
# 클러스터를 먼저 Terminate 한 뒤, 리소스 그룹 삭제
az group delete -n rg-cyclecloud-training --yes --no-wait
```
> CycleCloud 가 만든 노드가 별도 RG 에 있으면 그 RG 도 함께 삭제하세요.

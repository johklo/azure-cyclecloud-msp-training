# CycleCloud 교육 환경 인프라 (Bicep)

이 폴더는 실습용 Azure CycleCloud 서버 환경을 코드로 배포하는 Bicep 템플릿입니다.

## 배포되는 리소스
- VNet(`cc-vnet`) + 서브넷(`cyclecloud`, `compute`) + NSG(`cc-nsg`, 443/80/22)
- Public IP(`cc-pip`, DNS 레이블 포함)
- CycleCloud 8 서버 VM(`cc-server`, 시스템 할당 관리 ID)
- Locker 용 Storage Account + `cyclecloud` 컨테이너

> ⚠️ 노드 생성 권한(구독 범위 `Contributor`)은 보안상 Bicep 에 포함하지 않고
> 배포 후 별도 명령으로 부여합니다(아래 3번).

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

## 3. 관리 ID 에 노드 생성 권한 부여 (배포 후 1회)
```powershell
$pid = az deployment group show -g rg-cyclecloud-training -n cyclecloud-deploy `
  --query properties.outputs.principalId.value -o tsv
az role assignment create --assignee-object-id $pid `
  --assignee-principal-type ServicePrincipal `
  --role Contributor --scope /subscriptions/<YOUR_SUBSCRIPTION_ID>
```

## 4. 출력값 확인 (포털 URL 등)
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

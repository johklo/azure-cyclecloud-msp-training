# Azure CycleCloud 교육 환경 인프라 (Bicep & Automated Scripts)

이 폴더는 실습용 **Azure CycleCloud 8** 서버 및 네트워크 인프라를 한 번의 명령어로 자동 배포/삭제하는 Bicep 템플릿과 자동화 스크립트 모음입니다.

## 🚀 빠른 시작 (자동 배포)

### PowerShell (Windows)
```powershell
# 실습 환경 자동 배포 (RG 생성 + SSH키 + Bicep 배포 + RBAC 권한 부여)
.\deploy-lab.ps1

# (선택) 구독 ID 지정 배포
.\deploy-lab.ps1 -SubscriptionId "<YOUR_SUBSCRIPTION_ID>"
```

### Bash (Linux / macOS / WSL)
```bash
chmod +x deploy-lab.sh destroy-lab.sh
./deploy-lab.sh
```

---

## 🛠️ 실습 종료 후 비용 정리 (Teardown)

```powershell
# 1) 서버 일시 중지 (비용 최소화, 데이터/설정 유지)
.\destroy-lab.ps1 -Mode Deallocate

# 2) 전체 환경 삭제 (리소스 그룹 완전 삭제)
.\destroy-lab.ps1 -Mode Delete
```

---

## 📦 배포되는 Azure 리소스 상세
- **VNet**: `cc-vnet` (`10.0.0.0/16`)
- **Subnet**:
  - `cyclecloud` (`10.0.0.0/24`) — 서버 VM용
  - `compute` (`10.0.1.0/24`) — HPC 계산 노드 생성용
- **NSG**: `cc-nsg` (HTTPS 443, HTTP 80, SSH 22 허용)
- **Public IP**: `cc-pip` (FQDN DNS Label 자동 생성)
- **CycleCloud Server VM**: `cc-server` (`Standard_D4s_v5`, Ubuntu Gen2)
- **Managed Identity**: 서버 VM 시스템 할당 관리 ID (구독 범위 `Contributor` 자동 부여)
- **Locker Storage Account**: `cclkekwphusd3i` (컨테이너 `cyclecloud`)

---

## 📋 수동 배포 단계 (참고용)

1. **사전 로그인 및 약관 동의**:
   ```bash
   az login
   az vm image terms accept --urn azurecyclecloud:azure-cyclecloud:cyclecloud8-gen2:latest
   ```

2. **SSH 키 생성**:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ../keys/cyclecloud_rsa -N ""
   ```

3. **리소스 그룹 생성 및 Bicep 배포**:
   ```bash
   az group create -n rg-cyclecloud-training -l koreacentral
   az deployment group create \
     -g rg-cyclecloud-training -n cyclecloud-deploy \
     --template-file main.bicep \
     --parameters adminSshPublicKey="$(cat ../keys/cyclecloud_rsa.pub)" allowedSshCidr="$(curl -s https://api.ipify.org)/32"
   ```

4. **관리 ID Contributor 권한 부여**:
   ```bash
   PID=$(az deployment group show -g rg-cyclecloud-training -n cyclecloud-deploy --query properties.outputs.principalId.value -o tsv)
   az role assignment create --assignee-object-id $PID --assignee-principal-type ServicePrincipal --role Contributor --scope /subscriptions/<YOUR_SUBSCRIPTION_ID>
   ```

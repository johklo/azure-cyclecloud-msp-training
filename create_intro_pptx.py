"""고객 소개용 Azure CycleCloud 개요 프레젠테이션 생성 스크립트.

docs 폴더의 교육 매뉴얼(01~12) 및 KT 브리핑 자료를 근간으로,
'CycleCloud가 무엇이고 왜 필요한가'를 고객 관점에서 소개하는 덱을 만든다.
"""
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE

# --- Color Palette (교육 덱과 동일 톤) ---
NAVY = RGBColor(15, 34, 64)
BLUE = RGBColor(0, 114, 206)
LIGHT_BG = RGBColor(245, 247, 250)
DARK_TEXT = RGBColor(30, 30, 30)
WHITE = RGBColor(255, 255, 255)
GRAY = RGBColor(100, 100, 100)
ACCENT_ORANGE = RGBColor(227, 85, 33)
CARD_BG = RGBColor(235, 240, 248)
CARD_BORDER = RGBColor(200, 215, 235)
GREEN_BG = RGBColor(233, 245, 236)
GREEN_BORDER = RGBColor(150, 200, 160)
GREEN_TITLE = RGBColor(30, 120, 60)

CATEGORY = "AZURE CYCLECLOUD | 고객 소개 자료 (Customer Introduction)"


def build(output_path):
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank = prs.slide_layouts[6]

    def bg(slide, color=LIGHT_BG):
        s = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(7.5))
        s.fill.solid(); s.fill.fore_color.rgb = color; s.line.color.rgb = color
        return s

    def header(slide, title, category=CATEGORY):
        bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(1.1))
        bar.fill.solid(); bar.fill.fore_color.rgb = NAVY; bar.line.color.rgb = NAVY
        tf = bar.text_frame; tf.word_wrap = True
        tf.margin_left = Inches(0.6); tf.margin_top = Inches(0.15)
        p0 = tf.paragraphs[0]; p0.text = category.upper()
        p0.font.size = Pt(10); p0.font.bold = True; p0.font.color.rgb = BLUE
        p1 = tf.add_paragraph(); p1.text = title
        p1.font.size = Pt(22); p1.font.bold = True; p1.font.color.rgb = WHITE

    def card(slide, left, top, width, height, title, items,
             bg_color=CARD_BG, border_color=CARD_BORDER, title_color=NAVY, title_size=16):
        c = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE,
                                   Inches(left), Inches(top), Inches(width), Inches(height))
        c.fill.solid(); c.fill.fore_color.rgb = bg_color
        c.line.color.rgb = border_color; c.line.width = Pt(1.5)
        tf = c.text_frame; tf.word_wrap = True
        tf.margin_left = Inches(0.25); tf.margin_right = Inches(0.25)
        tf.margin_top = Inches(0.2); tf.margin_bottom = Inches(0.2)
        p0 = tf.paragraphs[0]; p0.text = title
        p0.font.size = Pt(title_size); p0.font.bold = True; p0.font.color.rgb = title_color
        for item in items:
            p = tf.add_paragraph()
            p.text = item if item.startswith("  ") else f"• {item}"
            p.font.size = Pt(12); p.font.color.rgb = DARK_TEXT; p.space_before = Pt(4)

    def textbox(slide, left, top, width, height):
        return slide.shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height)).text_frame

    # ---------------------------------------------------------------
    # SLIDE 1 : Title
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s, NAVY)
    tf = textbox(s, 1.0, 2.0, 11.333, 4.2); tf.word_wrap = True
    p = tf.paragraphs[0]; p.text = "AZURE CYCLECLOUD"
    p.font.size = Pt(18); p.font.bold = True; p.font.color.rgb = BLUE
    p = tf.add_paragraph(); p.text = "Azure에서 구현하는 엔터프라이즈 HPC · AI 클러스터"
    p.font.size = Pt(36); p.font.bold = True; p.font.color.rgb = WHITE
    p = tf.add_paragraph()
    p.text = "필요할 때 자동으로 확장하고, 쓴 만큼만 지불하는 클라우드 HPC 오케스트레이션"
    p.font.size = Pt(18); p.font.color.rgb = RGBColor(200, 215, 235)
    p = tf.add_paragraph(); p.text = "\nAzure SRE Team | 고객 소개 자료 | 2026"
    p.font.size = Pt(14); p.font.color.rgb = GRAY

    # ---------------------------------------------------------------
    # SLIDE 2 : HPC의 과제 (Why)
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "왜 클라우드 HPC 인가? — 기존 온프레미스의 한계")
    card(s, 0.6, 1.4, 5.8, 5.5, "🏢 온프레미스 HPC의 고민", [
        "고정된 물리 클러스터 → 피크 수요에 맞춰 과투자",
        "평시에는 값비싼 GPU/CPU 자원이 유휴 상태로 낭비",
        "증설 시 하드웨어 조달·구축에 수 주~수 개월 소요",
        "노후화·유지보수·전력/공간 비용 지속 부담",
        "연구·개발 폭증 시 즉시 대응 불가 (자원 병목)",
    ], bg_color=RGBColor(254, 243, 235), border_color=RGBColor(240, 150, 100),
        title_color=ACCENT_ORANGE)
    card(s, 6.8, 1.4, 5.9, 5.5, "☁️ Azure CycleCloud 로 해결", [
        "작업(Job) 수요에 따라 계산 노드를 자동 증설·감설",
        "유휴 시 자동 종료 → 사용한 만큼만 과금(OpEx)",
        "필요한 최신 GPU/CPU SKU를 즉시 선택·확장",
        "익숙한 스케줄러(Slurm 등) 환경을 그대로 클라우드로",
        "인프라 조달 없이 몇 분 만에 클러스터 기동",
    ], bg_color=GREEN_BG, border_color=GREEN_BORDER, title_color=GREEN_TITLE)

    # ---------------------------------------------------------------
    # SLIDE 3 : What is CycleCloud
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "Azure CycleCloud 란?")
    tf = textbox(s, 0.6, 1.3, 12.1, 1.3); tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = ("Azure 환경에서 HPC(고성능 컴퓨팅) 클러스터를 손쉽게 생성·관리하고, "
              "수요에 따라 자동으로 오케스트레이션(증설/감설)하는 엔터프라이즈 관리 서비스입니다.")
    p.font.size = Pt(15); p.font.color.rgb = DARK_TEXT
    card(s, 0.6, 2.8, 3.8, 4.1, "🧩 익숙한 스케줄러 지원", [
        "Slurm, OpenPBS, LSF,",
        "HTCondor, Grid Engine 등",
        "기존 워크로드·스크립트를",
        "수정 없이 클라우드로 이전",
    ])
    card(s, 4.7, 2.8, 3.8, 4.1, "📈 지능형 오토스케일", [
        "Job 큐 수요를 감지해",
        "VMSS 기반 노드 자동 증설",
        "완료 후 유휴 노드는",
        "자동 감설로 비용 최소화",
    ])
    card(s, 8.8, 2.8, 3.9, 4.1, "🎛️ 통합 제어 인터페이스", [
        "웹 포털 GUI",
        "CLI (cyclecloud / azslurm)",
        "REST API",
        "→ 운영자 친화적 단일 제어",
    ])

    # ---------------------------------------------------------------
    # SLIDE 4 : 핵심 가치 (Benefits)
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "CycleCloud 가 제공하는 핵심 가치")
    card(s, 0.6, 1.4, 5.8, 2.6, "💰 비용 효율 (Pay-as-you-go)", [
        "유휴 자원 자동 감설로 과투자 제거",
        "필요한 순간에만 GPU/CPU 확보",
        "Job Accounting 으로 사용량 기반 정산·차지백",
    ])
    card(s, 6.8, 1.4, 5.9, 2.6, "⚡ 민첩성 (Agility)", [
        "몇 분 만에 클러스터 기동, 즉시 확장",
        "최신 VM SKU·GPU 세대를 바로 채택",
        "템플릿(IaC) 기반 반복 가능한 배포",
    ])
    card(s, 0.6, 4.2, 5.8, 2.7, "🔐 보안 & 거버넌스", [
        "Managed Identity 로 시크릿 없는 프로비저닝",
        "VNet·Private Subnet·NSG 기반 격리",
        "Azure RBAC 로 접근 제어 및 감사",
    ])
    card(s, 6.8, 4.2, 5.9, 2.7, "🛠️ 운영 편의성", [
        "웹 포털 + CLI 통합 관리",
        "cluster-init 로 노드 커스터마이징 표준화",
        "Managed Prometheus/Grafana 모니터링 연계",
    ])

    # ---------------------------------------------------------------
    # SLIDE 5 : Architecture
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "아키텍처 한눈에 보기")
    card(s, 0.6, 1.4, 3.8, 5.5, "① 컨트롤 플레인 (Server)", [
        "CycleCloud Server VM",
        "웹 포털 GUI (HTTPS 443)",
        "cycle_server 서비스 & CLI",
        "System-assigned Managed Identity",
        "  - 구독 범위 노드 프로비저닝",
        "  - 자격증명/암호 없이 오케스트레이션",
    ])
    card(s, 4.7, 1.4, 3.8, 5.5, "② 스케줄러 & 계산 노드", [
        "스케줄러 노드 (예: Slurm Master)",
        "  - 워크로드 스케줄링 & 자원 할당",
        "실행(Execute) 노드",
        "  - VMSS 기반 필요 시 자동 생성",
        "  - Job 완료 후 유휴 시 자동 감설",
        "공유 저장소 /shared, /sched (NFS)",
    ])
    card(s, 8.8, 1.4, 3.9, 5.5, "③ 스토리지 & Locker", [
        "Blob Storage (Locker)",
        "  - 클러스터 템플릿 보관",
        "  - cluster-init 커스텀 스크립트",
        "데이터용 공유 스토리지",
        "  - Blob NFS / Azure Files",
        "  - Azure Managed Lustre (고성능)",
    ])

    # ---------------------------------------------------------------
    # SLIDE 6 : Autoscale lifecycle (How it works)
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "동작 방식 — 자동확장 라이프사이클")
    tf = textbox(s, 0.6, 1.3, 12.1, 0.9); tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "사용자가 작업을 제출하면, CycleCloud 가 큐를 감지해 노드를 자동 생성하고 완료 후 회수합니다."
    p.font.size = Pt(14); p.font.color.rgb = DARK_TEXT
    steps = [
        ("1. Job 제출", "사용자가 sbatch / srun 으로\nSlurm 큐에 작업 등록"),
        ("2. 수요 감지 & 증설", "CycleCloud 가 대기 Job 확인\n→ 계산 노드 자동 Acquiring"),
        ("3. 노드 Ready & 실행", "Off→Acquiring→Preparing→Ready\ncluster-init 적용 후 Job 실행"),
        ("4. 완료 & 자동 감설", "작업 완료·유휴 감지\n→ 노드 자동 종료(비용 절감)"),
    ]
    x = 0.6
    for title, body in steps:
        c = s.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(x), Inches(2.6), Inches(2.85), Inches(3.2))
        c.fill.solid(); c.fill.fore_color.rgb = CARD_BG
        c.line.color.rgb = BLUE; c.line.width = Pt(1.5)
        tf = c.text_frame; tf.word_wrap = True
        tf.margin_left = Inches(0.2); tf.margin_right = Inches(0.2); tf.margin_top = Inches(0.25)
        p0 = tf.paragraphs[0]; p0.text = title
        p0.font.size = Pt(15); p0.font.bold = True; p0.font.color.rgb = NAVY
        p1 = tf.add_paragraph(); p1.text = body
        p1.font.size = Pt(12); p1.font.color.rgb = DARK_TEXT; p1.space_before = Pt(10)
        if x > 3.0:
            ar = s.shapes.add_shape(MSO_SHAPE.RIGHT_ARROW, Inches(x - 0.55), Inches(3.9), Inches(0.5), Inches(0.6))
            ar.fill.solid(); ar.fill.fore_color.rgb = BLUE; ar.line.color.rgb = BLUE
        x += 3.1
    tf = textbox(s, 0.6, 6.1, 12.1, 0.8); tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "핵심: 필요한 만큼만 켜지고, 끝나면 꺼진다 → 성능과 비용을 동시에 최적화"
    p.font.size = Pt(13); p.font.bold = True; p.font.color.rgb = GREEN_TITLE

    # ---------------------------------------------------------------
    # SLIDE 7 : Slurm & Scheduler
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "표준 스케줄러 환경 그대로 — Slurm 예시")
    card(s, 0.6, 1.4, 5.8, 5.5, "⚡ 사용자에게 익숙한 명령 그대로", [
        "sinfo : 파티션·노드 상태 조회",
        "squeue : 큐의 Job 상태 및 대기 사유",
        "sbatch <script> : 배치 작업 제출",
        "srun <cmd> : 자원 할당받아 즉시 실행",
        "sacct : 완료 작업 이력·자원 사용량 조회",
        "→ 기존 HPC 워크플로 학습비용 최소화",
    ])
    card(s, 6.8, 1.4, 5.9, 5.5, "🛠️ 운영자용 CycleCloud 제어", [
        "cyclecloud show_cluster : 클러스터 상태",
        "cyclecloud start/terminate_cluster : 제어",
        "cyclecloud project upload : cluster-init 배포",
        "azslurm resume/suspend : 수동 노드 제어",
        "azslurm scale : 변경분 무중단 반영",
        "→ GUI·CLI·API 어디서든 동일 제어",
    ])

    # ---------------------------------------------------------------
    # SLIDE 8 : Storage & Data
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "데이터 · 스토리지 유연한 연계")
    card(s, 0.6, 1.4, 3.8, 5.5, "📁 공유 파일 시스템", [
        "/shared, /sched (NFS)",
        "모든 노드가 공유하는",
        "홈·스케줄러 저장소",
        "Azure Files / Blob NFS 연동",
    ])
    card(s, 4.7, 1.4, 3.8, 5.5, "🚀 고성능 병렬 스토리지", [
        "Azure Managed Lustre",
        "대용량·초고속 병렬 I/O",
        "AI 학습·시뮬레이션 등",
        "I/O 집약 워크로드에 최적",
    ])
    card(s, 8.8, 1.4, 3.9, 5.5, "📦 오브젝트 스토리지", [
        "Blob Storage (Locker)",
        "클러스터 구성·템플릿",
        "cluster-init 스크립트 보관",
        "데이터 레이크 연계 가능",
    ])

    # ---------------------------------------------------------------
    # SLIDE 9 : Observability - Accounting & Monitoring
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "운영 가시성 — 비용 정산 & 모니터링")
    card(s, 0.6, 1.4, 5.8, 5.5, "📊 Job Accounting (비용 가시성)", [
        "Job별 CPU/GPU/메모리 사용량 영구 기록",
        "Azure Database for MySQL 연동",
        "sacct·sreport 로 유저·프로젝트별 정산",
        "부서·과제 단위 차지백(chargeback) 기반 마련",
        "azslurm cost 로 작업별 비용 리포트(실험적)",
    ])
    card(s, 6.8, 1.4, 5.9, 5.5, "📈 GPU / 인프라 모니터링", [
        "Node Exporter → Prometheus 메트릭 수집",
        "Azure Managed Prometheus (remote_write)",
        "Azure Managed Grafana 대시보드 시각화",
        "실시간 GPU 사용률·메모리·온도 감시",
        "DCGM 기반 GPU 상세 지표 지원",
    ], bg_color=GREEN_BG, border_color=GREEN_BORDER, title_color=GREEN_TITLE)

    # ---------------------------------------------------------------
    # SLIDE 10 : Security & Governance
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "보안 · 거버넌스")
    card(s, 0.6, 1.4, 3.8, 5.5, "🔑 자격증명 없는 운영", [
        "System-assigned Managed Identity",
        "시크릿·암호 저장 없이",
        "Azure 리소스 프로비저닝",
        "키 유출 위험 최소화",
    ])
    card(s, 4.7, 1.4, 3.8, 5.5, "🌐 네트워크 격리", [
        "전용 VNet / Subnet 배치",
        "NSG 로 포트·트래픽 제어",
        "Private Endpoint 로",
        "스토리지·DB 비공개 연결",
    ])
    card(s, 8.8, 1.4, 3.9, 5.5, "👥 접근 제어 & 사용자", [
        "Azure RBAC 기반 권한 관리",
        "사용자 관리: Built-in /",
        "Active Directory / LDAP / Entra ID",
        "SSH Keypair·sudo 정책 제어",
    ])

    # ---------------------------------------------------------------
    # SLIDE 11 : Use cases & Next steps
    # ---------------------------------------------------------------
    s = prs.slides.add_slide(blank); bg(s)
    header(s, "활용 사례 & 다음 단계")
    card(s, 0.6, 1.4, 5.8, 5.5, "🎯 주요 활용 사례", [
        "AI/ML 대규모 분산 학습 (GPU 클러스터)",
        "CAE·CFD 시뮬레이션 및 렌더링",
        "유전체·생명과학 등 연구 컴퓨팅",
        "금융 리스크·몬테카를로 시뮬레이션",
        "NGC 컨테이너 기반 가속 워크로드",
    ])
    card(s, 6.8, 1.4, 5.9, 5.5, "🚀 도입 여정 (Next Steps)", [
        "1. 워크로드·스케줄러 요건 진단",
        "2. Azure 구독·네트워크·쿼터 준비",
        "3. CycleCloud 서버 및 클러스터 PoC 구축",
        "4. cluster-init·모니터링·정산 체계 구성",
        "5. 운영 이관 및 MSP 지원 체계 수립",
    ], bg_color=GREEN_BG, border_color=GREEN_BORDER, title_color=GREEN_TITLE)
    tf = textbox(s, 0.6, 6.95, 12.1, 0.5); tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "상세 구축·운영 절차는 'Azure CycleCloud MSP 운영 매뉴얼(12개 모듈)'을 참고하십시오."
    p.font.size = Pt(12); p.font.italic = True; p.font.color.rgb = GRAY

    prs.save(output_path)
    print("Presentation saved.")


if __name__ == "__main__":
    build("docs/CycleCloud_고객소개.pptx")

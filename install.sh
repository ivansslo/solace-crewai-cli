#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Solace Hermes — Termux Full Installer v3
#  1 script, 1 session, tidak pernah berhenti
# ============================================================

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
MAG='\033[0;35m'
RST='\033[0m'

clear
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${MAG}⚡ SOLACE HERMES — FULL INSTALLER v3${RST}        ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""

# ---- STEP 1: Termux ----
echo -e "${GRN}📦 [1/4] Termux packages...${RST}"
export DEBIAN_FRONTEND=noninteractive
pkg update -y 2>/dev/null || true
pkg install -y proot-distro git curl wget openssh 2>/dev/null || true
echo -e "${GRN}  ✅ Termux ready${RST}"

# ---- STEP 2: Ubuntu ----
echo ""
echo -e "${GRN}🐧 [2/4] Ubuntu rootfs...${RST}"
proot-distro install ubuntu 2>/dev/null || echo -e "${YLW}  ℹ️ Ubuntu sudah ada, lanjut${RST}"
echo -e "${GRN}  ✅ Ubuntu ready${RST}"

# ---- STEP 3: Semua di dalam Ubuntu ----
echo ""
echo -e "${GRN}🔧 [3/4] Setup semua di Ubuntu (10-30 menit)...${RST}"
echo ""

proot-distro login ubuntu -- bash << 'UBUNTUBLOCK'
export DEBIAN_FRONTEND=noninteractive

echo "━━━ [3a] System packages ━━━"
apt update -qq 2>/dev/null
apt install -y -qq python3 python3-pip python3-venv python3-dev git curl wget build-essential libffi-dev libssl-dev nodejs npm ca-certificates jq 2>/dev/null || true
echo "  ✅ System packages done"

echo ""
echo "━━━ [3b] Tailscale ━━━"
if command -v tailscale >/dev/null 2>&1; then
    echo "  ✅ Tailscale sudah ada"
else
    curl -fsSL https://tailscale.com/install.sh | sh 2>/dev/null || true
    echo "  ✅ Tailscale done"
fi

echo ""
echo "━━━ [3c] CrewAI (sabar, paling lama) ━━━"
cd /root
if [ ! -d crewai-env ]; then
    python3 -m venv crewai-env
fi
. crewai-env/bin/activate
pip install --upgrade pip setuptools wheel -q 2>/dev/null
echo "  → pip ready, installing crewai..."
pip install crewai crewai-tools 2>&1 | tail -5
echo ""
crewai version 2>/dev/null || python3 -c "import crewai;print('crewai',crewai.__version__)" 2>/dev/null || echo "  ⚠️ crewai partial"
echo "  ✅ CrewAI done"

echo ""
echo "━━━ [3d] Hermes Crew Project ━━━"
mkdir -p /root/hermes-crew/src/hermes_crew
cd /root/hermes-crew

cat > src/hermes_crew/__init__.py << 'PY1'
pass
PY1

cat > src/hermes_crew/crew.py << 'PY2'
from crewai import Agent, Crew, Process, Task

researcher = Agent(
    role="Research Specialist",
    goal="Find accurate, comprehensive information on any topic",
    backstory="Expert researcher. Part of Solace Hermes AI Hub.",
    verbose=True, allow_delegation=False,
)
analyst = Agent(
    role="Data Analyst",
    goal="Analyze findings and extract actionable insights",
    backstory="Skilled analyst who finds patterns and recommendations.",
    verbose=True, allow_delegation=False,
)
writer = Agent(
    role="Content Writer",
    goal="Create clear, well-structured reports",
    backstory="Professional writer who creates concise content.",
    verbose=True, allow_delegation=False,
)

def run_crew(topic):
    t1 = Task(description="Research: " + topic, expected_output="Research summary with key findings", agent=researcher)
    t2 = Task(description="Analyze: " + topic, expected_output="Analysis with insights and recommendations", agent=analyst)
    t3 = Task(description="Write report: " + topic, expected_output="Professional report in markdown", agent=writer)
    crew = Crew(agents=[researcher, analyst, writer], tasks=[t1, t2, t3], process=Process.sequential, verbose=True)
    return str(crew.kickoff())

if __name__ == "__main__":
    import sys
    topic = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "AI agents in 2026"
    print(run_crew(topic))
PY2

cat > .env << 'ENV1'
GROQ_API_KEY=YOUR_KEY_HERE
OPENAI_API_KEY=YOUR_KEY_HERE
CREWAI_TOKEN=YOUR_TOKEN_HERE
CREWAI_TELEMETRY_OPT_OUT=true
SOLACE_URL=https://mr-connection-mwc1f9igml1.messaging.solace.cloud:9443
SOLACE_USER=solace-cloud-client
SOLACE_PASS=YOUR_PASS_HERE
ENV1

cat > /root/hermes << 'HLNCH'
#!/bin/bash
. /root/crewai-env/bin/activate 2>/dev/null
cd /root/hermes-crew
. .env 2>/dev/null
export GROQ_API_KEY OPENAI_API_KEY CREWAI_TELEMETRY_OPT_OUT CREWAI_TOKEN
case "$1" in
    run|crew) shift; PYTHONPATH=src python3 -m hermes_crew.crew "$@" ;;
    deploy) crewai deploy ;;
    version) crewai version 2>/dev/null || python3 -c "import crewai;print(crewai.__version__)" 2>/dev/null ;;
    status)
        echo "🤖 Solace Hermes Status"
        crewai version 2>/dev/null || python3 -c "import crewai;print('crewai',crewai.__version__)" 2>/dev/null
        python3 --version
        echo "Project: /root/hermes-crew"
        curl -s -m 5 https://hermes-cloudflare.certveis.workers.dev/health 2>/dev/null && echo "Gateway: Online" || echo "Gateway: check connection"
        ;;
    env) nano .env 2>/dev/null || vi .env ;;
    *) echo "⚡ Solace Hermes CLI"; echo ""; echo "  hermes run [topic]   Run AI crew"; echo "  hermes deploy        Deploy to CrewAI Cloud"; echo "  hermes version       Show version"; echo "  hermes status        System check"; echo "  hermes env           Edit API keys"; echo ""; echo "  Example: hermes run \"AI agents 2026\"" ;;
esac
HLNCH
chmod +x /root/hermes
echo "  ✅ Project + launcher done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ UBUNTU SETUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
UBUNTUBLOCK

echo -e "${GRN}  ✅ Ubuntu setup done${RST}"

# ---- STEP 4: Termux shortcuts (SETELAH ubuntu selesai) ----
echo ""
echo -e "${GRN}🚀 [4/4] Termux shortcuts...${RST}"

cat > $PREFIX/bin/ubuntu << 'S1'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu
S1
chmod +x $PREFIX/bin/ubuntu

cat > $PREFIX/bin/hermes << 'S2'
#!/data/data/com.termux/files/usr/bin/bash
if [ $# -eq 0 ]; then
    proot-distro login ubuntu -- /root/hermes
else
    proot-distro login ubuntu -- /root/hermes "$@"
fi
S2
chmod +x $PREFIX/bin/hermes

echo -e "${GRN}  ✅ Shortcuts created:${RST}"
echo -e "    ${CYN}ubuntu${RST}   → masuk Ubuntu shell"
echo -e "    ${CYN}hermes${RST}   → jalankan Hermes CLI"

# ---- DONE ----
echo ""
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${GRN}✅ INSTALLATION COMPLETE!${RST}                    ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""
echo -e "  ${CYN}ubuntu${RST}                     Enter Ubuntu"
echo -e "  ${CYN}hermes run \"topic\"${RST}         Run AI crew"
echo -e "  ${CYN}hermes deploy${RST}              Deploy to Cloud"
echo -e "  ${CYN}hermes status${RST}              System check"
echo -e "  ${CYN}hermes env${RST}                 Edit API keys"
echo ""
echo -e "${YLW}🔑 Setup keys: ${CYN}hermes env${RST}"
echo -e "${GRN}💡 Test: ${CYN}hermes run \"AI agents 2026\"${RST}"
echo ""

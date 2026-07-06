#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Solace Hermes — Termux Full Installer
#  Ubuntu rootfs + CrewAI + Tailscale + Project
#  Semua otomatis, tidak perlu input manual
#
#  Usage: bash install.sh
# ============================================================

set -e

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
MAG='\033[0;35m'
RST='\033[0m'

clear
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${MAG}⚡ SOLACE HERMES — FULL INSTALLER${RST}           ${CYN}║${RST}"
echo -e "${CYN}║${RST}  ${GRN}Ubuntu + CrewAI + Tailscale + Project${RST}       ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""

# ---- STEP 1: Termux packages ----
echo -e "${GRN}📦 [1/4] Termux packages...${RST}"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null || pkg update -y
pkg upgrade -y 2>/dev/null || true
pkg install -y proot-distro git curl wget openssh termux-api 2>/dev/null || pkg install -y proot-distro git curl wget openssh
echo -e "${GRN}  ✅ Termux ready${RST}"

# ---- STEP 2: Ubuntu rootfs ----
echo ""
echo -e "${GRN}🐧 [2/4] Ubuntu rootfs...${RST}"
if proot-distro list --installed 2>/dev/null | grep -q ubuntu; then
    echo -e "${YLW}  ℹ️ Ubuntu sudah ada, skip install${RST}"
else
    proot-distro install ubuntu
fi
echo -e "${GRN}  ✅ Ubuntu ready${RST}"

# ---- STEP 3: SEMUA setup di dalam Ubuntu (1 session, tidak keluar) ----
echo ""
echo -e "${GRN}🔧 [3/4] Setup Ubuntu + CrewAI + Tailscale + Project...${RST}"
echo -e "${YLW}  ⏳ Ini butuh 10-30 menit, jangan tutup Termux${RST}"
echo ""

proot-distro login ubuntu -- bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [3a] System packages..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt update -qq 2>/dev/null
apt upgrade -y -qq 2>/dev/null || true
apt install -y -qq python3 python3-pip python3-venv python3-dev \
    git curl wget build-essential nodejs npm \
    ca-certificates gnupg jq libffi-dev libssl-dev 2>/dev/null
echo "  ✅ System packages done"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [3b] Tailscale..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v tailscale >/dev/null 2>&1; then
    echo "  ✅ Tailscale sudah ada"
else
    curl -fsSL https://tailscale.com/install.sh | sh 2>/dev/null || echo "  ⚠️ Tailscale install via script gagal, coba manual..."
    if ! command -v tailscale >/dev/null 2>&1; then
        apt install -y -qq tailscale 2>/dev/null || echo "  ℹ️ Tailscale akan diakses via API"
    fi
fi
echo "  ✅ Tailscale done"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [3c] Python venv + CrewAI..."
echo "  ⏳ Bagian ini paling lama, sabar..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /root
if [ -d crewai-env ]; then
    echo "  ℹ️ venv sudah ada, activate..."
    source crewai-env/bin/activate
else
    python3 -m venv crewai-env
    source crewai-env/bin/activate
fi

pip install --upgrade pip setuptools wheel -q
echo "  ✅ pip upgraded"

echo "  → Installing CrewAI..."
pip install crewai crewai-tools 2>&1 | tail -5
echo ""

# Verify
if crewai version 2>/dev/null; then
    echo "  ✅ CrewAI installed"
elif python3 -c "import crewai; print(crewai.__version__)" 2>/dev/null; then
    echo "  ✅ CrewAI module installed"
else
    echo "  ⚠️ CrewAI install mungkin belum lengkap, lanjut..."
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [3d] Hermes Crew Project..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p /root/hermes-crew/src/hermes_crew/config
cd /root/hermes-crew

# pyproject.toml
cat > pyproject.toml << PYPROJ
[project]
name = "hermes-crew"
version = "1.0.0"
description = "Solace Hermes AI Agent Crew"
requires-python = ">=3.10"
dependencies = ["crewai[tools]>=0.11"]

[build-system]
requires = ["setuptools"]
build-backend = "setuptools.backends._legacy:_Backend"
PYPROJ

cat > src/hermes_crew/__init__.py << INITPY
pass
INITPY

cat > src/hermes_crew/crew.py << CREWPY
from crewai import Agent, Crew, Process, Task
import os

researcher = Agent(
    role="Research Specialist",
    goal="Find accurate, comprehensive information on any topic",
    backstory="Expert researcher with years of experience. Part of Solace Hermes AI Hub.",
    verbose=True,
    allow_delegation=False,
)

analyst = Agent(
    role="Data Analyst",
    goal="Analyze findings and extract actionable insights and patterns",
    backstory="Skilled analyst who finds patterns and provides clear recommendations.",
    verbose=True,
    allow_delegation=False,
)

writer = Agent(
    role="Content Writer",
    goal="Create clear, well-structured reports from research and analysis",
    backstory="Professional writer who creates concise, accurate content.",
    verbose=True,
    allow_delegation=False,
)

def run_crew(topic):
    research_task = Task(
        description="Research thoroughly: " + topic + ". Find key facts and sources.",
        expected_output="Structured research summary with key findings and sources.",
        agent=researcher,
    )
    analysis_task = Task(
        description="Analyze research findings about: " + topic + ". Identify patterns.",
        expected_output="Analysis with insights, conclusions, and recommendations.",
        agent=analyst,
    )
    report_task = Task(
        description="Write a report about: " + topic + ". Combine research and analysis.",
        expected_output="Professional report (300-500 words) in markdown.",
        agent=writer,
    )
    crew = Crew(
        agents=[researcher, analyst, writer],
        tasks=[research_task, analysis_task, report_task],
        process=Process.sequential,
        verbose=True,
    )
    result = crew.kickoff()
    return str(result)

if __name__ == "__main__":
    import sys
    topic = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "AI agents in 2026"
    print(run_crew(topic))
CREWPY

cat > src/hermes_crew/main.py << MAINPY
#!/usr/bin/env python3
import sys
sys.path.insert(0, "/root/hermes-crew/src")
from hermes_crew.crew import run_crew

def main():
    topic = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "AI agents in 2026"
    print("\n🤖 Running Hermes Crew: " + topic + "\n")
    result = run_crew(topic)
    print("\n📄 Result:\n" + result)

if __name__ == "__main__":
    main()
MAINPY

# .env (placeholder, user fills in later)
cat > .env << DOTENV
GROQ_API_KEY=YOUR_GROQ_KEY_HERE
OPENAI_API_KEY=YOUR_GROQ_KEY_HERE
CREWAI_TOKEN=YOUR_CREWAI_TOKEN_HERE
CREWAI_TELEMETRY_OPT_OUT=true
SOLACE_URL=https://mr-connection-mwc1f9igml1.messaging.solace.cloud:9443
SOLACE_USER=solace-cloud-client
SOLACE_PASS=YOUR_SOLACE_PASS
TAILSCALE_API=YOUR_TAILSCALE_KEY
DOTENV

echo "  ✅ Project files created"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [3e] Launcher scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /root/hermes << LAUNCHER
#!/bin/bash
source /root/crewai-env/bin/activate 2>/dev/null
cd /root/hermes-crew
source .env 2>/dev/null
export GROQ_API_KEY OPENAI_API_KEY CREWAI_TELEMETRY_OPT_OUT CREWAI_TOKEN

case "\$1" in
    run|crew)
        shift
        PYTHONPATH=/root/hermes-crew/src python3 -m hermes_crew.main "\$@"
        ;;
    deploy)
        crewai deploy 2>/dev/null || echo "Run: crewai login first, then crewai deploy"
        ;;
    version)
        crewai version 2>/dev/null || python3 -c "import crewai;print(crewai.__version__)" 2>/dev/null || echo "crewai not found"
        ;;
    status)
        echo "🤖 Solace Hermes Status"
        echo "  CrewAI: \$(crewai version 2>/dev/null || python3 -c 'import crewai;print(crewai.__version__)' 2>/dev/null || echo 'not found')"
        echo "  Python: \$(python3 --version 2>&1)"
        echo "  Project: /root/hermes-crew"
        echo "  Agents: Researcher, Analyst, Writer"
        curl -s -m 5 https://hermes-cloudflare.certveis.workers.dev/health >/dev/null 2>&1 && echo "  Gateway: ✅ Online" || echo "  Gateway: ❌ Offline"
        ;;
    env)
        nano /root/hermes-crew/.env 2>/dev/null || vi /root/hermes-crew/.env
        ;;
    *)
        echo "⚡ Solace Hermes CLI"
        echo ""
        echo "  hermes run [topic]    Run crew on a topic"
        echo "  hermes deploy         Deploy to CrewAI Cloud"
        echo "  hermes version        Show version"
        echo "  hermes status         Check system status"
        echo "  hermes env            Edit API keys"
        echo ""
        echo "  Example: hermes run \"AI agents in 2026\""
        ;;
esac
LAUNCHER
chmod +x /root/hermes
echo "  ✅ /root/hermes launcher ready"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ ALL UBUNTU SETUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
'

echo -e "${GRN}  ✅ Ubuntu setup complete${RST}"

# ---- STEP 4: Termux shortcuts ----
echo ""
echo -e "${GRN}🚀 [4/4] Termux shortcuts...${RST}"

cat > $PREFIX/bin/ubuntu << 'UBSH'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu
UBSH
chmod +x $PREFIX/bin/ubuntu

cat > $PREFIX/bin/hermes << 'HMSH'
#!/data/data/com.termux/files/usr/bin/bash
if [ $# -eq 0 ]; then
    proot-distro login ubuntu -- /root/hermes
else
    proot-distro login ubuntu -- /root/hermes "$@"
fi
HMSH
chmod +x $PREFIX/bin/hermes

echo -e "${GRN}  ✅ Shortcuts ready${RST}"

# ---- DONE ----
echo ""
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${GRN}✅ INSTALLATION COMPLETE!${RST}                    ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""
echo -e "${MAG}⚡ Commands:${RST}"
echo -e "  ${CYN}ubuntu${RST}                     Enter Ubuntu"
echo -e "  ${CYN}hermes run \"topic\"${RST}         Run AI crew"
echo -e "  ${CYN}hermes deploy${RST}              Deploy to Cloud"
echo -e "  ${CYN}hermes status${RST}              System check"
echo -e "  ${CYN}hermes env${RST}                 Edit API keys"
echo ""
echo -e "${YLW}🔑 PENTING: Setup API keys dulu!${RST}"
echo -e "  Jalankan: ${CYN}hermes env${RST}"
echo -e "  Ganti YOUR_GROQ_KEY_HERE dengan key asli"
echo ""
echo -e "${GRN}💡 First run: ${CYN}hermes run \"AI agents 2026\"${RST}"
echo ""

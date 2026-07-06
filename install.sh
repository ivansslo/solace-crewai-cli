#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Solace Hermes — Termux Master Installer
#  Ubuntu CLI rootfs + CrewAI + Tailscale + Project
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
echo -e "${CYN}║${RST}  ${MAG}⚡ SOLACE HERMES — TERMUX INSTALLER${RST}         ${CYN}║${RST}"
echo -e "${CYN}║${RST}  ${GRN}Ubuntu CLI + CrewAI + Tailscale${RST}             ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""

# ---- STEP 1: Termux packages ----
echo -e "${GRN}📦 [1/5] Updating Termux packages...${RST}"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null || pkg update -y
pkg upgrade -y 2>/dev/null || true
pkg install -y proot-distro git curl wget openssh
echo -e "${GRN}  ✅ Termux packages ready${RST}"

# ---- STEP 2: Install Ubuntu rootfs ----
echo ""
echo -e "${GRN}🐧 [2/5] Installing Ubuntu rootfs...${RST}"
if proot-distro list --installed 2>/dev/null | grep -q ubuntu; then
    echo -e "${YLW}  ℹ️ Ubuntu already installed, resetting...${RST}"
    proot-distro reset ubuntu 2>/dev/null || true
else
    proot-distro install ubuntu
fi
echo -e "${GRN}  ✅ Ubuntu rootfs installed${RST}"

# ---- STEP 3: Setup Ubuntu environment ----
echo ""
echo -e "${GRN}🔧 [3/5] Setting up Ubuntu environment...${RST}"

proot-distro login ubuntu -- bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive

echo "  → Updating apt..."
apt update -qq && apt upgrade -y -qq 2>/dev/null

echo "  → Installing system packages..."
apt install -y -qq python3 python3-pip python3-venv python3-dev \
    git curl wget build-essential nodejs npm \
    ca-certificates gnupg lsb-release jq \
    libffi-dev libssl-dev 2>/dev/null

echo "  → Python version:"
python3 --version
echo "  ✅ Ubuntu environment ready"
'
echo -e "${GRN}  ✅ Ubuntu base setup complete${RST}"

# ---- STEP 4: Install Tailscale ----
echo ""
echo -e "${GRN}🔗 [4/5] Installing Tailscale...${RST}"

proot-distro login ubuntu -- bash -c '
set -e
echo "  → Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh 2>/dev/null || {
    echo "  → Fallback: manual install..."
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null 2>&1
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list 2>/dev/null
    apt update -qq 2>/dev/null && apt install -y -qq tailscale 2>/dev/null || echo "  ⚠️ Tailscale needs full Linux, will use API instead"
}
echo "  ✅ Tailscale setup done"
'
echo -e "${GRN}  ✅ Tailscale installed${RST}"

# ---- STEP 5: Install CrewAI + Project ----
echo ""
echo -e "${GRN}🤖 [5/5] Installing CrewAI + Solace Hermes Project...${RST}"

proot-distro login ubuntu -- bash -c '
set -e

echo "  → Creating CrewAI virtual environment..."
cd /root
python3 -m venv crewai-env
source crewai-env/bin/activate

echo "  → Upgrading pip..."
pip install --upgrade pip setuptools wheel -q

echo "  → Installing CrewAI (this takes ~2 min)..."
pip install crewai crewai-tools 2>&1 | tail -3

echo "  → Verifying..."
crewai version 2>/dev/null || python3 -m crewai version 2>/dev/null || echo "  ⚠️ crewai installed but CLI not in PATH"

# ---- Create Hermes Crew Project ----
echo ""
echo "  → Creating Solace Hermes Crew project..."
mkdir -p /root/hermes-crew/src/hermes_crew/config
cd /root/hermes-crew

# pyproject.toml
cat > pyproject.toml << PYPROJ
[project]
name = "hermes-crew"
version = "1.0.0"
description = "Solace Hermes AI Agent Crew"
requires-python = ">=3.10"
dependencies = ["crewai[tools]>=1.10"]

[build-system]
requires = ["setuptools"]
build-backend = "setuptools.backends._legacy:_Backend"
PYPROJ

# crew.py
cat > src/hermes_crew/__init__.py << INITPY
pass
INITPY

cat > src/hermes_crew/crew.py << CREWPY
from crewai import Agent, Crew, Process, Task, LLM
import os

llm = LLM(
    model="groq/llama-3.3-70b-versatile",
    api_key=os.getenv("GROQ_API_KEY", ""),
)

researcher = Agent(
    role="Research Specialist",
    goal="Find accurate, comprehensive information on any topic",
    backstory="Expert researcher with years of experience. Part of Solace Hermes AI Hub.",
    llm=llm,
    verbose=True,
)

analyst = Agent(
    role="Data Analyst",
    goal="Analyze findings and extract actionable insights and patterns",
    backstory="Skilled analyst who finds patterns and provides clear recommendations.",
    llm=llm,
    verbose=True,
)

writer = Agent(
    role="Content Writer",
    goal="Create clear, well-structured reports from research and analysis",
    backstory="Professional writer who creates concise, accurate content.",
    llm=llm,
    verbose=True,
)

def run_crew(topic: str) -> str:
    research_task = Task(
        description=f"Research thoroughly: {topic}. Find key facts and sources.",
        expected_output="Structured research summary with key findings and sources.",
        agent=researcher,
    )
    analysis_task = Task(
        description=f"Analyze research findings about: {topic}. Identify patterns.",
        expected_output="Analysis with insights, conclusions, and recommendations.",
        agent=analyst,
        context=[research_task],
    )
    report_task = Task(
        description=f"Write a report about: {topic}. Combine research and analysis.",
        expected_output="Professional report (300-500 words) in markdown.",
        agent=writer,
        context=[research_task, analysis_task],
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
    topic = sys.argv[1] if len(sys.argv) > 1 else "AI agents in 2026"
    print(run_crew(topic))
CREWPY

# main.py
cat > src/hermes_crew/main.py << MAINPY
#!/usr/bin/env python3
import sys
from hermes_crew.crew import run_crew

def main():
    topic = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "AI agents in 2026"
    print(f"\n🤖 Running Hermes Crew on: {topic}\n")
    result = run_crew(topic)
    print(f"\n📄 Result:\n{result}")

if __name__ == "__main__":
    main()
MAINPY

# .env
cat > .env << DOTENV
GROQ_API_KEY=YOUR_GROQ_KEY_HERE
OPENAI_API_KEY=YOUR_GROQ_KEY_HERE
CREWAI_TELEMETRY_OPT_OUT=true
SOLACE_URL=https://mr-connection-mwc1f9igml1.messaging.solace.cloud:9443
SOLACE_USER=solace-cloud-client
SOLACE_PASS=YOUR_SOLACE_PASS
TAILSCALE_API=YOUR_TAILSCALE_KEY
DOTENV

echo "  ✅ Hermes Crew project created"

# ---- Create launcher script ----
echo ""
echo "  → Creating launcher scripts..."

cat > /root/hermes << LAUNCHER
#!/bin/bash
source /root/crewai-env/bin/activate
cd /root/hermes-crew
source .env 2>/dev/null
export GROQ_API_KEY OPENAI_API_KEY CREWAI_TELEMETRY_OPT_OUT

case "\$1" in
    run|crew)
        shift
        python3 -m hermes_crew.main "\$@"
        ;;
    deploy)
        crewai deploy
        ;;
    version)
        crewai version
        ;;
    status)
        echo "🤖 Hermes Crew Status"
        echo "  CrewAI: \$(crewai version 2>/dev/null || echo not found)"
        echo "  Python: \$(python3 --version)"
        echo "  Project: /root/hermes-crew"
        echo "  Agents: Researcher, Analyst, Writer"
        echo "  LLM: Groq Llama 70B"
        curl -s https://hermes-cloudflare.certveis.workers.dev/health 2>/dev/null && echo "  Gateway: ✅ Online" || echo "  Gateway: ❌ Offline"
        curl -s https://hermes-cloudflare.certveis.workers.dev/solace/status 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);print(f\"  Solace: {d.get(chr(39)status chr(39),chr(39)?chr(39))}\")" 2>/dev/null || echo "  Solace: check manually"
        ;;
    *)
        echo "⚡ Solace Hermes CLI"
        echo ""
        echo "Usage:"
        echo "  hermes run [topic]    Run crew on topic"
        echo "  hermes deploy         Deploy to CrewAI Cloud"
        echo "  hermes version        Show CrewAI version"
        echo "  hermes status         Check system status"
        echo ""
        echo "Example:"
        echo "  hermes run \"benefits of event-driven AI\""
        ;;
esac
LAUNCHER
chmod +x /root/hermes

echo "  ✅ Launcher ready: hermes"
'

echo -e "${GRN}  ✅ CrewAI + Project installed${RST}"

# ---- Create Termux launcher ----
echo ""
echo -e "${GRN}🚀 Creating Termux shortcuts...${RST}"

cat > $PREFIX/bin/ubuntu << 'UBUNTUSH'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu -- "$@"
UBUNTUSH
chmod +x $PREFIX/bin/ubuntu

cat > $PREFIX/bin/hermes << 'HERMESSH'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu -- bash -c 'source /root/crewai-env/bin/activate && cd /root/hermes-crew && source .env 2>/dev/null && /root/hermes '"$*"
HERMESSH
chmod +x $PREFIX/bin/hermes

echo -e "${GRN}  ✅ Shortcuts created${RST}"

# ---- DONE ----
echo ""
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${GRN}✅ INSTALLATION COMPLETE!${RST}                    ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""
echo -e "${MAG}📂 Environment:${RST}"
echo -e "  Ubuntu rootfs via proot-distro"
echo -e "  Python venv: /root/crewai-env"
echo -e "  Project: /root/hermes-crew"
echo ""
echo -e "${MAG}🤖 Agents:${RST}"
echo -e "  Research Specialist → find data"
echo -e "  Data Analyst → analyze patterns"
echo -e "  Content Writer → create reports"
echo ""
echo -e "${MAG}⚡ Quick Commands (dari Termux):${RST}"
echo -e "  ${CYN}ubuntu${RST}                    Enter Ubuntu shell"
echo -e "  ${CYN}hermes run \"topic\"${RST}        Run crew on topic"
echo -e "  ${CYN}hermes deploy${RST}             Deploy to CrewAI Cloud"
echo -e "  ${CYN}hermes status${RST}             Check system status"
echo -e "  ${CYN}hermes version${RST}            Show CrewAI version"
echo ""
echo -e "${MAG}🔗 Inside Ubuntu:${RST}"
echo -e "  ${CYN}source /root/crewai-env/bin/activate${RST}"
echo -e "  ${CYN}cd /root/hermes-crew${RST}"
echo -e "  ${CYN}crewai deploy${RST}"
echo ""
echo -e "${YLW}💡 First run: ${CYN}hermes run \"AI agents in 2026\"${RST}"
echo ""

echo -e "${YLW}🔑 Setup API Keys:${RST}"
echo -e "  Edit: ${CYN}ubuntu${RST} then ${CYN}nano /root/hermes-crew/.env${RST}"
echo -e "  Set your GROQ_API_KEY and other credentials"
echo ""

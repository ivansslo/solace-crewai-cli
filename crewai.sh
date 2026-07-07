#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/isdocker
# ─────────────────────────────────────────────────────────────────
#  isdocker · CrewAI — Solace Hermes Multi-Agent Platform
#  Image : python:3.12-slim
#  Agents: Researcher, Analyst, Writer
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="crewai-hermes"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root/hermes-crew/src/hermes_crew"

# ── Create project files if not exist ──
if [ ! -f "$DATA_DIR/root/hermes-crew/src/hermes_crew/crew.py" ]; then
  cat > "$DATA_DIR/root/hermes-crew/src/hermes_crew/__init__.py" << 'PY1'
pass
PY1

  cat > "$DATA_DIR/root/hermes-crew/src/hermes_crew/crew.py" << 'PY2'
from crewai import Agent, Crew, Process, Task
import os

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
    t1 = Task(description="Research: " + topic, expected_output="Research summary", agent=researcher)
    t2 = Task(description="Analyze: " + topic, expected_output="Analysis with insights", agent=analyst)
    t3 = Task(description="Write report: " + topic, expected_output="Report in markdown", agent=writer)
    return str(Crew(agents=[researcher, analyst, writer], tasks=[t1, t2, t3], process=Process.sequential, verbose=True).kickoff())

if __name__ == "__main__":
    import sys
    topic = " ".join(sys.argv[1:]) or "AI agents in 2026"
    print(run_crew(topic))
PY2

  cat > "$DATA_DIR/root/hermes-crew/.env" << 'ENV1'
GROQ_API_KEY=YOUR_KEY_HERE
OPENAI_API_KEY=YOUR_KEY_HERE
CREWAI_TELEMETRY_OPT_OUT=true
ENV1
fi

udocker_check
udocker_prune
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

case "$1" in
  setup)
    echo -e "\n  ${GREEN}Installing CrewAI inside container...${RESET}\n"
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      "$CONTAINER_NAME" '
        pip install --upgrade pip setuptools wheel -q
        pip install crewai crewai-tools 2>&1 | tail -10
        python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)"
        echo ""
        echo "✅ CrewAI installed! Run: isdocker crewai run \"topic\""
      '
    ;;
  run)
    shift
    TOPIC="${*:-AI agents in 2026}"
    echo -e "\n  ${GREEN}Running crew: $TOPIC${RESET}\n"
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      -e GROQ_API_KEY="$(grep GROQ_API_KEY "$DATA_DIR/root/hermes-crew/.env" 2>/dev/null | cut -d= -f2)" \
      -e OPENAI_API_KEY="$(grep OPENAI_API_KEY "$DATA_DIR/root/hermes-crew/.env" 2>/dev/null | cut -d= -f2)" \
      -e CREWAI_TELEMETRY_OPT_OUT=true \
      "$CONTAINER_NAME" \
      "cd /root/hermes-crew && PYTHONPATH=src python3 -m hermes_crew.crew $TOPIC"
    ;;
  version)
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      "$CONTAINER_NAME" \
      'python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)" 2>/dev/null || echo "Not installed. Run: isdocker crewai setup"'
    ;;
  env)
    echo -e "\n  ${CYAN}Edit API keys:${RESET}"
    echo -e "  File: $DATA_DIR/root/hermes-crew/.env\n"
    nano "$DATA_DIR/root/hermes-crew/.env" 2>/dev/null || vi "$DATA_DIR/root/hermes-crew/.env"
    ;;
  shell)
    udocker_run --entrypoint "bash" \
      -v "$DATA_DIR/root:/root" \
      "$CONTAINER_NAME"
    ;;
  *)
    echo ""
    echo -e "  ${GREEN}🤖 CrewAI — Solace Hermes${RESET}"
    echo ""
    echo -e "  ${CYAN}isdocker crewai setup${RESET}          Install CrewAI"
    echo -e "  ${CYAN}isdocker crewai run \"topic\"${RESET}    Run AI crew"
    echo -e "  ${CYAN}isdocker crewai version${RESET}        Show version"
    echo -e "  ${CYAN}isdocker crewai env${RESET}            Edit API keys"
    echo -e "  ${CYAN}isdocker crewai shell${RESET}          Enter container"
    echo ""
    ;;
esac

exit $?

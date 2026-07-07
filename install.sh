#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Solace Hermes — Termux Installer v4 (udocker)
#  Uses isdocker framework — no compilation needed
# ============================================================

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
MAG='\033[0;35m'
RST='\033[0m'

clear
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${MAG}⚡ SOLACE HERMES — INSTALLER v4${RST}             ${CYN}║${RST}"
echo -e "${CYN}║${RST}  ${GRN}udocker + CrewAI + Tailscale${RST}                ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""

# ---- STEP 1: Termux packages ----
echo -e "${GRN}📦 [1/4] Termux packages...${RST}"
pkg update -y 2>/dev/null || true
pkg install -y git curl wget python 2>/dev/null || true
echo -e "${GRN}  ✅ Termux ready${RST}"

# ---- STEP 2: isdocker framework ----
echo ""
echo -e "${GRN}🐳 [2/4] isdocker framework...${RST}"
cd ~
if [ -d isdocker ]; then
    cd isdocker && git pull -q 2>/dev/null
    echo -e "${YLW}  ℹ️ isdocker updated${RST}"
else
    git clone https://github.com/ivansslo/isdocker.git
    cd isdocker
fi
# Install udocker
bash install_udocker.sh 2>/dev/null || true
echo -e "${GRN}  ✅ isdocker + udocker ready${RST}"

# ---- STEP 3: Add CrewAI app ----
echo ""
echo -e "${GRN}🤖 [3/4] Adding CrewAI app...${RST}"
mkdir -p ~/isdocker/apps/crewai
curl -sL "https://raw.githubusercontent.com/ivansslo/solace-crewai-cli/main/crewai.sh" \
  -o ~/isdocker/apps/crewai/crewai.sh 2>/dev/null || {
    # Fallback: copy from solace-crewai-cli if cloned
    [ -f ~/solace-crewai-cli/crewai.sh ] && cp ~/solace-crewai-cli/crewai.sh ~/isdocker/apps/crewai/
}
chmod +x ~/isdocker/apps/crewai/crewai.sh 2>/dev/null
echo -e "${GRN}  ✅ CrewAI app added${RST}"

# ---- STEP 4: Shortcuts ----
echo ""
echo -e "${GRN}🚀 [4/4] Shortcuts...${RST}"

cat > $PREFIX/bin/hermes << 'S1'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/isdocker
case "$1" in
    setup) bash apps/crewai/crewai.sh setup ;;
    run) shift; bash apps/crewai/crewai.sh run "$@" ;;
    version) bash apps/crewai/crewai.sh version ;;
    env) bash apps/crewai/crewai.sh env ;;
    shell) bash apps/crewai/crewai.sh shell ;;
    status)
        echo "🤖 Solace Hermes Status"
        bash apps/crewai/crewai.sh version
        echo "Project: ~/isdocker/data-crewai-hermes/root/hermes-crew"
        curl -s -m 5 https://hermes-cloudflare.certveis.workers.dev/health 2>/dev/null && echo "Gateway: Online" || echo "Gateway: Offline"
        ;;
    *)
        echo "⚡ Solace Hermes CLI (udocker)"
        echo ""
        echo "  hermes setup            Install CrewAI in container"
        echo "  hermes run [topic]      Run AI crew"
        echo "  hermes version          Show version"
        echo "  hermes status           System check"
        echo "  hermes env              Edit API keys"
        echo "  hermes shell            Enter container"
        echo ""
        echo "  First time: hermes setup"
        echo "  Then: hermes run \"AI agents 2026\""
        ;;
esac
S1
chmod +x $PREFIX/bin/hermes

echo -e "${GRN}  ✅ hermes shortcut created${RST}"

# ---- DONE ----
echo ""
echo -e "${CYN}╔═══════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║${RST}  ${GRN}✅ INSTALLATION COMPLETE!${RST}                    ${CYN}║${RST}"
echo -e "${CYN}╚═══════════════════════════════════════════════╝${RST}"
echo ""
echo -e "  ${CYN}hermes setup${RST}              Install CrewAI (first time)"
echo -e "  ${CYN}hermes run \"topic\"${RST}        Run AI crew"
echo -e "  ${CYN}hermes version${RST}            Show version"
echo -e "  ${CYN}hermes status${RST}             System check"
echo -e "  ${CYN}hermes env${RST}                Edit API keys"
echo -e "  ${CYN}hermes shell${RST}              Enter container"
echo ""
echo -e "${YLW}▶️ Next: ${CYN}hermes setup${RST} (install CrewAI in container)"
echo ""

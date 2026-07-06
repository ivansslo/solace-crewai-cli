# ⚡ Solace Hermes — Termux CLI

Ubuntu rootfs environment with CrewAI multi-agent platform + Tailscale VPN for Android.

## 🚀 One-Line Install

```bash
pkg install git -y && git clone https://github.com/ivansslo/solace-crewai-cli.git && cd solace-crewai-cli && bash install.sh
```

## 📦 What Gets Installed

| Component | Detail |
|---|---|
| **Ubuntu rootfs** | Full Ubuntu CLI via proot-distro |
| **Python 3** | + pip + venv inside Ubuntu |
| **CrewAI** | v1.15+ multi-agent framework |
| **Tailscale** | VPN mesh networking |
| **Hermes Crew** | 3 AI agents (Researcher, Analyst, Writer) |
| **Groq LLM** | Llama 3.3 70B (free, fast) |

## ⚡ Quick Commands

From Termux:
```bash
ubuntu                        # Enter Ubuntu shell
hermes run "topic"            # Run AI crew on topic
hermes deploy                 # Deploy to CrewAI Cloud
hermes status                 # System status check
hermes version                # CrewAI version
```

Inside Ubuntu:
```bash
source /root/crewai-env/bin/activate
cd /root/hermes-crew
python3 -m hermes_crew.main "your topic"
crewai deploy
```

## 🤖 Agents

| Agent | Role |
|---|---|
| **Research Specialist** | Find accurate data from any source |
| **Data Analyst** | Analyze patterns, draw conclusions |
| **Content Writer** | Create clear reports and summaries |

## 🔗 Connected Infrastructure

- **Gateway**: `hermes-cloudflare.certveis.workers.dev`
- **Chat**: `ca.certveis.space/chat`
- **Solace**: RoClace Cluster (Singapore)
- **AI Models**: 12 chat + 60 CF AI
- **Tools**: 1019 via ClawLink
- **Repos**: GitHub + GitLab synced

## 🔧 Troubleshooting

**No space left on device:**
```bash
apt clean && pip cache purge
termux-setup-storage  # Enable shared storage
```

**CrewAI not found:**
```bash
ubuntu
source /root/crewai-env/bin/activate
crewai version
```

**Tailscale in proot:**
Tailscale daemon can't run in proot (no kernel access). Use API instead:
```bash
curl -s https://hermes-cloudflare.certveis.workers.dev/tailscale/devices
```

## 📄 Part of [Solace Hermes Project](https://github.com/ivansslo/Solace-Hermes-Project)

© 2026 Ivan Ssl

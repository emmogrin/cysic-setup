#!/bin/bash

bold() { echo -e "\e[1m$1\e[0m"; }

clear
bold "🕊️  Saint Khen admirkhen welcomes you to Cysic Phase 3"

echo ""
echo "Choose your node type:"
echo "1. Verifier (lightweight)"
echo "2. Prover (requires high CPU/GPU)"
read -p "Enter 1 or 2: " choice

if [[ "$choice" != "1" && "$choice" != "2" ]]; then
  echo "❌ Invalid choice. Exiting."
  exit 1
fi

read -p "Enter your reward address (e.g. 0x...): " reward_address
if [[ -z "$reward_address" ]]; then
  echo "❌ No reward address provided. Exiting."
  exit 1
fi

if [[ "$choice" == "2" ]]; then
  read -p "🔗 Enter your Ethereum RPC URL (from Alchemy, etc.): " rpc_url
  if [[ -z "$rpc_url" ]]; then
    echo "❌ RPC URL required for Prover. Exiting."
    exit 1
  fi
fi

# Ensure curl/wget/bash are present
for cmd in curl wget bash; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "$cmd not found. Installing..."
    if command -v apt >/dev/null 2>&1; then
      apt update && apt install -y $cmd
    elif command -v pkg >/dev/null 2>&1; then
      pkg update && pkg install -y $cmd
    else
      echo "Package manager not found. Install $cmd manually."
      exit 1
    fi
  fi
done

# Add swap if RAM is low
create_swap() {
  bold "🧠 RAM is low — activating 2GB swap..."
  fallocate -l 2G $HOME/swapfile || dd if=/dev/zero of=$HOME/swapfile bs=1M count=2048
  chmod 600 $HOME/swapfile
  mkswap $HOME/swapfile
  swapon $HOME/swapfile
  echo "✅ Swap enabled."
}

total_mem=$(free -m | awk '/^Mem:/{print $2}')
if [ "$total_mem" -lt 1900 ]; then
  create_swap
fi

echo ""

if [ "$choice" == "1" ]; then
  bold "🌱 Setting up Phase 3 Verifier..."
  curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh
  chmod +x ~/setup_linux.sh
  bash ~/setup_linux.sh "$reward_address"
  cd ~/cysic-verifier || exit
  nohup bash start.sh > $HOME/cysic-verifier.log 2>&1 &
  log_file="cysic-verifier.log"

  # Auto-restart using crontab
  cron_entry="@reboot cd \$HOME/cysic-verifier && nohup bash start.sh > \$HOME/cysic-verifier.log 2>&1 &"
else
  bold "⚙️  Setting up Phase 3 Prover..."
  curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_prover.sh > ~/setup_prover.sh
  chmod +x ~/setup_prover.sh
  bash ~/setup_prover.sh "$reward_address" "$rpc_url"
  cd ~/cysic-prover || { echo "❌ Prover directory not found. Setup failed."; exit 1; }
  nohup bash start.sh > $HOME/cysic-prover.log 2>&1 &
  log_file="cysic-prover.log"

  # Auto-restart using crontab
  cron_entry="@reboot cd \$HOME/cysic-prover && nohup bash start.sh > \$HOME/cysic-prover.log 2>&1 &"
fi

# Install crontab if missing and add entry
if ! command -v crontab >/dev/null 2>&1; then
  echo "Installing cronie or cron..."
  if command -v apt >/dev/null 2>&1; then
    apt install -y cron
    service cron start
  elif command -v pkg >/dev/null 2>&1; then
    pkg install -y cronie
    crond
  fi
fi

(crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

echo ""
bold "✅ Node is running in the background."
echo "📄 To view logs anytime: tail -f \$HOME/$log_file"
echo ""
bold "Saint Khen blesses your late entry 🙌"
echo "Follow @admirkhen on X: https://x.com/admirkhen"

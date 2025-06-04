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
  nohup bash start.sh > $HOME/cysic.log 2>&1 &
else
  bold "⚙️  Setting up Phase 3 Prover..."
  curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_prover.sh > ~/setup_prover.sh
  chmod +x ~/setup_prover.sh
  bash ~/setup_prover.sh "$reward_address"
  
  # Write RPC URL to config
  cd ~/cysic-prover || exit
  if [[ -f config.toml ]]; then
    sed -i "s|rpc_url = .*|rpc_url = \"$rpc_url\"|" config.toml
  else
    echo "❌ config.toml not found. Exiting."
    exit 1
  fi

  nohup bash start.sh > $HOME/cysic.log 2>&1 &
fi

echo ""
bold "✅ Node is running in the background."
echo "📄 To view logs anytime: tail -f \$HOME/cysic.log"
echo ""
bold "Saint Khen blesses your late entry 🙌"
echo "Follow @admirkhen on X: https://x.com/admirkhen"

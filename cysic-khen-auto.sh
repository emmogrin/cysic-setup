#!/bin/bash

# Bold text function
bold() { echo -e "\e[1m$1\e[0m"; }

clear
bold "🕊️  Saint Khen admirkhen welcomes you."

echo ""
echo "Choose your node type:"
echo "1. Verifier (lightweight)"
echo "2. Prover (requires high CPU/GPU)"
read -p "Enter 1 or 2: " choice

if [[ "$choice" != "1" && "$choice" != "2" ]]; then
  echo "Invalid choice. Exiting."
  exit 1
fi

read -p "Enter your reward address (e.g. 0x...): " reward_address
if [[ -z "$reward_address" ]]; then
  echo "No reward address provided. Exiting."
  exit 1
fi

# Install essential packages if missing
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

# Create swap if RAM is less than 2GB
create_swap() {
  bold "🧠 RAM is low — activating 2GB swap for smoother performance..."
  fallocate -l 2G $HOME/swapfile || dd if=/dev/zero of=$HOME/swapfile bs=1M count=2048
  chmod 600 $HOME/swapfile
  mkswap $HOME/swapfile
  swapon $HOME/swapfile
  echo "✅ Swap enabled."
}

# Detect RAM
total_mem=$(free -m | awk '/^Mem:/{print $2}')
if [ "$total_mem" -lt 1900 ]; then
  create_swap
fi

echo ""
if [ "$choice" == "1" ]; then
  bold "🌱 Setting up the Verifier..."
  wget https://github.com/Cysic-VDF/phase2-genesis-verifier/releases/latest/download/setup.sh -O setup.sh
  chmod +x setup.sh
  bash setup.sh "$reward_address"
  cd phase2-genesis-verifier || exit
  nohup bash start.sh > ../cysic.log 2>&1 &
else
  bold "🧠 Setting up the Prover..."
  wget https://github.com/Cysic-VDF/phase2-genesis-prover/releases/latest/download/setup.sh -O setup.sh
  chmod +x setup.sh
  bash setup.sh "$reward_address"
  cd phase2-genesis-prover || exit
  nohup bash start.sh > ../cysic.log 2>&1 &
fi

echo ""
bold "✅ Node is running in the background."
echo "📄 Check logs with: tail -f cysic.log"
echo ""
bold "Saint Khen blesses your late entry 🙌"
echo "Follow @admirkhen on X: https://x.com/admirkhen"

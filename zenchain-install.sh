#!/bin/bash

# === KONFIGURASI ===
NODE_NAME=${1:-"zen-node"}
WALLET_NAME="walletpubg"
CHAIN_ID="zenchain-testnet-1"
PORT=26657

echo -e "\e[1m\e[32m🚀 Mulai install ZenChain Node: $NODE_NAME\e[0m"

# === UPDATE & INSTALL DEPENDENSI ===
sudo apt update && sudo apt upgrade -y
sudo apt install curl git build-essential make gcc jq -y

# === INSTALL GO (opsional, kalau belum ada) ===
cd $HOME
wget https://golang.org/dl/go1.21.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc

# === CLONE & BUILD BINARY ===
git clone https://github.com/zenchain/zenchain
cd zenchain
make install

# === INISIALISASI NODE ===
zenchaind init "$NODE_NAME" --chain-id=$CHAIN_ID

# === AMBIL GENESIS & ADDRBOOK ===
wget -O $HOME/.zenchain/config/genesis.json https://raw.githubusercontent.com/zenchain/testnet/master/genesis.json
wget -O $HOME/.zenchain/config/addrbook.json https://raw.githubusercontent.com/zenchain/testnet/master/addrbook.json

# === SET PEER DAN SEED ===
SEEDS="seed1@ip:port"
PEERS="peer1@ip:port"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $HOME/.zenchain/config/config.toml
sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.zenchain/config/config.toml

# === BUAT WALLET ===
zenchaind keys add $WALLET_NAME

# === RESET DAN START NODE ===
zenchaind tendermint unsafe-reset-all

# === BUAT SERVICE SYSTEMD ===
sudo tee /etc/systemd/system/zenchaind.service > /dev/null <<EOF
[Unit]
Description=ZenChain Node
After=network-online.target

[Service]
User=$USER
ExecStart=$(which zenchaind) start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# === ENABLE DAN MULAI SERVICE ===
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable zenchaind
sudo systemctl start zenchaind

echo -e "\e[1m\e[32m✅ ZenChain node berhasil diinstall!\e[0m"
echo -e "🔁 Cek status: \e[33mjournalctl -u zenchaind -f -o cat\e[0m"
echo -e "🔎 Cek sync: \e[33mcurl -s localhost:$PORT/status | jq .result.sync_info\e[0m"

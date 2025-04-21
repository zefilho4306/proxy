#!/data/data/com.termux/files/usr/bin/bash
set -e

# Atualizar Termux
pkg update && pkg upgrade -y

# Instalar dependências
pkg install git curl wget nano tsu -y
pkg install clang make -y
pkg install openssl -y

# Clonar e compilar
git clone https://github.com/z3APA3A/3proxy.git
cd 3proxy
make -f Makefile.Linux

# Criar config
mkdir -p ~/3proxy/conf
cat > ~/3proxy/conf/3proxy.cfg <<EOF
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p3128 -i0.0.0.0 -e0.0.0.0
flush
EOF

# Rodar em segundo plano com nohup
mkdir -p ~/3proxy/logs
nohup ~/3proxy/src/3proxy ~/3proxy/conf/3proxy.cfg > ~/3proxy/logs/3proxy.log 2>&1 &

echo "[✓] 3proxy rodando em segundo plano na porta 3128."
echo "[→] Log em: ~/3proxy/logs/3proxy.log"
echo "[→] Para ver: tail -f ~/3proxy/logs/3proxy.log"

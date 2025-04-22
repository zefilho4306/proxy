#!/data/data/com.termux/files/usr/bin/bash

echo "========================================"
echo "Instalador do 3proxy para Termux"
echo "========================================"

# Verificar ambiente
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ Este script deve ser executado no Termux!"
    exit 1
fi

# [1] Atualizar Termux
echo "[1/8] Atualizando Termux..."
pkg update -y && pkg upgrade -y

# [2] Instalar dependências
echo "[2/8] Instalando dependências..."
pkg install -y git make clang net-tools

# [3] Clonar e compilar 3proxy
echo "[3/8] Clonando e compilando 3proxy..."
cd ~
rm -rf 3proxy
git clone https://github.com/3proxy/3proxy.git
cd 3proxy
make -f Makefile.Linux

# [4] Instalar binário
echo "[4/8] Instalando binário..."
mkdir -p $PREFIX/bin
cp bin/3proxy $PREFIX/bin/
chmod +x $PREFIX/bin/3proxy

# [5] Criar configuração funcional com DNS fixo
echo "[5/8] Criando configuração..."
mkdir -p $PREFIX/etc/3proxy
cat > $PREFIX/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
nserver 8.8.8.8
nserver 1.1.1.1
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p8080 -i0.0.0.0 -e0.0.0.0
flush
EOF

# [6] Fixar DNS do sistema também (fallback)
echo "[6/8] Setando DNS no sistema..."
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > $PREFIX/etc/resolv.conf
chmod 444 $PREFIX/etc/resolv.conf

# [7] Limpar log antigo
rm -f ~/3proxy.log

# [8] Iniciar proxy com nohup e env
echo "[8/8] Iniciando o 3proxy..."
nohup env LD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/3proxy $PREFIX/etc/3proxy/3proxy.cfg > ~/3proxy.log 2>&1 &

sleep 1
if pgrep -x "3proxy" > /dev/null; then
    IP=$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print $2}' | head -n1)
    echo ""
    echo "========================================"
    echo "✅ 3proxy instalado e rodando!"
    echo "========================================"
    echo "IP local: $IP"
    echo "HTTP Proxy: $IP:8080"
    echo ""
    echo "Log: ~/3proxy.log"
    echo "Parar: pkill -x 3proxy"
    echo "========================================"
else
    echo "❌ ERRO: 3proxy não iniciou corretamente!"
fi

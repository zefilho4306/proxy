#!/data/data/com.termux/files/usr/bin/bash

echo "========================================"
echo "Instalador do 3proxy para Termux"
echo "========================================"

# Verificar se está no Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ Este script deve ser executado no Termux!"
    exit 1
fi

# 1. Atualizar repositórios
echo "[1/7] Atualizando Termux..."
pkg update -y && pkg upgrade -y

# 2. Instalar dependências
echo "[2/7] Instalando dependências..."
pkg install -y git make clang net-tools

# 3. Clonar e compilar 3proxy
echo "[3/7] Clonando e compilando 3proxy..."
cd ~
rm -rf 3proxy
git clone https://github.com/3proxy/3proxy.git
cd 3proxy
make -f Makefile.Linux

# 4. Instalar binário
echo "[4/7] Instalando binário..."
mkdir -p $PREFIX/bin
cp bin/3proxy $PREFIX/bin/
chmod +x $PREFIX/bin/3proxy

# 5. Criar configuração
echo "[5/7] Criando configuração..."
mkdir -p $PREFIX/etc/3proxy
cat > $PREFIX/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p3128 -i0.0.0.0 -e0.0.0.0
flush
EOF

# 6. Limpar logs antigos
rm -f ~/3proxy.log

# 7. Iniciar 3proxy com LD_LIBRARY_PATH
echo "[7/7] Iniciando o 3proxy..."
nohup env LD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/3proxy $PREFIX/etc/3proxy/3proxy.cfg > ~/3proxy.log 2>&1 &

sleep 1
if pgrep -x "3proxy" > /dev/null; then
    IP=$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print $2}' | head -n1)
    echo ""
    echo "========================================"
    echo "✅ 3proxy instalado e rodando!"
    echo "========================================"
    echo "IP local: $IP"
    echo "HTTP Proxy: $IP:3128"
    echo ""
    echo "Log: ~/3proxy.log"
    echo "Parar: pkill -x 3proxy"
    echo "========================================"
else
    echo "❌ ERRO: 3proxy não iniciou corretamente!"
fi

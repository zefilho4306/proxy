#!/data/data/com.termux/files/usr/bin/bash

echo "========================================"
echo "Instalador do 3proxy para Termux"
echo "========================================"

# Verificar se está rodando no Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "Este script deve ser executado no Termux!"
    exit 1
fi

echo "[1/7] Atualizando repositórios do Termux..."
pkg update -y && pkg upgrade -y

echo "[2/7] Instalando dependências..."
pkg install -y git make clang net-tools

echo "[3/7] Clonando repositório do 3proxy..."
cd ~
rm -rf 3proxy
git clone https://github.com/3proxy/3proxy.git
cd 3proxy

echo "[4/7] Compilando o 3proxy..."
make -f Makefile.Linux || { echo "Erro ao compilar."; exit 1; }

echo "[5/7] Instalando binários..."
mkdir -p $PREFIX/bin
cp bin/3proxy $PREFIX/bin/
cp bin/mycrypt $PREFIX/bin/
cp bin/pop3p $PREFIX/bin/
chmod +x $PREFIX/bin/3proxy $PREFIX/bin/mycrypt $PREFIX/bin/pop3p

echo "[6/7] Configurando arquivos..."
mkdir -p $PREFIX/etc/3proxy

cat > $PREFIX/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p3128 -i0.0.0.0 -e0.0.0.0
flush
EOF

cat > $PREFIX/bin/start3proxy <<EOF
#!/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    echo "3proxy já está em execução!"
else
    nohup env LD_LIBRARY_PATH=\$PREFIX/lib \$PREFIX/bin/3proxy \$PREFIX/etc/3proxy/3proxy.cfg > \$HOME/3proxy.log 2>&1 &
    echo "3proxy iniciado na porta 3128"
    echo "IP local: \$(ifconfig | grep -E 'inet (192|10|172)' | awk '{print \$2}')"
fi
EOF

cat > $PREFIX/bin/stop3proxy <<EOF
#!/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    pkill -x 3proxy
    echo "3proxy parado com sucesso!"
else
    echo "3proxy não está em execução!"
fi
EOF

cat > $PREFIX/bin/status3proxy <<EOF
#!/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    echo "3proxy está em execução!"
    echo "IP local: \$(ifconfig | grep -E 'inet (192|10|172)' | awk '{print \$2}')"
    echo "Conexões ativas: \$(netstat -an | grep 3128 | grep ESTABLISHED | wc -l)"
else
    echo "3proxy não está rodando."
fi
EOF

chmod +x $PREFIX/bin/start3proxy $PREFIX/bin/stop3proxy $PREFIX/bin/status3proxy

echo "[7/7] Iniciando o 3proxy..."
nohup env LD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/3proxy $PREFIX/etc/3proxy/3proxy.cfg > ~/3proxy.log 2>&1 &
sleep 1

if pgrep -x "3proxy" > /dev/null; then
    IP=$(ifconfig | grep -E 'inet (192|10|172)' | awk '{print $2}' | head -n 1)
    echo "========================================"
    echo "✅ 3proxy rodando com sucesso!"
    echo "IP local: $IP"
    echo "Acesse via: http://$IP:3128"
    echo "start3proxy | stop3proxy | status3proxy"
    echo "Log: ~/3proxy.log"
    echo "========================================"
else
    echo "❌ ERRO: 3proxy não iniciou corretamente."
fi

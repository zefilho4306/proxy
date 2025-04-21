#!/data/data/com.termux/files/usr/bin/bash

# Script de instalação do 3proxy no Termux (Android)
# Compatível com Android 10+ e execuções ARM64

echo "========================================"
echo "Instalador do 3proxy para Termux"
echo "========================================"

# Checagem básica
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ Este script deve ser executado no Termux!"
    exit 1
fi

# 1. Atualizar pacotes
echo "[1/7] Atualizando Termux..."
pkg update -y && pkg upgrade -y

# 2. Instalar dependências
echo "[2/7] Instalando dependências..."
pkg install -y git make clang net-tools

# 3. Clonar e compilar 3proxy
echo "[3/7] Baixando e compilando 3proxy..."
cd ~
rm -rf 3proxy
git clone https://github.com/3proxy/3proxy.git
cd 3proxy
make -f Makefile.Linux

# 4. Instalar binários
echo "[4/7] Instalando binários..."
mkdir -p $PREFIX/bin
cp bin/3proxy $PREFIX/bin/
chmod +x $PREFIX/bin/3proxy

# 5. Criar configuração
echo "[5/7] Configurando arquivos..."
mkdir -p $PREFIX/etc/3proxy
cat > $PREFIX/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p3128 -i0.0.0.0 -e0.0.0.0
flush
EOF

# 6. Criar scripts de controle
echo "[6/7] Criando scripts..."

cat > $PREFIX/bin/start3proxy <<EOF
#!/data/data/com.termux/files/usr/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    echo "⚠️  3proxy já está em execução."
else
    env LD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/3proxy $PREFIX/etc/3proxy/3proxy.cfg &
    echo "✅ 3proxy iniciado na porta 3128."
fi
EOF

cat > $PREFIX/bin/stop3proxy <<EOF
#!/data/data/com.termux/files/usr/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    pkill -x 3proxy
    echo "🛑 3proxy parado com sucesso."
else
    echo "ℹ️  3proxy não está em execução."
fi
EOF

cat > $PREFIX/bin/status3proxy <<EOF
#!/data/data/com.termux/files/usr/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    echo "✅ 3proxy está rodando."
    IP=\$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print \$2}')
    echo "IP local: \$IP"
    echo "Porta: 3128"
else
    echo "❌ 3proxy não está em execução."
fi
EOF

chmod +x $PREFIX/bin/start3proxy
chmod +x $PREFIX/bin/stop3proxy
chmod +x $PREFIX/bin/status3proxy

# 7. Iniciar proxy
echo "[7/7] Iniciando o 3proxy..."
$PREFIX/bin/start3proxy

# Verificação
sleep 1
if pgrep -x "3proxy" > /dev/null; then
    IP=$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print $2}')
    echo ""
    echo "========================================"
    echo "✅ 3proxy instalado com sucesso!"
    echo "========================================"
    echo "IP local: $IP"
    echo "HTTP Proxy: $IP:3128"
    echo ""
    echo "Comandos:"
    echo "  start3proxy  → Iniciar"
    echo "  stop3proxy   → Parar"
    echo "  status3proxy → Ver status"
    echo "========================================"
else
    echo "❌ ERRO: 3proxy não iniciou corretamente."
fi

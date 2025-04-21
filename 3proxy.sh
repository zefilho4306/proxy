#!/bin/bash

# Script de instalação do 3proxy no Termux sem root
# Customizado com configuração personalizada

echo "========================================"
echo "Instalador do 3proxy para Termux (Android)"
echo "========================================"

# Verificar se está no Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "Este script deve ser executado no Termux!"
    exit 1
fi

# Passo 1: Atualizar pacotes
echo "[1/7] Atualizando repositórios..."
pkg update -y && pkg upgrade -y

# Passo 2: Instalar dependências
echo "[2/7] Instalando dependências..."
pkg install -y git make clang

# Passo 3: Clonar 3proxy
echo "[3/7] Baixando 3proxy..."
cd ~
rm -rf 3proxy
git clone https://github.com/3proxy/3proxy.git
cd 3proxy

# Passo 4: Compilar
echo "[4/7] Compilando 3proxy..."
make -f Makefile.Linux
if [ $? -ne 0 ]; then
    echo "[ERRO] Falha na compilação."
    exit 1
fi

# Passo 5: Instalar binários
echo "[5/7] Instalando binários..."
mkdir -p $PREFIX/bin
cp bin/3proxy $PREFIX/bin/
chmod +x $PREFIX/bin/3proxy

# Passo 6: Criar config e logs
echo "[6/7] Criando configuração personalizada..."
mkdir -p $PREFIX/etc/3proxy
mkdir -p $HOME/storage/shared/3proxy_logs

# Pedir permissão de armazenamento se necessário
if [ ! -d "$HOME/storage/shared" ]; then
    echo "Solicitando permissão de armazenamento..."
    termux-setup-storage
    sleep 5
fi

cat > $PREFIX/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p3128 -i0.0.0.0 -e0.0.0.0
flush
EOF

# Script de iniciar
cat > $PREFIX/bin/start3proxy <<EOF
#!/bin/bash
mkdir -p \$HOME/storage/shared/3proxy_logs
if pgrep -x "3proxy" > /dev/null; then
    echo "3proxy já está rodando."
else
    $PREFIX/bin/3proxy $PREFIX/etc/3proxy/3proxy.cfg &
    echo "3proxy iniciado em 0.0.0.0:3128"
fi
EOF

# Script de parar
cat > $PREFIX/bin/stop3proxy <<EOF
#!/bin/bash
if pgrep -x "3proxy" > /dev/null; then
    pkill -x 3proxy
    echo "3proxy parado."
else
    echo "3proxy não está rodando."
fi
EOF

chmod +x $PREFIX/bin/start3proxy
chmod +x $PREFIX/bin/stop3proxy

# Passo 7: Iniciar pela primeira vez
echo "[7/7] Iniciando 3proxy..."
$PREFIX/bin/start3proxy

# Verificação final
if pgrep -x "3proxy" > /dev/null; then
    echo ""
    echo "========================================"
    echo "✅ 3proxy instalado e rodando com sucesso!"
    echo "========================================"
    echo ""
    echo "Gerenciamento:"
    echo "  • Iniciar:  start3proxy"
    echo "  • Parar:    stop3proxy"
    echo ""
    echo "Proxy ativo em:"
    echo "  • HTTP: 0.0.0.0:3128"
    echo ""
    echo "Config: $PREFIX/etc/3proxy/3proxy.cfg"
    echo "Logs:   \$HOME/storage/shared/3proxy_logs/3proxy.log"
    echo "========================================"
else
    echo "[ERRO] 3proxy não foi iniciado!"
fi

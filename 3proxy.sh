#!/bin/bash

# Script de instalação do 3proxy no Termux sem root
# Configuração personalizada para acesso externo

echo "========================================"
echo "Instalador do 3proxy para Termux"
echo "========================================"

# Verificar se está rodando no Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "Este script deve ser executado no Termux!"
    exit 1
fi

# Passo 1: Atualizar repositórios do Termux
echo "[1/7] Atualizando repositórios do Termux..."
pkg update -y && pkg upgrade -y

# Passo 2: Instalar dependências necessárias
echo "[2/7] Instalando dependências..."
pkg install -y git make clang

# Passo 3: Baixar o código-fonte do 3proxy
echo "[3/7] Baixando o código-fonte do 3proxy..."
cd ~
if [ -d "3proxy" ]; then
    echo "Diretório 3proxy já existe. Removendo e clonando novamente..."
    rm -rf 3proxy
fi
git clone https://github.com/3proxy/3proxy.git
cd 3proxy

# Passo 4: Compilar o 3proxy
echo "[4/7] Compilando o 3proxy..."
make -f Makefile.Linux
if [ $? -ne 0 ]; then
    echo "Erro na compilação! Abortando..."
    exit 1
fi

# Passo 5: Instalar manualmente os binários
echo "[5/7] Instalando binários..."
mkdir -p $PREFIX/bin
cp bin/3proxy $PREFIX/bin/
cp bin/mycrypt $PREFIX/bin/
cp bin/dighosts $PREFIX/bin/
cp bin/pop3p $PREFIX/bin/
chmod +x $PREFIX/bin/3proxy
chmod +x $PREFIX/bin/mycrypt
chmod +x $PREFIX/bin/dighosts
chmod +x $PREFIX/bin/pop3p

# Passo 6: Criar diretórios de configuração
echo "[6/7] Configurando diretórios e arquivos de configuração..."
mkdir -p $PREFIX/etc/3proxy

# Criar arquivo de configuração com as configurações especificadas
echo "nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -n -a -p3128 -i0.0.0.0 -e0.0.0.0
flush" > $PREFIX/etc/3proxy/3proxy.cfg

# Criar script de inicialização
echo "#!/bin/bash
# Script para iniciar o 3proxy
if pgrep -x \"3proxy\" > /dev/null
then
    echo \"3proxy já está em execução!\"
else
    $PREFIX/bin/3proxy $PREFIX/etc/3proxy/3proxy.cfg &
    echo \"3proxy iniciado na porta HTTP 3128, acessível de qualquer dispositivo da rede\"
    echo \"IP local: \$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print \$2}')\"
fi" > $PREFIX/bin/start3proxy

# Criar script para parar o proxy
echo "#!/bin/bash
# Script para parar o 3proxy
if pgrep -x \"3proxy\" > /dev/null
then
    pkill -x 3proxy
    echo \"3proxy parado com sucesso!\"
else
    echo \"3proxy não está em execução!\"
fi" > $PREFIX/bin/stop3proxy

# Adicionar script para mostrar o status
echo "#!/bin/bash
# Script para verificar o status do 3proxy
if pgrep -x \"3proxy\" > /dev/null
then
    echo \"3proxy está em execução!\"
    echo \"IP local: \$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print \$2}')\"
    echo \"Porta HTTP: 3128\"
    echo \"Conexões ativas: \$(netstat -an | grep 3128 | grep ESTABLISHED | wc -l)\"
else
    echo \"3proxy não está em execução!\"
fi" > $PREFIX/bin/status3proxy

# Tornar scripts executáveis
chmod +x $PREFIX/bin/start3proxy
chmod +x $PREFIX/bin/stop3proxy
chmod +x $PREFIX/bin/status3proxy

# Instalar ifconfig se não estiver presente
if ! command -v ifconfig &> /dev/null; then
    pkg install -y net-tools
fi

# Passo 7: Iniciar o 3proxy pela primeira vez
echo "[7/7] Iniciando o 3proxy..."
$PREFIX/bin/start3proxy

# Verificar se está rodando
if pgrep -x "3proxy" > /dev/null; then
    LOCALIP=$(ifconfig 2>/dev/null | grep -E 'inet (192|10|172)' | awk '{print $2}')
    echo ""
    echo "========================================"
    echo "3proxy instalado e iniciado com sucesso!"
    echo "========================================"
    echo ""
    echo "Para gerenciar o serviço:"
    echo "  - Iniciar:    start3proxy"
    echo "  - Parar:      stop3proxy"
    echo "  - Verificar:  status3proxy"
    echo ""
    echo "Configurações do proxy:"
    echo "  - Endereço IP local: $LOCALIP"
    echo "  - Proxy HTTP: $LOCALIP:3128"
    echo ""
    echo "Outros dispositivos na rede podem usar este proxy:"
    echo "  - Configure o proxy HTTP: $LOCALIP:3128"
    echo ""
    echo "O arquivo de configuração está em:"
    echo "  $PREFIX/etc/3proxy/3proxy.cfg"
    echo "========================================"
    echo "IMPORTANTE: Mantenha o Termux aberto enquanto estiver usando o proxy!"
    echo "========================================"
else
    echo "ERRO: 3proxy não foi iniciado corretamente!"
fi

#!/bin/bash

# Cores para melhor visualização
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Instalador Interativo do n8n ===${NC}"
echo -e "${YELLOW}Este script instala a versão mais recente do n8n do repositório oficial${NC}"
echo -e "${YELLOW}Por favor, responda as perguntas abaixo para personalizar sua instalação.${NC}"
echo ""

# Verifica se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Por favor execute como root (use sudo)${NC}"
  exit 1
fi

# Verificar dependências
command -v curl >/dev/null 2>&1 || { echo -e "${RED}curl é necessário, por favor instale-o.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { 
  echo -e "${YELLOW}jq não está instalado. Instalando...${NC}"
  apt-get update && apt-get install -y jq || { echo -e "${RED}Falha ao instalar jq.${NC}"; exit 1; }
}

# Obter a versão mais recente do n8n do GitHub
echo -e "${YELLOW}Verificando a versão mais recente do n8n...${NC}"
LATEST_VERSION=$(curl -s https://api.github.com/repos/n8n-io/n8n/releases/latest | jq -r '.tag_name' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ]; then
  echo -e "${RED}Não foi possível obter a versão mais recente do n8n. Usando a versão padrão.${NC}"
  LATEST_VERSION="latest"
else
  echo -e "${GREEN}Versão mais recente do n8n: ${LATEST_VERSION}${NC}"
fi

# Solicitar informações do usuário
echo -e "${BLUE}== Configuração do n8n ==${NC}"

# Solicitar local de instalação
read -p "$(echo -e ${GREEN}\"Digite o caminho para instalação [padrão: /opt/n8n]: \"${NC})" INSTALL_PATH
INSTALL_PATH=${INSTALL_PATH:-/opt/n8n}

# Solicitar porta para o n8n
read -p "$(echo -e ${GREEN}\"Digite a porta para o n8n [padrão: 5678]: \"${NC})" N8N_PORT
N8N_PORT=${N8N_PORT:-5678}

# Solicitar informações de login para o n8n
read -p "$(echo -e ${GREEN}\"Digite o email do administrador do n8n [padrão: admin@admin.com]: \"${NC})" N8N_EMAIL
N8N_EMAIL=${N8N_EMAIL:-admin@admin.com}

read -p "$(echo -e ${GREEN}\"Digite a senha do administrador do n8n [padrão: gerada automaticamente]: \"${NC})" N8N_PASSWORD
if [ -z "$N8N_PASSWORD" ]; then
  N8N_PASSWORD=$(openssl rand -base64 12)
  echo -e "${YELLOW}Senha gerada automaticamente: ${N8N_PASSWORD}${NC}"
fi

# Solicitar configuração de banco de dados
echo -e "${BLUE}== Configuração do Banco de Dados ==${NC}"
echo -e "${YELLOW}Detectado suporte a MySQL na hospedagem${NC}"
echo -e "${YELLOW}Recomendamos usar MySQL para melhor desempenho em produção${NC}"

PS3="Selecione o tipo de banco de dados: "
options=("MySQL (recomendado)" "SQLite" "PostgreSQL")
select DB_TYPE in "${options[@]}"; do
  case $DB_TYPE in
    "MySQL (recomendado)")
      DB_TYPE="mysql"
      echo -e "${BLUE}Configuração do MySQL:${NC}"
      read -p "$(echo -e ${GREEN}\"Host do MySQL [padrão: localhost]: \"${NC})" DB_HOST
      DB_HOST=${DB_HOST:-localhost}
      read -p "$(echo -e ${GREEN}\"Porta do MySQL [padrão: 3306]: \"${NC})" DB_PORT
      DB_PORT=${DB_PORT:-3306}
      read -p "$(echo -e ${GREEN}\"Usuário do MySQL: \"${NC})" DB_USER
      while [ -z "$DB_USER" ]; do
        echo -e "${RED}Usuário do MySQL não pode estar vazio${NC}"
        read -p "$(echo -e ${GREEN}\"Usuário do MySQL: \"${NC})" DB_USER
      done
      read -p "$(echo -e ${GREEN}\"Senha do MySQL: \"${NC})" DB_PASS
      while [ -z "$DB_PASS" ]; do
        echo -e "${RED}Senha do MySQL não pode estar vazia${NC}"
        read -p "$(echo -e ${GREEN}\"Senha do MySQL: \"${NC})" DB_PASS
      done
      read -p "$(echo -e ${GREEN}\"Nome do banco de dados MySQL [padrão: n8n]: \"${NC})" DB_NAME
      DB_NAME=${DB_NAME:-n8n}
      
      # Verificar se o MySQL está instalado
      if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}MySQL client não encontrado. Instalando...${NC}"
        apt-get update && apt-get install -y mysql-client || {
          echo -e "${RED}Não foi possível instalar o cliente MySQL. Continuando mesmo assim...${NC}"
        }
      fi
      
      # Tentar conectar ao banco de dados MySQL
      echo -e "${YELLOW}Verificando conexão com o banco de dados MySQL...${NC}"
      if command -v mysql &> /dev/null; then
        if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" &> /dev/null; then
          echo -e "${GREEN}Conexão com o MySQL estabelecida com sucesso!${NC}"
          
          # Verificar se o banco de dados existe, se não, tentar criá-lo
          if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" &> /dev/null; then
            echo -e "${YELLOW}Banco de dados '$DB_NAME' não existe. Tentando criar...${NC}"
            if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" &> /dev/null; then
              echo -e "${GREEN}Banco de dados '$DB_NAME' criado com sucesso!${NC}"
            else
              echo -e "${RED}Não foi possível criar o banco de dados. Verifique se o usuário tem permissão.${NC}"
              echo -e "${YELLOW}Você precisará criar o banco de dados manualmente antes de continuar.${NC}"
              read -p "$(echo -e ${YELLOW}\"Deseja continuar mesmo assim? (s/n): \"${NC})" CONTINUE_ANYWAY
              if [[ $CONTINUE_ANYWAY != "s" && $CONTINUE_ANYWAY != "S" ]]; then
                echo -e "${RED}Instalação cancelada pelo usuário.${NC}"
                exit 1
              fi
            fi
          else
            echo -e "${GREEN}Banco de dados '$DB_NAME' já existe e está acessível.${NC}"
          fi
        else
          echo -e "${RED}Não foi possível conectar ao MySQL. Verifique as credenciais.${NC}"
          read -p "$(echo -e ${YELLOW}\"Deseja continuar mesmo assim? (s/n): \"${NC})" CONTINUE_ANYWAY
          if [[ $CONTINUE_ANYWAY != "s" && $CONTINUE_ANYWAY != "S" ]]; then
            echo -e "${RED}Instalação cancelada pelo usuário.${NC}"
            exit 1
          fi
        fi
      else
        echo -e "${YELLOW}Cliente MySQL não disponível. Não é possível verificar conexão.${NC}"
        read -p "$(echo -e ${YELLOW}\"Deseja continuar mesmo assim? (s/n): \"${NC})" CONTINUE_ANYWAY
        if [[ $CONTINUE_ANYWAY != "s" && $CONTINUE_ANYWAY != "S" ]]; then
          echo -e "${RED}Instalação cancelada pelo usuário.${NC}"
          exit 1
        fi
      fi
      
      break
      ;;
    "SQLite")
      DB_TYPE="sqlite"
      echo -e "${YELLOW}Usando SQLite. Adequado apenas para testes ou uso leve.${NC}"
      break
      ;;
    "PostgreSQL")
      DB_TYPE="postgres"
      read -p "$(echo -e ${GREEN}\"Host do PostgreSQL [padrão: localhost]: \"${NC})" DB_HOST
      DB_HOST=${DB_HOST:-localhost}
      read -p "$(echo -e ${GREEN}\"Porta do PostgreSQL [padrão: 5432]: \"${NC})" DB_PORT
      DB_PORT=${DB_PORT:-5432}
      read -p "$(echo -e ${GREEN}\"Usuário do PostgreSQL: \"${NC})" DB_USER
      read -p "$(echo -e ${GREEN}\"Senha do PostgreSQL: \"${NC})" DB_PASS
      read -p "$(echo -e ${GREEN}\"Nome do banco de dados PostgreSQL [padrão: n8n]: \"${NC})" DB_NAME
      DB_NAME=${DB_NAME:-n8n}
      break
      ;;
    *) 
      echo -e "${RED}Opção inválida. Selecionando SQLite como padrão.${NC}"
      DB_TYPE="sqlite"
      break
      ;;
  esac
done

# Confirmar configurações
echo -e "${BLUE}== Resumo da Configuração ==${NC}"
echo -e "${GREEN}Versão do n8n:${NC} $LATEST_VERSION"
echo -e "${GREEN}Local de instalação:${NC} $INSTALL_PATH"
echo -e "${GREEN}Porta do n8n:${NC} $N8N_PORT"
echo -e "${GREEN}Email do administrador:${NC} $N8N_EMAIL"
echo -e "${GREEN}Banco de dados:${NC} $DB_TYPE"
if [ "$DB_TYPE" != "sqlite" ]; then
  echo -e "${GREEN}Host do banco:${NC} $DB_HOST:$DB_PORT"
  echo -e "${GREEN}Banco de dados:${NC} $DB_NAME"
fi

echo ""
read -p "$(echo -e ${YELLOW}\"Deseja continuar com a instalação? (s/n): \"${NC})" CONFIRM
if [[ $CONFIRM != "s" && $CONFIRM != "S" ]]; then
  echo -e "${RED}Instalação cancelada pelo usuário.${NC}"
  exit 1
fi

echo -e "${YELLOW}Iniciando instalação do n8n...${NC}"

# Instalar dependências
echo -e "${GREEN}Instalando dependências...${NC}"
apt-get update
apt-get install -y curl wget gnupg2 ca-certificates lsb-release

# Instalar Node.js (versão LTS)
echo -e "${GREEN}Instalando Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

# Verificar versão do Node.js
NODE_VERSION=$(node -v)
echo -e "${GREEN}Versão do Node.js: $NODE_VERSION${NC}"

# Criar diretório para o n8n
echo -e "${GREEN}Criando diretório para o n8n...${NC}"
mkdir -p $INSTALL_PATH

# Criar usuário para executar o n8n
N8N_USER="n8n"
echo -e "${GREEN}Criando usuário para o n8n...${NC}"
id -u $N8N_USER &>/dev/null || useradd -r -d $INSTALL_PATH -s /bin/bash $N8N_USER

# Instalar n8n globalmente
echo -e "${GREEN}Instalando n8n versão $LATEST_VERSION...${NC}"
if [ "$LATEST_VERSION" = "latest" ]; then
  npm install -g n8n
else
  npm install -g n8n@$LATEST_VERSION
fi

# Configurar diretório de dados
mkdir -p $INSTALL_PATH/.n8n

# Configurar variáveis de ambiente do n8n
echo -e "${GREEN}Configurando variáveis de ambiente...${NC}"
cat > $INSTALL_PATH/.n8n/.env << EOF
# Configurações básicas do n8n
N8N_PORT=$N8N_PORT
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_PATH=/

# Configurações de autenticação
N8N_EMAIL_MODE=smtp
N8N_DEFAULT_USER_EMAIL=$N8N_EMAIL
N8N_DEFAULT_USER_PASSWORD=$N8N_PASSWORD

# Configurações de banco de dados
DB_TYPE=$DB_TYPE
EOF

# Adicionar configurações específicas de banco de dados se não for SQLite
if [ "$DB_TYPE" != "sqlite" ]; then
  cat >> $INSTALL_PATH/.n8n/.env << EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_DATABASE=$DB_NAME
EOF
fi

# Ajustar permissões
chown -R $N8N_USER:$N8N_USER $INSTALL_PATH

# Configurar serviço systemd
echo -e "${GREEN}Configurando serviço systemd...${NC}"
cat > /etc/systemd/system/n8n.service << EOF
[Unit]
Description=n8n
After=network.target

[Service]
Type=simple
User=$N8N_USER
WorkingDirectory=$INSTALL_PATH
ExecStart=/usr/bin/n8n start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
EnvironmentFile=$INSTALL_PATH/.n8n/.env

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd, habilitar e iniciar serviço
systemctl daemon-reload
systemctl enable n8n
systemctl start n8n

# Configurar o firewall (se necessário)
if command -v ufw &> /dev/null; then
  echo -e "${GREEN}Configurando firewall...${NC}"
  ufw allow $N8N_PORT/tcp
  echo -e "${YELLOW}Porta $N8N_PORT aberta no firewall para acesso ao n8n${NC}"
fi

# Verificar se o serviço iniciou corretamente
sleep 5
if systemctl is-active --quiet n8n; then
  # Obter IP para exibição
  IP=$(hostname -I | awk '{print $1}')
  
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${GREEN}Instalação do n8n concluída com sucesso!${NC}"
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${YELLOW}Você pode acessar a interface do n8n em:${NC}"
  echo -e "${BLUE}http://$IP:$N8N_PORT${NC}"
  echo -e ""
  echo -e "${YELLOW}Credenciais de acesso:${NC}"
  echo -e "${BLUE}Email: $N8N_EMAIL${NC}"
  echo -e "${BLUE}Senha: $N8N_PASSWORD${NC}"
  
  # Salvar informações em um arquivo de texto para referência
  cat > $INSTALL_PATH/instalacao_info.txt << EOF
=== Informações da Instalação do n8n ===
Data da instalação: $(date)
Versão do n8n: $LATEST_VERSION
Diretório de instalação: $INSTALL_PATH
Porta: $N8N_PORT
Endereço de acesso: http://$IP:$N8N_PORT

Credenciais de acesso:
Email: $N8N_EMAIL
Senha: $N8N_PASSWORD

Banco de dados: $DB_TYPE
EOF

  if [ "$DB_TYPE" != "sqlite" ]; then
    cat >> $INSTALL_PATH/instalacao_info.txt << EOF
Host do banco: $DB_HOST:$DB_PORT
Nome do banco: $DB_NAME
Usuário do banco: $DB_USER
EOF
  fi
  
  echo -e "${YELLOW}Um arquivo com as informações da instalação foi salvo em:${NC}"
  echo -e "${BLUE}$INSTALL_PATH/instalacao_info.txt${NC}"
  
else
  echo -e "${RED}Houve um problema ao iniciar o serviço n8n.${NC}"
  echo -e "${YELLOW}Verifique o status com:${NC} systemctl status n8n"
  echo -e "${YELLOW}Verifique os logs com:${NC} journalctl -u n8n -f"
fi

echo -e "${GREEN}Instalação concluída!${NC}"

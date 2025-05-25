# n8n Installer - i9ads

🚀 Instalador automático do n8n no Ubuntu.

## 📜 Descrição

Este script realiza a instalação completa do n8n em um servidor Linux (preferencialmente Ubuntu), configurando ambiente, dependências, banco de dados MySQL e serviço em segundo plano.

## ⚙️ Como Usar

### 1. Obter o Instalador

Execute no seu servidor:

bash
wget -O n8n-installer.sh https://raw.githubusercontent.com/nataoliver/n8n-installer-i9ads/main/n8n-installer.sh
sudo bash n8n-installer.sh

### 2. Seguir as Instruções

O script irá perguntar:

* Diretório de instalação
* Porta desejada
* Credenciais de administrador
* Dados do banco de dados MySQL

### 3. Acesso

Após a instalação, acesse o n8n via:

http://IP_DO_SERVIDOR:PORTA

## 🔒 Requisitos

* Sistema operacional Linux (Ubuntu recomendado)
* Acesso root ou sudo
* Servidor com acesso à internet

## 📂 Estrutura do Repositório

├── n8n-installer.sh   # Script de instalação
├── README.md           # Documentação

## 🛠️ Funcionalidades do Script

* Instala Node.js, n8n e dependências
* Configura banco de dados MySQL
* Cria serviço no systemd
* Inicia o n8n automaticamente

## 🚨 Observações

* Não funciona em hospedagens compartilhadas sem SSH
* Use apenas em servidores sob seu controle

## 🙌 Créditos

Desenvolvido por [@nataoliver](https://github.com/nataoliver) - i9ads
www.i9ads.com.br

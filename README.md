# 🚀 n8n-installer-i9ads

**Instalador automático do n8n para servidores Linux.**

Este script permite instalar o **n8n** de forma rápida, prática e interativa. Ele cuida de toda a configuração necessária, desde dependências até variáveis de ambiente, banco de dados e inicialização automática.

## ⚙️ Funcionalidades

* Instala a versão mais recente do n8n
* Configura porta, diretório de instalação e credenciais
* Permite usar MySQL ou SQLite
* Cria serviço para iniciar o n8n automaticamente
* Instala dependências necessárias (Node.js, npm, etc.)
* Simples, rápido e seguro

## 🚀 Como Usar

### 1️⃣ Execute no seu servidor Linux (Ubuntu, Debian, CentOS...)

#### Opção rápida (via GitHub):

```bash
wget -O n8ni https://raw.githubusercontent.com/nataoliver/n8n-installer-i9ads/main/n8n-installer.sh && sudo bash n8ni
```

### 2️⃣ Siga as instruções na tela

O instalador irá perguntar:

* 📂 **Diretório de instalação** (ex.: `/opt/n8n`)
* 🔐 **Usuário e senha de administrador**
* 🌐 **Porta para rodar o n8n** (ex.: `5678`)
* 🗄️ **Banco de dados** (MySQL ou SQLite)
* ✔️ Confirmações de instalação

### 3️⃣ Acesso ao n8n

Após a instalação, acesse no navegador:

http://IP_DO_SEU_SERVIDOR:PORTA

Use as credenciais que você definiu no processo de instalação.

## 🔥 Pré-requisitos

* ✅ Servidor Linux (Ubuntu, Debian, CentOS, AlmaLinux...)
* ✅ Acesso root ou sudo
* ✅ Acesso à internet no servidor
* 🚫 Não funciona em hospedagens compartilhadas sem SSH

## 🛠️ Tecnologias usadas

* Bash Script
* Node.js
* n8n
* MySQL ou SQLite
* Systemd

## 💡 Observações

* Este script é fornecido **"como está"**. Use por sua conta e risco.
* Sempre teste em ambientes controlados antes de produção.

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## 🧑‍💻 Autor

Feito com 💙 por **[@nataoliver](https://github.com/nataoliver)**.

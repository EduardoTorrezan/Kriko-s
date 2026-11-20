# Kriko’s - Sistema de Atendimento e Gestao de Pedidos

Projeto interdisciplinar de Banco de Dados e Desenvolvimento Web (2º Semestre).

## Acesso ao Sistema

- Cardapio e Pedidos: https://krikos.duckdns.org
- Painel Administrativo: https://krikos.duckdns.org/painel.php
  - Usuario: admin@krikos.com
  - Senha: admin123

## Tecnologias

- Backend: PHP 8.4.1+
- Banco de Dados: MariaDB 13 / MySQL 8
- ORM: Doctrine ORM 3.x / DBAL 4.x
- Frontend: HTML5, CSS3, JavaScript puro, Bootstrap 5
- Infraestrutura: Oracle Cloud Infrastructure (Ubuntu 22.04 LTS), Apache 2.4, Let's Encrypt SSL/TLS, Cloudflare

## Arquitetura do Sistema

O backend foi estruturado em camadas para separar regras de negocio, persistencia e apresentacao:

- Controllers: Recebem as requisicoes HTTP e gerenciam as respostas (UserControl.php).
- Chain of Responsibility: Encadeamento de validacoes e processamento de operacoes (Handler.php, ChainControl.php).
- Services: Classes responsaveis pelas regras de validacao, cadastro, busca e atualizacao.
- DTO (Data Transfer Object): Transporte de dados tipados entre camadas.
- Doctrine ORM: Mapeamento objeto-relacional com arquivos XML (config/xml), garantindo operacoes seguras contra SQL Injection e integridade transacional.

## Estrutura do Banco de Dados

O banco de dados (krikos_db) contem 7 tabelas relacionais com integridade referencial estrita (src/Repository/Schema/SchemaDb.sql):

1. administradores: Usuarios do sistema interno com perfis MASTER, GARCOM e COZINHA. Senhas armazenadas com hash criptografico.
2. mesas: Controle das mesas fisicas do estabelecimento com restricao UNIQUE.
3. categorias: Classificacao dos produtos (ex: Pastel, Churros, Porcoes).
4. produtos: Itens comercializados. Precos gravados em centavos (INT) com constraint CHECK (preco >= 0) para evitar imprecisao de ponto flutuante.
5. pedidos: Cabecalho do pedido vinculado a mesa e ao atendente, com controle de status (ABERTO, EM_PREPARACAO, PRONTO, FINALIZADO, CANCELADO) e forma de pagamento.
6. itens_pedido: Relacao N:N entre pedidos e produtos com quantidade e valor unitario.
7. pagamentos: Historico financeiro com suporte a PIX, DINHEIRO, CARTAO_CREDITO e CARTAO_DEBITO.

## Infraestrutura e Redundancia

O projeto foi implantado com arquitetura distribuida:

1. Servidor Principal (Nuvem): Instancia Linux Ubuntu na Oracle Cloud rodando Apache 2.4, MariaDB e PHP 8.4, com certificado SSL Let's Encrypt e dominio krikos.duckdns.org.
2. Servidor Local (Contingencia): Servidor PHP local no computador de desenvolvimento conectado diretamente ao banco de dados da nuvem pela porta 3306.
3. Sincronizacao: Ambos os ambientes utilizam o mesmo banco de dados centralizado em tempo real.

## Como Executar Localmente

### Opcao 1: Windows (Script Automatico)
Execute o arquivo:
```cmd
iniciar_servidor.bat
```

### Opcao 2: Manual via Terminal
1. Instale as dependencias do Composer:
```bash
composer install
```
2. Defina as variaveis de ambiente de conexao:
```bash
export KRIKOS_DB_HOST="147.15.21.44"
export KRIKOS_DB_PORT="3306"
export KRIKOS_DB_NAME="krikos_db"
export KRIKOS_DB_USER="krikos_user"
export KRIKOS_DB_PASSWORD="SuaSenha"
```
3. Inicie o servidor PHP apontando para a pasta public:
```bash
php -S 127.0.0.1:8765 -t public
```
4. Acesse: http://127.0.0.1:8765

## Estrutura de Diretorios

- bin/: Utilitarios de linha de comando.
- config/xml/: Mapeamento XML das entidades do Doctrine ORM.
- deploy/: Scripts bash de provisionamento na nuvem (Oracle e GCP).
- includes/: Componentes reutilizaveis de visualizacao e sessao.
- public/: DocumentRoot do servidor web (index.php, painel.php, assets, api).
- src/: Codigo-fonte do backend (Controllers, Services, Entities, DTOs, Repository).
- iniciar_servidor.bat: Script de inicializacao rapida do servidor local.
- APRESENTACAO.md: Guia e roteiro de apresentacao para a banca.

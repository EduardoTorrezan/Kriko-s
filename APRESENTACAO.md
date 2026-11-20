# Plano de Apresentacao - Infraestrutura e Deploy

Guia objetivo focado exclusivamente na arquitetura de infraestrutura, redes, seguranca e deploy em nuvem do projeto.

---

## 1. Visao Geral da Infraestrutura

A infraestrutura foi desenhada para tirar a aplicacao do ambiente puramente local (localhost) e disponibiliza-la na internet com alta disponibilidade, seguranca SSL e redundancia.

A solucao e composta por dois nós integrados:
1. Servidor de Producao na Nuvem (Oracle Cloud Infrastructure): maquina virtual Linux 24/7.
2. Servidor de Contingencia / Desenvolvimento (Local): computador do desenvolvedor com conexao direta ao banco centralizado.
3. Banco de Dados Compartilhado: instancia MariaDB na nuvem atendendo tanto a producao quanto o ambiente local em tempo real.

---

## 2. Componentes e Etapas da Infraestrutura

### 2.1. Maquina Virtual e Sistema Operacional (Oracle Cloud)
- Instancia de computacao com sistema Linux Ubuntu 22.04 LTS (x86_64).
- Alocacao de 2 GB de memoria Swap (/swapfile) para complementar a memoria fisica e evitar travamentos por estouro de memoria (Out of Memory - OOM) ao executar Apache, PHP 8.4 e MariaDB simultaneamente.
- Instalacao do runtime PHP 8.4 via repositorio PPA (ondrej/php), servidor web Apache 2.4 e banco MariaDB 13.

### 2.2. Arquitetura de Rede (VCN, Subnet e Roteamento)
- Criacao de uma Virtual Cloud Network (VCN) com bloco CIDR 10.0.0.0/16.
- Sub-rede publica com bloco CIDR 10.0.0.0/24 associada a um IP publico estatico (147.15.21.44).
- Criacao de um Internet Gateway (krikos-gateway) na VCN.
- Criacao de Tabela de Roteamento (Route Table) direcionando todo o trafego externo (0.0.0.0/0) para o Internet Gateway da sub-rede.

### 2.3. Seguranca de Rede e Firewall
A seguranca opera em duas camadas independentes:
1. Security List (Firewall de Borda da Oracle):
   - Porta 22 (TCP): acesso administrativo seguro via SSH por chave privada criptografica.
   - Porta 80 (TCP): trafego web HTTP e validacao de certificados.
   - Porta 443 (TCP): trafego web seguro HTTPS (SSL/TLS).
   - Porta 3306 (TCP): comunicacao com o banco de dados MariaDB.
2. Firewall Interno do Linux (iptables):
   - Ajuste na ordem das regras do kernel Linux para permitir as portas 80, 443 e 3306 antes da regra padrao de bloqueio (REJECT).
   - Persistencia das regras entre reinicializacoes do servidor atraves do netfilter-persistent / iptables-save.

### 2.4. Dominio e Certificado SSL/TLS (HTTPS)
- Dominio DNS dinamico configurado: krikos.duckdns.org apontando para o IP 147.15.21.44.
- Emissao de certificado digital oficial pela autoridade certificadora Let's Encrypt atraves da ferramenta Certbot.
- Criacao de VirtualHost SSL no Apache (krikos-le-ssl.conf) com redirecionamento automatico de HTTP para HTTPS.
- Renovacao automatica de certificados ativada via timer do systemd (certbot.timer).

### 2.5. Banco Centralizado e Integracao Hibrida
- Configuracao do arquivo 50-server.cnf do MariaDB para escutar em todas as interfaces de rede (bind-address = 0.0.0.0).
- Criacao de usuario de banco de dados com privilegio de conexao remota (krikos_user).
- O ambiente local no computador Windows utiliza variaveis de ambiente apontando o host do banco para o IP publico da Oracle (147.15.21.44:3306).
- Resultado: qualquer transacao feita localmente reflete instantaneamente no servidor da nuvem, e vice-versa.

### 2.6. Automacao e Contingencia
- Script de inicializacao rapida local (iniciar_servidor.bat) que checa portas, define as variaveis de conexao da nuvem e sobe o servidor PHP em 1 clique.
- Script de provisionamento da nuvem (deploy/deploy-oracle.sh) que automatiza a instalacao completa de pacotes, configuracao de swap, clonagem de codigo e ativacao de servicos.

---

## 3. Roteiro Sugerido para a Apresentacao (8 a 10 minutos)

### Bloco 1: Objetivo da Infraestrutura 
- Falar que a meta foi construir uma infraestrutura real de producao em nuvem, superando o modelo tradicional que roda apenas em localhost.
- Apresentar a topologia: nó de producao na nuvem da Oracle, nó local de desenvolvimento e banco unificado.

### Bloco 2: Construcao Nuvem e Redes
- Explicar a VCN e a sub-rede publica na Oracle Cloud.
- Explicar como o trafego chega a maquina: Internet Gateway -> Route Table -> Security List -> maquina virtual.
- Mencionar a configuracao do sistema operacional Linux: instalacao do Apache, PHP 8.4, MariaDB e criacao de 2GB de Swap.

### Bloco 3: Seguranca, Dominio e Certificado SSL
- Mostrar o dominio https://krikos.duckdns.org acessivel no navegador com o cadeado de seguranca ativo.
- Explicar o processo de emissao do certificado Let's Encrypt com Certbot na porta 80 e o redirecionamento para HTTPS na porta 443.
- Explicar o ajuste de firewall em duas camadas (Security List na nuvem e iptables no Linux).

### Bloco 4: Banco Compartilhado Demonstracao Pratica
- Mostrar que o computador local e o servidor da nuvem conversam com o mesmo banco.
- Demonstrar ao vivo:
  1. Abrir o site no celular pelo link HTTPS oficial (https://krikos.duckdns.org).
  2. Abrir o terminal ou o ambiente local no computador.
  3. Fazer uma alteracao ou pedido e demonstrar que ambos os nós enxergam o mesmo dado instantaneamente.

---

## 4. Desafios Superados

1. Falta de capacidade de instancias (Out of Capacity): selecao e ajuste correto do modelo de computacao compativel com o plano Always Free da nuvem.
2. Roteamento de rede: correcao de conflito de sub-redes e configuracao manual da tabela de rotas direcionando o destino 0.0.0.0/0 para o Internet Gateway correto.
3. Ordem de regras no iptables: o firewall interno do Linux avalia regras de cima para baixo. Foi necessario inserir as liberacoes de portas web antes da instrucao padrao de REJECT da imagem base.
4. Conexao remota ao banco de dados: alteracao do bind-address do MariaDB de 127.0.0.1 para 0.0.0.0 e criacao de usuario com permissao global de host.

---

## 5. Perguntas Provaveis da Banca sobre Infraestrutura

### Pergunta 1: Por que utilizar Swap em uma maquina virtual?
Resposta: A maquina virtual gratuita possui memoria RAM limitada. A criacao de um arquivo de Swap de 2 GB em disco permite que o kernel do Linux descarregue processos inativos para o disco caso o consumo momentaneo do PHP e MariaDB exceda a memoria fisica, evitando que o sistema finalize processos com erros de Out of Memory.

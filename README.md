# Stack Completa: Rails API com ELK (Elasticsearch, Logstash, Kibana) e Nginx

Este projeto demonstra uma arquitetura completa e robusta para uma aplicação API em Ruby on Rails, utilizando o Docker Compose para orquestrar todos os serviços necessários para desenvolvimento e produção, incluindo um pipeline de logging centralizado com a Stack ELK e um proxy reverso com Nginx.

## Tecnologias Utilizadas

-   **Backend:** Ruby on Rails 7 (API-only)
-   **Banco de Dados:** PostgreSQL
-   **Proxy Reverso:** Nginx
-   **Logging:**
    -   **Elasticsearch:** Para armazenamento e busca dos logs.
    -   **Logstash:** Para processamento e ingestão dos logs.
    -   **Kibana:** Para visualização e análise dos logs.
-   **Orquestração:** Docker & Docker Compose

## Pré-requisitos

Antes de começar, garanta que você tenha os seguintes softwares instalados na sua máquina:
-   [Docker](https://docs.docker.com/get-docker/)
-   [Docker Compose](https://docs.docker.com/compose/install/)

## 🚀 Configuração e Inicialização (Passo a Passo)

Siga estes passos na ordem correta para inicializar toda a stack.

### 1. Crie a Imagem Docker da Aplicação Rails

Este projeto utiliza uma imagem Docker customizada para a aplicação Rails. O primeiro passo é construí-la a partir do `Dockerfile` do projeto.

Execute o seguinte comando na raiz do projeto:
```bash
docker build -t rails-elk:1.0 .
```
*(**Nota:** O `1.0` no final é a "tag" da imagem. Certifique-se de que ela corresponde à tag definida para o serviço `rails` no arquivo `docker-compose.yml`)*

### 2. Configure as Variáveis de Ambiente

As senhas e configurações sensíveis são gerenciadas através de um arquivo `.env`. Se houver um arquivo `env.example` no projeto, copie-o para um novo arquivo chamado `.env`. Caso contrário, crie o arquivo `.env` do zero.

**Crie o arquivo `.env` com o seguinte conteúdo:**
```ini
# Variáveis do PostgreSQL
POSTGRES_USER=""
POSTGRES_PASSWORD=""
POSTGRES_DB=""

# Chave secreta do Rails (gere uma nova para produção com `rails secret`)
SECRET_KEY_BASE="34f3b9fcd4d6056025e3b25818ac2f3e"

# Versão da Stack ELK (garante que todos os componentes são compatíveis)
STACK_VERSION="8.14.0"

# Nome do Cluster Elasticsearch
CLUSTER_NAME=""

# Senha do superusuário 'elastic'
ELASTIC_PASSWORD=""

# A SENHA DO KIBANA SERÁ ADICIONADA EM UM PASSO POSTERIOR
```

### 3. Suba a Stack e Configure a Senha do Kibana

Este é um processo de inicialização em duas etapas, necessário para configurar a senha do usuário de sistema do Kibana de forma segura.

**a) Suba todos os serviços:**
```bash
docker compose up -d
```
> **Nota:** É normal que o contêiner do Kibana entre em um loop de reinicialização ou fique com o status "unhealthy" neste momento. Ele não consegue se conectar ao Elasticsearch sem a senha correta, que vamos definir agora.

**b) Defina a senha para o usuário `kibana_system`:**
O comando abaixo irá definir a senha para o usuário que o Kibana usa para se comunicar com o Elasticsearch.

> **IMPORTANTE:** Para o comando funcionar, a variável `ELASTIC_PASSWORD` precisa estar disponível no seu terminal. Você pode fazer isso de duas formas:
> 1.  Rodar `source .env` no seu terminal antes de executar o comando abaixo (se seu `.env` contiver `export`). Se não rode export ELASTIC_PASSWORD="Sua Senha Aqui"
> 2.  Substituir `${ELASTIC_PASSWORD}` pela senha real diretamente no comando.

```bash
docker exec -it elasticsearch curl -X POST -u elastic:${ELASTIC_PASSWORD} \
     -H "Content-Type: application/json" \
     http://localhost:9200/_security/user/kibana_system/_password \
     -d '{"password":"NovaSenh@123"}'
```
*(Usamos "NovaSenh@123" como exemplo, você pode usar outra senha forte)*

**c) Desligue a stack, atualize o `.env` e suba novamente:**
Agora que a senha foi criada no Elasticsearch, precisamos informar essa senha para o serviço do Kibana.

```bash
# Desliga tudo de forma limpa
docker compose down
```
Agora, **adicione a senha do Kibana ao seu arquivo `.env`**:
```ini
# Adicione esta linha ao final do seu .env
KIBANA_PASSWORD="NovaSenh@123"
```
E finalmente, suba a stack novamente. Agora o Kibana iniciará com sucesso.
```bash
docker compose up -d
```

### 4. Execute as Migrações do Banco de Dados

Com a stack no ar, precisamos criar as tabelas no banco de dados PostgreSQL.
```bash
docker compose exec rails bin/rails db:migrate
```

**Pronto! Sua stack está 100% operacional.**

## Endpoints da API

A aplicação Rails expõe os seguintes endpoints para o recurso `livros`, acessíveis através do Nginx (ex: `http://localhost:8081/livros`).

-   `GET /livros` - Retorna uma lista de todos os livros.
-   `GET /livros/:id` - Retorna os detalhes de um livro específico.
-   `POST /livros` - Cria um novo livro.
-   `PATCH / PUT /livros/:id` - Atualiza um livro existente.
-   `DELETE /livros/:id` - Remove um livro específico.

#### Exemplo de Objeto JSON (para `POST` e `PUT`/`PATCH`)

```json
{
  "livro": {
    "name": "Clean Code",
    "isbn": 9780132350884,
    "description": "Um guia de boas práticas para desenvolvimento de software.",
    "author": "Robert C. Martin"
  }
}
```

## Visualizando os Logs no Kibana

1.  **Gere um Log:** Faça uma ou mais requisições para a sua API (ex: `GET http://localhost:8081/livros`) para que o Rails gere um log, o Logstash o processe e o Elasticsearch o indexe.
    > **OBS:** É crucial que você gere um log primeiro para que o índice seja criado no Elasticsearch. O Kibana não encontrará o padrão de índice se nenhum dado tiver sido enviado ainda. Normalmente a aplicação rails gera um log no "migrate"

2.  **Acesse o Kibana:** Abra `http://localhost:5601` no seu navegador.
3.  **Faça Login:** Use o usuário `elastic` e a senha que você definiu em `ELASTIC_PASSWORD`.
4.  **Crie uma Data View:**
    -   No menu lateral, vá em **Stack Management -> Kibana -> Data Views**.
    -   Clique em **Create data view**.
    -   No campo **Index pattern**, digite `rails-logs-*`. O Kibana deve encontrar seu índice correspondente.
    -   No campo **Timestamp field**, selecione `@timestamp`.
    -   Clique em **Create data view**.
5.  **Explore!** Vá para a seção **Discover** (ícone de bússola 🧭 no menu) para ver, filtrar e analisar seus logs em tempo real.
FROM ruby:3.4.4-slim

# Cria o diretório da aplicação
WORKDIR /rails

# Instala dependências básicas e PostgreSQL client
RUN apt-get update && \
    apt-get install -y curl libjemalloc2 libvips libyaml-dev postgresql-client build-essential libpq-dev git pkg-config

# Define ambiente de produção para o Rails
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Copia arquivos de dependências e instala gems
# Similar ao package.json do Node.js, o Gemfile define as dependências do Rails
# e o Gemfile.lock garante que as versões sejam consistentes. assim como o package-lock.json do Node.js. (Não entendo muito, mas o que eu entendi)
COPY Gemfile Gemfile.lock ./

## Roda o comando bundle install para instalar as gems do Rails
# O comando bundle install é como npm install no Node.js, instala as dependências do Rails
RUN bundle install 

# Copia todo o código da aplicação
# com exceção dos arquivos e diretórios listados no .dockerignore
COPY . .

# # Ajusta permissões (opcional, mas recomendado)
RUN chown -R nobody:nogroup /rails && chmod +x ./bin/rails

# Expõe a porta padrão do Rails
EXPOSE 3000

# Comando padrão para rodar o servidor Rails
CMD ["./bin/rails", "server"]

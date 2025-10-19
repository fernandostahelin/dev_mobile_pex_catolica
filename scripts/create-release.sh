#!/bin/bash

# Script para criar uma nova release do PEX
# Uso: ./scripts/create-release.sh [versão] [mensagem]
# Exemplo: ./scripts/create-release.sh v1.0.0 "Primeira release"

set -e

# Verifica se a versão foi fornecida
if [ -z "$1" ]; then
    echo "❌ Erro: Versão não fornecida"
    echo "Uso: $0 [versão] [mensagem]"
    echo "Exemplo: $0 v1.0.0 \"Primeira release\""
    exit 1
fi

VERSION=$1
MESSAGE=${2:-"Release $VERSION"}

echo "🚀 Criando release $VERSION..."

# Verifica se estamos no branch main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Aviso: Você não está no branch main (atual: $CURRENT_BRANCH)"
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operação cancelada"
        exit 1
    fi
fi

# Verifica se há mudanças não commitadas
if ! git diff-index --quiet HEAD --; then
    echo "❌ Erro: Há mudanças não commitadas"
    echo "Por favor, faça commit das suas mudanças antes de criar uma release"
    exit 1
fi

# Verifica se a tag já existe
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "❌ Erro: A tag $VERSION já existe"
    exit 1
fi

# Atualiza a versão no pubspec.yaml
echo "📝 Atualizando versão no pubspec.yaml..."
VERSION_NUMBER=${VERSION#v}  # Remove o 'v' do início
sed -i.bak "s/version: .*/version: $VERSION_NUMBER+1/" pubspec.yaml
rm pubspec.yaml.bak

# Commit da mudança de versão
git add pubspec.yaml
git commit -m "Bump version to $VERSION_NUMBER"

# Cria a tag
echo "🏷️  Criando tag $VERSION..."
git tag -a "$VERSION" -m "$MESSAGE"

# Push das mudanças e da tag
echo "📤 Enviando para o repositório remoto..."
git push origin main
git push origin "$VERSION"

echo "✅ Release $VERSION criada com sucesso!"
echo "🔗 Acesse: https://github.com/USERNAME/pex/releases/tag/$VERSION"
echo "⏳ O GitHub Actions irá automaticamente:"
echo "   - Executar os testes"
echo "   - Gerar o APK de release"
echo "   - Anexar o APK à release"
echo ""
echo "📱 O APK estará disponível para download em alguns minutos!"

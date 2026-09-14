#!/bin/bash
echo "Iniciando teste de concorrência com 2 requisições simultâneas para o Gemma 3 1B..."

# Dispara a primeira requisição em background (&)
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "gemma3:1b",
  "prompt": "Explique o conceito de threads em sistemas operacionais.",
  "stream": false
}' &

# Dispara a segunda requisição em background (&)
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "gemma3:1b",
  "prompt": "Qual a diferença entre concorrência e paralelismo?",
  "stream": false
}' &

# Aguarda ambas terminarem
wait
echo -e "\nTeste de concorrência concluído."
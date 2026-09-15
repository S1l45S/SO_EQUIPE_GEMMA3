# Atividade 1 - Sistemas Operacionais (2026.2)

## Equipe Gemma 3

- Bruno Amancio Ferreira
- Christian Will Silva Santos Nunes
- Iasmin Victoria Teixeira Barreto
- Marcos Vinícius Dantas aguiar
- Pedro César Figueiredo Carneiro
- Sibele Oliveira Cruz
- Silas Santos da Silva

## Vídeo da Atividade

- **URL do Vídeo:** [Inserir Link do Vídeo Aqui]
- A URL também está documentada de forma isolada no arquivo `VIDEO.md` na raiz deste repositório, conforme exigência da disciplina.

## Contexto e Objetivos

Este repositório contém os artefatos, logs e análises da **Atividade 1 (AV1)** da disciplina de **Sistemas Operacionais**.

O foco do projeto é observar e relacionar os conceitos de **processos, threads, chamadas de sistema, escalonamento e uso de recursos** durante a execução de uma aplicação local de Inteligência Artificial Generativa.

- **Trilha de Aplicação:** Trilha A - Chat local: Ollama + Open WebUI
- **Modelo de Linguagem:** Google Gemma 3 1B IT (`google/gemma-3-1b-it`)
- **Formato e Quantização:** GGUF / Q4_K_M

## Inventário do Ambiente Experimental

Os experimentos foram executados na seguinte infraestrutura:

| Componente              | Especificação                                          |
|-------------------------|--------------------------------------------------------|
| **Sistema Operacional** | Ubuntu 26.04.1 LTS (Resolute Raccoon) aarch64          |
| **Processador**         | Apple Silicon (ARM64), 5 núcleos on-line (0-4), 64-bit |
| **Memória RAM**         | 11 GiB                                                 |
| **Armazenamento**       | 20 GiB (Partição NVMe)                                 |
| **Runtime de IA**       | Ollama v0.34.0                                         |
| **Camada de Aplicação** | Open WebUI (`ghcr.io/open-webui/open-webui:main`)      |
| **Containerização**     | Docker Engine 29.8.0 / containerd v2.3.5               |


### Descrição dos arquivos e diretórios

- `README.md`: Documento principal do repositório, contendo a apresentação da atividade, descrição do ambiente experimental, instruções de instalação e execução, metodologia dos experimentos e comandos utilizados para monitoramento do sistema.

- `entregaveis/`: Diretório destinado aos materiais finais da atividade, reunindo os documentos e arquivos utilizados para avaliação e apresentação do trabalho.
    - `VIDEO.md`: Documento contendo o link para o vídeo de apresentação da equipe, conforme solicitado pela disciplina.
    - `relatorio_tecnico_Equipe_Gemma3.pdf`: Relatório técnico completo da equipe, contendo o desenvolvimento da atividade, procedimentos experimentais, evidências coletadas e análises teóricas e experimentais das 13 questões propostas.
    - `apresentacao_Equipe_Gemma3.pdf`: Apresentação utilizada pela equipe para exposição dos objetivos, metodologia, ambiente experimental, resultados e principais conclusões da atividade.

- `scripts/`: Diretório que reúne os scripts utilizados durante a realização dos experimentos.

- `logs/`: Diretório destinado ao armazenamento das evidências coletadas durante os experimentos. Contém registros obtidos por meio de ferramentas de monitoramento e diagnóstico do sistema operacional, como `ps`, `top`, `pstree`, `strace` e `lscpu`.

---

# Instalação e Execução

## 1. Preparação do Runtime e do Modelo

O Ollama foi instalado nativamente no host para permitir acesso aos recursos do sistema operacional.

### Instalação do Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Download e execução do modelo

```bash
ollama run gemma3:1b
```

---

## 2. Implantação da Camada de Aplicação

A interface **Open WebUI** foi instanciada de forma isolada em um contêiner Docker.

O parâmetro `host.docker.internal` foi utilizado para garantir que a interface consiga se comunicar com o Ollama hospedado no host.

A porta `8080` do contêiner foi mapeada para a porta `3000` do host, enquanto o Ollama permanece disponível na porta `11434`.

### Execução do Open WebUI

```bash
docker run -d -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Após a inicialização, a aplicação pode ser acessada pelo navegador através de:

```text
http://localhost:3000
```

---

# Reprodução dos Experimentos

Foram executados **três cenários de configuração**, cada um com pelo menos três repetições, visando observar diferentes comportamentos relacionados ao escalonamento, concorrência, processos, threads e chamadas de sistema.

## Configuração 1: Execução Padrão

Foi realizada uma requisição isolada via API para obtenção de uma medida de base (*baseline*) de:

- Latência;
- Tempo até o primeiro token (TTFT);
- Vazão;
- Utilização dos recursos do sistema.

### Comando

```bash
time curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:1b",
    "prompt": "Explique o que é escalonamento de processos.",
    "stream": false
  }'
```

---

## Configuração 2: Concorrência Modificada

Neste cenário foram realizadas múltiplas requisições simultâneas com o objetivo de estressar a fila de entrada e observar o comportamento do processo `llama-server`.

Durante o experimento, foi observado:

- Aproximadamente **410% de utilização de CPU**;
- Intensa competição entre as threads;
- Aproximadamente **14 threads** geradas pelo runtime;
- Aumento da concorrência durante o processamento das requisições.

### Reprodução

Execute o comando da Configuração 1 em **dois ou mais terminais simultaneamente**:

```bash
time curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:1b",
    "prompt": "Explique o que é escalonamento de processos.",
    "stream": false
  }'
```
---

# Comandos de Monitoramento Utilizados

Para extrair as evidências relacionadas a **processos, threads, utilização de recursos e chamadas de sistema**, foram utilizados os seguintes comandos.

## Árvore e Hierarquia de Processos

O comando `pstree` permite visualizar a hierarquia entre os processos em execução.

```bash
pstree -p
```

---

## Consumo de CPU e RAM

O comando `ps` foi utilizado para obter informações sobre processos, incluindo PID, PPID, estado, utilização de CPU e memória e quantidade de threads.

```bash
ps -eo pid,ppid,stat,pcpu,pmem,nlwp,comm --sort=-pcpu | head -20
```

### Principais campos

| Campo     | Descrição                           |
|-----------|-------------------------------------|
| `PID`     | Identificador do processo           |
| `PPID`    | Identificador do processo pai       |
| `STAT`    | Estado atual do processo            |
| `%CPU`    | Percentual de utilização da CPU     |
| `%MEM`    | Percentual de utilização da memória |
| `NLWP`    | Número de threads do processo       |
| `COMMAND` | Nome do processo                    |

---

## Monitoramento de Threads em Tempo Real

O comando abaixo permite visualizar individualmente as threads e acompanhar seu comportamento durante a execução:

```bash
top -H
```

A opção `-H` faz com que o `top` apresente as threads individualmente, permitindo observar a distribuição da carga entre elas.

---

## Rastreamento de Chamadas de Sistema

O `strace` foi utilizado para analisar as chamadas de sistema realizadas pelo processo `llama-server`.

```bash
strace -c -p $(pidof llama-server)
```

A opção `-c` apresenta um resumo estatístico das chamadas de sistema realizadas durante o período de rastreamento.

---

# Evidências Experimentais

Os resultados obtidos durante os experimentos são armazenados no diretório `logs/`.

Esses arquivos contêm as saídas brutas dos comandos utilizados para monitoramento e análise do comportamento do sistema operacional.

Entre as principais evidências estão:

- Hierarquia de processos;
- Quantidade e comportamento das threads;
- Uso de CPU;
- Uso de memória;
- Chamadas de sistema;
- Informações sobre o processador;
- Resultados dos diferentes cenários de execução.

---

# Relatório Técnico

O relatório acadêmico completo da atividade está disponível no arquivo:

```text
relatorio_tecnico_Equipe_Gemma3.pdf
```

O documento apresenta a análise teórica e experimental dos conceitos de Sistemas Operacionais observados durante a execução da aplicação local de Inteligência Artificial Generativa.

---

# Resumo do Ambiente

```text
Sistema Operacional
└── Ubuntu 26.04.1 LTS
    └── Apple Silicon ARM64
        ├── 5 núcleos
        ├── 11 GiB RAM
        └── 20 GiB NVMe

Aplicação
├── Ollama v0.34.0
│   └── Gemma 3 1B IT
│       └── GGUF / Q4_K_M
│
└── Open WebUI
    └── Docker
        └── porta 3000 → 8080

Monitoramento
├── pstree
├── ps
├── top -H
└── strace
```

# Equipe

**Equipe Gemma 3 — Sistemas Operacionais 2026.2**

Universidade Federal de Sergipe — UFS

# ⚖️ DOC Intelligence — Serviço de Inteligência Documental
> **Trilha B: Front-end** | Desafio Técnico de Inteligência Documental Jurídica  
> Desenvolvido em **Flutter 3.47.2 (Dart 3.13.2)** com **GetX** e **Clean Architecture**.

---

## 📌 1. Sobre o Projeto

O **DOC Intelligence** é uma solução de esteira inteligente projetada para transformar e automatizar o fluxo documental de um escritório de advocacia. Diariamente, centenas de peças e anexos chegam por WhatsApp, e-mail e balcão físico (identidades, comprovantes de residência, contracheques, certidões, laudos, procurações e contratos). O processo manual anterior exigia cerca de 4 minutos por arquivo para triagem, renomeação e digitação em planilhas.

Esta aplicação entrega uma **interface Web/Desktop de alta produtividade** para o atendimento e a equipe jurídica, com:
* **Recepção em Lote (*Batch Upload*):** Envio simultâneo de múltiplos arquivos com arrastar e soltar (*Drag & Drop*).
* **Classificação e Extração:** Visualização dos dados inferidos pelo modelo de IA e padronização automática de nomenclatura.
* **Conferência Humana (*Split View*):** Validação lado a lado do documento original (PDF/Imagem em alta fidelidade) com os campos extraídos.
* **Governança por Cliente (*Aggregate Root*):** Agrupamento documental por titular com isolamento de dados (LGPD) e prevenção a fraudes/duplicatas.

---

## 🎯 2. Como o Projeto Atende aos Requisitos e Fatos do Desafio

O projeto foi construído endereçando rigorosamente tanto o **produto-alvo** quanto os **7 fatos reais do ambiente** descritos no [desafio.pdf](assets/mock/desafio.pdf):

### 📋 Aderência aos Comportamentos do Produto-Alvo
1. **Recepção de Documentos (PDF e Imagens):** Suporte nativo a PDFs vetoriais e imagens brutas de câmera (JPEG, PNG).
2. **Classificação, Extração e Renomeação Padronizada:** O sistema infere a tipologia, extrai campos essenciais e propõe o nome sanitizado:
   $$\text{[TIPO\_DOCUMENTO]}\_\text{[PRIMEIRO\_NOME\_CLIENTE]}\_\text{[DATA\_ENVIO]}.\text{[extensao]}$$
3. **Consulta e Histórico:** Listagem completa de clientes e seus respectivos dossiês com status reativo.
4. **Fila de Conferência Humana:** Documentos processados entram como *"Aguardando Conferência"*, impedindo que a máquina aprove dados sem supervisão humana.
5. **Consumo por Sistemas Internos:** Modelagem orientada a domínios internos (`/clients`, `/clients/{id}/documents`), pronta para integração com ERPs jurídicos.

---

### 🛡️ Tratamento dos Fatos Reais do Ambiente

| Fato do Ambiente | Impacto Real | Solução Implementada no Front-end |
| :--- | :--- | :--- |
| **a) Latência e Custo de IA** *(5–40s por doc, falhas esporádicas e cobrança por chamada)* | Risco de travamento da tela e cobranças extras por reprocessamento. | • Processamento assíncrono com feedback de progresso e skeletons.<br>• **Proteção de Custos:** Botões de IA e aprovação são desabilitados após o status `Conferido` (`reviewed`), impedindo reprocessamento acidental.<br>• Tratamento de erro com opção de retry manual. |
| **b) Origem Mobile Sem Validação** *(Nomes sujos: "WhatsApp Image...", "scan0001.pdf")* | Dificuldade de auditoria e desorganização de arquivos. | • Preservação do `originalName` bruto para auditoria.<br>• Geração automática do `standardizedName` corporativo com sanitização.<br>• Visualizador híbrido com zoom interativo. |
| **c) Reenvio Frequente de Duplicatas** *(Envios repetidos por insegurança do cliente)* | Poluição da base e custos duplicados de inferência. | • **Hash Criptográfico SHA-256:** Cálculo binário instantâneo no upload.<br>• Badge visual **`DUPLICADO`** em destaque âmbar na fila.<br>• Botão *"Remover Duplicatas"* para expurgo em 1 clique.<br>• Permite múltiplos documentos legítimos do mesmo tipo (ex: 3 contratos). |
| **d) Dados Pessoais Sensíveis (LGPD)** *(Risco de vazamento de dados de clientes)* | Não conformidade jurídica e risco regulatório. | • Ambiente 100% alimentado com dados e PDFs fictícios sintéticos.<br>• Agrupamento estrito por Cliente (*Aggregate Root*).<br>• Mascaramento de CPF e imutabilidade de dados pós-aprovação. |
| **e) Picos de Volume** *(150 a 800+ docs/dia das 9h às 11h)* | Lentidão no navegador e sobrecarga de rede. | • Dropzone em lote com fila reativa item a item.<br>• Listagem de clientes com paginação configurável (10, 25, 50) e busca com *debounce* (400ms). |
| **f) Troca de Versão do Modelo e Prompts** *(Evolução contínua da IA)* | Quebra de contrato e incompatibilidade de UI. | • *Clean Architecture* e *Repository Pattern* isolados do framework de UI.<br>• Mapeamento defensivo com tipologias predefinidas e fallback para `'Outros'`. |
| **g) Concorrência entre Atendentes** *(Dois conferentes abrindo o mesmo arquivo)* | Sobrescrita cega de correções (*Lost Update*). | • **Bloqueio Otimista (*Optimistic Locking*):** Controle de versão (`version`) e timestamp (`updatedAt`).<br>• **Tratamento HTTP 409 Conflict:** Modal informativo com ação **"Recarregar Dados"**.<br>• Botão no cabeçalho para simulação e teste de concorrência 409. |

---

## 🧪 3. O que Escolhemos Testar e Por Quê

> **Declaração de Escopo de Testes (Requisito da Entrega):**  
> Focamos a suíte de testes automatizados nos **mecanismos de integridade de dados e resiliência de negócio** da aplicação, localizados em `test/`:
> 1. **Controle de Concorrência (`ConflictException` / HTTP 409):** Validamos que tentativas simultâneas de gravação com versões defasadas sejam interceptadas, prevenindo perda de dados de conferência.
> 2. **Detecção Criptográfica de Duplicatas (Hash SHA-256):** Testamos a precisão matemática do cálculo de hash binário para barrar reenvios idênticos, garantindo ao mesmo tempo a coexistência de múltiplos anexos distintos da mesma tipologia (ex: múltiplos contratos válidos).
> 3. **Geração Segura de PDFs Sintéticos em Memória:** Garantimos que o gerador de mocks produza documentos jurídicos válidos sem erros de codificação de fontes ou estouro de memória.

Para executar os testes:
```bash
flutter test
```

---

## 🚀 4. Guia de Instalação e Execução

### 🔧 Pré-requisitos
* **Flutter SDK:** Versão `3.47.2` (canal `stable`)
* **Dart SDK:** Versão `3.13.2`
* **Navegador Web (Google Chrome)** ou ambiente Desktop (macOS / Linux / Windows)
* **Git**

---

### 📥 Passo 1: Como Instalar o Flutter 3.47.2

#### Opção A: Via FVM (Flutter Version Management) — Recomendado
Se você já utiliza o `fvm`:
```bash
# Instalar a versão exata do projeto
fvm install 3.47.2

# Definir como versão ativa no projeto
fvm use 3.47.2

# Obter dependências e rodar
fvm flutter pub get
fvm flutter run -d chrome
```

#### Opção B: Instalação Manual via Git
```bash
# 1. Clone o repositório oficial do Flutter (ou acesse seu diretório flutter existente)
git clone https://github.com/flutter/flutter.git -b stable ~/flutter

# 2. Navegue até o diretório e faça o checkout na tag 3.47.2
cd ~/flutter
git fetch --tags
git checkout 3.47.2

# 3. Adicione o Flutter ao seu PATH (exemplo para zsh no macOS/Linux)
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 4. Verifique a instalação
flutter --version
# Saída esperada: Flutter 3.47.2 • channel stable • Dart 3.13.2
```

---

### 💻 Passo 2: Clonar e Rodar o Projeto

```bash
# 1. Clonar o repositório
git clone https://github.com/nickolas-silva/doc_intelligence.git
cd doc_intelligence

# 2. Obter as dependências do projeto
flutter pub get

# 3. Executar em modo Web (Google Chrome)
flutter run -d chrome

# (Opcional) Executar como aplicativo Desktop no macOS:
flutter run -d macos
```

---

### 🔍 Passo 3: Análise Estática e Qualidade de Código
O projeto segue regras rigorosas de linting:
```bash
flutter analyze
```

---

## 🤖 5. Engenharia de IA e Rastreabilidade

O projeto foi inteiramente concebido utilizando práticas modernas de engenharia com agentes de inteligência artificial:

* **Diretrizes e Regras de Contexto:** [`.antigravity/AGENTS.md`](.antigravity/AGENTS.md) padroniza as regras de arquitetura, isolamento do GetX e proibição de dados reais.
* **Especificação Técnica Detalhada:** [`docs/especificacao.md`](docs/especificacao.md) detalha o racional arquitetural e decisões de produto.
* **Registro Integral de Prompts:** A pasta [`docs/prompts/`](docs/prompts/) contém o log cronológico e sem edições de todas as iterações de desenvolvimento com a IA:
  * [`1-arch+listagem-clientes.md`](docs/prompts/1-arch+listagem-clientes.md): Arquitetura base, repositórios e listagem de clientes.
  * [`2-form-cliente+upload+splitview.md`](docs/prompts/2-form-cliente+upload+splitview.md): Formulário de cliente, dropzone em lote e split view de conferência.
  * [`3-ajustes-form-e-conferencia.md`](docs/prompts/3-ajustes-form-e-conferencia.md): Select de tipos, formatação de datas e padronização de nomenclatura.
  * [`4-fix-texteditingcontroller-disposed.md`](docs/prompts/4-fix-texteditingcontroller-disposed.md): Diagnóstico e correção de ciclo de vida de controllers no GetX.
  * [`5-mock-pdf-image-viewer-support.md`](docs/prompts/5-mock-pdf-image-viewer-support.md): Gerador autônomo de PDFs jurídicos e suporte a bytes em memória.
  * [`6-fatores-naturais.md`](docs/prompts/6-fatores-naturais.md): Implementação de Hash SHA-256 e controle de concorrência 409.
  * [`7-remove-duplicate-tipology-warning.md`](docs/prompts/7-remove-duplicate-tipology-warning.md): Refinamento da regra de negócio para múltiplas instâncias da mesma tipologia.

---

## 📁 6. Estrutura de Pastas do Projeto

```
lib/app/
├── bindings/             # Injeção de Dependências GetX (ClientListBinding, ClientFormBinding)
├── controllers/          # Gerência de Estado Reativo (ClientListController, ClientFormController)
├── core/
│   ├── app_theme.dart    # Design System escuro/dourado moderno (Legal Tech)
│   ├── errors/           # Exceções de domínio (ConflictException, NotFoundException)
│   └── routes/           # Rotas nomeadas (AppPages, AppRoutes)
├── domain/models/        # Entidades Imutáveis (ClientModel, DocumentModel, PaginatedResult)
├── repository/           # Contratos abstratos e Implementações Mock/Memória
└── ui/
    ├── pages/            # Telas principais (ClientListPage, ClientFormPage)
    └── widgets/          # Componentes modulares (DocumentDropzone, DocumentSplitView, etc.)
```


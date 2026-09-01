# Especificação Técnica e Decisões de Arquitetura — DOC Intelligence (Trilha B: Front-end)

Este documento descreve a especificação funcional e arquitetural do **DOC Intelligence**, o racional por trás das decisões de modelagem e design de interface, e como a solução endereça as restrições reais e requisitos definidos no desafio de inteligência documental.

---

## 1. Visão Geral do Produto e Problema

O escritório de advocacia recebe diariamente centenas de documentos (identidades, comprovantes de residência, contracheques, certidões, laudos, procurações e contratos) através do WhatsApp do atendimento, e-mails e balcão físico. O fluxo manual anterior exigia abrir cada arquivo, renomeá-lo em padrão interno e digitar os dados em planilhas (uma média de 4 minutos por documento).

O **DOC Intelligence** substitui essa fricção por um **serviço de esteira inteligente**:
1. **Recepção em Lote:** O atendimento seleciona ou arrasta múltiplos arquivos de uma vez.
2. **Classificação e Extração por IA:** A inteligência artificial infere a tipologia documental, extrai campos-chave e sugere um nome padronizado.
3. **Conferência Humana (Split View):** Quando a máquina processa o arquivo, o documento entra no estado *"Aguardando Conferência"*, permitindo que o conferente visualize o documento original lado a lado com os campos sugeridos para rápida validação ou correção.
4. **Governança e Consulta:** Os documentos ficam vinculados ao cadastro do cliente/titular, indexados e prontos para consumo pelos sistemas jurídicos internos.

---

## 2. Decisão Arquitetural: Listagem e Agregação por Cliente / Usuário

Uma das decisões estruturais do projeto foi modelar a entidade **Cliente (`ClientModel`)** como raiz de agregação (*Aggregate Root*) para os documentos (`DocumentModel`), em vez de tratar arquivos como itens soltos numa fila anônima.

### 🌟 Vantagens da Estruturação por Cliente

1. **Contexto Jurídico e Conformidade LGPD (Dados Pessoais Sensíveis):**
   - No direito, documentos não existem descontextualizados; pertencem a um titular com CPF, RG e qualificação civil.
   - Agrupar os anexos por cliente garante isolamento de dados pessoais, rastreabilidade clara de quem é o titular e evita cruzamento indevido de informações confidenciais entre clientes homônimos.

2. **Dossiê Digital Unificado e Rastreabilidade:**
   - O atendente e os advogados conseguem consultar o dossiê documental completo de uma pessoa em um único lugar (quantos documentos foram enviados, quantos já foram conferidos e quais ainda estão pendentes).
   - Facilita a auditoria de completude documental para petições iniciais (ex.: verificar se o cliente já enviou RG, comprovante de residência e procuração).

3. **Validação Inteligente de Duplicatas (Hash Criptográfico) no Escopo do Cliente:**
   - Evita falsos positivos globais: um documento de rescisão pode ter estrutura parecida com outro, mas pertencer a clientes diferentes. O hash binário SHA-256 garante precisão matemática.
   - **Suporte a Múltiplos Anexos da Mesma Tipologia:** Clientes podem legitimamente anexar múltiplos contratos, comprovantes de residência de meses diferentes ou certidões distintas. O sistema permite coexistência de vários documentos do mesmo tipo, focando a restrição de duplicidade no conteúdo binário real do arquivo.

4. **Integração Natural com Sistemas Internos do Escritório (Item 5 do Desafio):**
   - Conforme o requisito de integração interna, os ERPs jurídicos e sistemas de processo eletrônico indexam peças por **Parte / Cliente / Processo**.
   - Ter a listagem de clientes expõe endpoints e modelos de dados perfeitamente compatíveis com as APIs legadas e futuras do escritório (`/clients`, `/clients/{id}/documents`).

5. **Distribuição de Trabalho e Atribuição:**
   - Permite que o escritório distribua carteiras de clientes entre atendentes específicos, mantendo a fila organizada mesmo em picos de demanda.

---

## 3. Aderência aos Fatos do Ambiente e Requisitos do Desafio

Abaixo detalhamos como a implementação responde diretamente a cada um dos fatos reais levantados na especificação do desafio:

### a) IA Multimodal de Terceiro: Latência (5 a 40s), Custo por Chamada e Instabilidade
* **Como foi resolvido na Interface:**
  - **Fluxo Não-Bloqueante:** O envio e o processamento ocorrem em segundo plano com indicador de progresso percentual e timer assíncrono na Split View.
  - **Proteção de Custos da API:** Assim que o documento é aprovado pelo conferente (`status: reviewed`), os botões *"Processar com IA"* e *"Aprovar"* são **desabilitados**, impedindo reprocessamentos acidentais tarifados.
  - **Tolerância a Falhas:** Se o modelo externo falhar ou demorar excessivamente, o documento recebe o status `error` com mensagem explicativa e opção de retry manual, preservando o arquivo original intacto no sistema.

### b) Origem Mobile/Atendimento: Nomes Sujos ("WhatsApp Image...", "scan0001.pdf") e Sem Validação
* **Como foi resolvido na Interface:**
  - **Preservação do Nome Original:** O nome bruto do arquivo (`originalName`) é mantido em campo somente leitura para auditoria e conferência com a fonte enviada pelo cliente.
  - **Padronização Automática:** O sistema propõe o `standardizedName` seguindo a convenção corporativa:
    $$\text{[TIPO\_DOCUMENTO]}\_\text{[PRIMEIRO\_NOME\_CLIENTE]}\_\text{[DATA\_ENVIO]}.\text{[extensao]}$$
    com sanitização automática de caracteres especiais, espaços e acentuação gráfica.
  - **Visualizador Híbrido:** Dropzone e Split View suportam tanto arquivos PDF (via renderização vetorial com PDF.js e `SyncfusionPdfViewer`) quanto imagens brutas de câmera (JPEG, PNG).

### c) Reenvio Frequente de Documentos Duplicados
* **Como foi resolvido na Interface:**
  - **Impressão Digital Criptográfica (Hash SHA-256):** Ao selecionar arquivos, o sistema calcula o hash binário (`Uint8List`) de cada item.
  - **Detecção na Fila de Upload:** Arquivos idênticos já enviados para o cliente ou repetidos no mesmo lote recebem o badge visual **`DUPLICADO`** com destaque âmbar.
  - **Ação Rápida:** Botão *"Remover Duplicatas"* permite expurgar arquivos redundantes com 1 clique antes do envio.
  - **Flexibilidade de Tipologia:** Permite múltiplos anexos de um mesmo tipo (ex.: 3 contratos diferentes), validando apenas duplicatas com idêntico conteúdo ou nome/tamanho.

### d) Dados Pessoais e Pessoais Sensíveis (LGPD)
* **Como foi resolvido na Interface:**
  - **Dados 100% Sintéticos / Fictícios:** O ambiente de mock e desenvolvimento utiliza exclusivamente nomes, CPFs, RGs e cidades de teste fictícias.
  - **Mascaramento e Imutabilidade:** Campos formatados (CPF: `000.000.000-00`, Data: `dd/MM/yyyy`) e bloqueio de edição após aprovação formal da conferência.

### e) Picos de Volume (150 a 800+ docs/dia, concentrados das 9h às 11h)
* **Como foi resolvido na Interface:**
  - **Fila em Lote (*Batch Upload*):** Permite arrastar ou selecionar dezenas de arquivos simultaneamente.
  - **Acompanhamento por Item:** Lista reativa com status individual (`queued` → `uploading` → `done` / `error`).
  - **Listagem Paginada e Debounce:** A listagem de clientes implementa paginação configurável (10, 25, 50 itens) com busca textual otimizada por debounce.

### f) Troca de Versão do Modelo e Evolução de Prompts
* **Como foi resolvido na Interface:**
  - **Padrão Repository (Clean Architecture):** A camada de apresentação depende apenas do contrato abstrato `DocumentRepository`. Se o backend ou o provedor de IA mudar, a UI não sofre impacto.
  - **Payload Flexível com Fallback:** Os dados extraídos são mapeados defensivamente com categorias padronizadas (`documentTypes`) e opção segura `'Outros'`.

### g) Concorrência entre Múltiplos Atendentes (*Race Conditions*)
* **Como foi resolvido na Interface:**
  - **Bloqueio Otimista (*Optimistic Locking*):** Documentos possuem controle de versão (`version`) e data de modificação (`updatedAt`).
  - **Tratamento HTTP 409 Conflict:** Caso dois revisores abram o mesmo documento e um deles salve primeiro, a tentativa de regravação subsequente intercepta o `ConflictException` e abre um modal informativo permitindo **"Recarregar Dados"**, eliminando o risco de sobrescrita cega (*Lost Update*).
  - **Botão de Simulação 409:** Adicionado no cabeçalho para permitir a demonstração e teste do fluxo de concorrência em tempo real.

---

## 4. Arquitetura de Software do Front-end

A aplicação foi desenvolvida em **Flutter Web / Desktop** com gerenciamento de estado via **GetX**, estruturada nas seguintes camadas:

```
lib/app/
├── bindings/             # Injeção de Dependências (ClientListBinding, ClientFormBinding)
├── controllers/          # Gerenciamento de Estado Reativo (ClientListController, ClientFormController)
├── core/
│   ├── app_theme.dart    # Design System escuro/moderno (Paleta Charcoal, Slate & Emerald)
│   ├── errors/           # Exceções unificadas (ConflictException, NotFoundException)
│   └── routes/           # Rotas nomeadas (AppPages, AppRoutes)
├── domain/models/        # Entidades Imutáveis (ClientModel, DocumentModel, PaginatedResult)
├── repository/           # Contratos abstratos e Implementações Mock/Remote
└── ui/
    ├── pages/            # Telas principais (ClientListPage, ClientFormPage)
    └── widgets/          # Componentes reutilizáveis (DocumentDropzone, DocumentSplitView, etc.)
```

### Componentes Principais:
* **`ClientListPage`:** Tabela de clientes com busca, paginação, contagem de documentos e ações de navegação rápida.
* **`ClientFormPage`:** Interface com 3 abas organizadas:
  1. *Aba 1 (Dados do Cliente):* Formulário com validação de campos cadastrais.
  2. *Aba 2 (Upload de Documentos):* Dropzone com cálculo de hash SHA-256, detecção de duplicatas e listagem reativa imediata.
  3. *Aba 3 (Conferência Split View):* Carrossel de seleção de documentos, visualizador de PDF/imagem e formulário de dados extraídos com controle de concorrência.

---

## 5. Estratégia de Testes Automatizados

O projeto conta com uma suíte de testes em `test/` validando os fluxos críticos de negócio:
* **`test/concurrency_and_duplicates_test.dart`:**
  - Cálculo de hash SHA-256.
  - Identificação e bloqueio de arquivos duplicados na fila.
  - Lançamento e captura de `ConflictException` (HTTP 409).
* **`test/mock_document_generator_test.dart`:** Geração de PDFs vetoriais sem erros de codificação de fontes.
* **`test/widget_test.dart`:** Teste de fumaça da interface e renderização inicial.

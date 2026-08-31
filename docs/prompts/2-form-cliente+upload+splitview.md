# O QUE FOI FEITO PELA IA

Implementação completa do Formulário de Cliente com suporte a cadastro/edição, upload de documentos (único ou em lote via Dropzone e File Picker), simulação de latência de processamento por IA e Split View de conferência documental.

──────
### 📂 Arquitetura e Arquivos Implementados

#### 1. Domínio & Modelos (Isolados do GetX)
• `document_model.dart`: Modelo `DocumentModel` com status (`pending`, `uploading`, `processing`, `reviewed`, `error`), tamanho formatado, nome original sujo, nome padronizado sugerido pela IA e mapa de dados extraídos (`extractedData`).
• `client_model.dart`: Mantém campos de identificação (Nome, Cidade, CPF, RG, contagem de documentos).

#### 2. Camada de Repositório (Desacoplada)
• `document_repository.dart`: Interface abstrata com métodos `getDocumentsByClientId`, `uploadDocument`, `processDocument`, `updateDocument` e `deleteDocument`.
• `mock_document_repository.dart`: Mock em memória com documentos pré-carregados, simulação de latência de IA (4s) e inferência de nomes padronizados e tipologia documental.

#### 3. Gerência de Estado & DI (GetX)
• `client_form_controller.dart`: Controlador com `TabController` (3 abas), validação de formulário com `GlobalKey<FormState>`, máscara de CPF, gerenciamento de fila de upload em lote (`DocumentUploadItem`), seleção de documento para conferência, controle de progresso de IA e tratamento de `ConflictException` (409).
• `client_form_binding.dart`: Registra as dependências do `DocumentRepository` e `ClientFormController`.

#### 4. UI & Apresentação (Desktop / Web First com Tema Escuro & Dourado)
• `document_dropzone.dart`: Componente interativo com `desktop_drop` e `file_picker` com feedback visual de arrastar e soltar, fila de upload com progresso e remoção prévia.
• `document_split_view.dart`: Layout dividido (lado esquerdo: visualizador PDF com `syncfusion_flutter_pdfviewer` / imagens; lado direito: dados extraídos pela IA, barra de progresso de processamento, edição de nome padronizado e ações de aprovação/exclusão).
• `client_form_page.dart`: Página principal unificada em 3 abas ("1. Dados do Cliente", "2. Upload de Documentos", "3. Conferência (Split View)") com carrossel horizontal de seleção de documentos e transição fluida.
• `app_pages.dart`: Rotas `/clients/form` e `/clients/details` configuradas com `ClientFormBinding`.

──────
### 🧪 Validações Realizadas
• `flutter analyze`: 0 issues / avisos.
• `flutter test`: Testes executados com sucesso.

# COMENTARIOS DO DESENVOLVEDOR
- O campo Tipo de documento deve ser do tipo select com opções ja predefinidas como: identidade, cnh, comprovante de residencia, laudos, procurações, etc...
- Para documentos ja processados pela IA, eles devem ir para o status "aguardando conferencia" e apos isso "conferido"
- Em casos do status "conferido" desabilitar os botoes de conferir e analisar com IA.
- Formate a data do documento para o padrao dd/mm/yyyy
- Para o nome padronizado utilize o tipo de documento + o primeiro nome do cliente mais a data de envio
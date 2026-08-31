# O QUE FOI FEITO PELA IA

Implementação dos ajustes no formulário de cliente e split view de conferência documental:

──────
### 📂 Detalhamento das Alterações

#### 1. Tipo de Documento como Select com Opções Predefinidas
• Modificado o campo de tipo de documento em `DocumentSplitView` para um `DropdownButtonFormField<String>`.
• Lista com opções: `'Identidade (RG)'`, `'CNH'`, `'Comprovante de Residência'`, `'Laudo Médico / Pericial'`, `'Procuração'`, `'Contrato'`, `'Certidão'`, `'Outros'`.
• Ao trocar a seleção, o nome padronizado sugerido é recalculado automaticamente.

#### 2. Fluxo de Status: "Aguardando Conferência" e "Conferido"
• Atualizado o `DocumentStatus` em `document_model.dart` adicionando o estado `awaitingReview` ("Aguardando Conferência").
• Documentos processados pela IA passam automaticamente do status `processing` para `awaitingReview`.
• Ao clicar em "Aprovar Conferência", o documento é atualizado para o status `reviewed` ("Conferido").

#### 3. Desabilitação de Ações em Documentos "Conferido"
• Quando o documento está no status `reviewed`, os botões "Analisar com IA" e "Aprovar Conferência" são desabilitados.
• O botão de aprovação exibe o estado "Conferido" com ícone de confirmação.
• Campos de edição ficam protegidos contra alterações acidentais.

#### 4. Formatação de Data no Padrão `dd/MM/yyyy`
• Adicionada máscara e formatação `_DateMaskFormatter` (`dd/mm/aaaa`) no campo de data do documento.
• As datas inferidas pela IA e carregadas no mock agora seguem o padrão brasileiro (`dd/MM/yyyy`).

#### 5. Regra de Nomenclatura Padronizada
• Implementada a função `generateStandardizedName` no `ClientFormController`:
  - Formato: `[TIPO_DOCUMENTO]_[PRIMEIRO_NOME]_[DATA_ENVIO].[extensao]`
  - Exemplo: `PROCURACAO_JOAO_31_08_2026.pdf` ou `COMPROVANTE_RESIDENCIA_MARIA_31_08_2026.png`.

──────
### 🧪 Validações Realizadas
• `flutter analyze`: 0 issues / avisos.
• `flutter test`: 100% de sucesso.

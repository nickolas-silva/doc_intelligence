# O QUE FOI FEITO PELA IA

Implementação completa dos mecanismos de controle de concorrência (Optimistic Locking / HTTP 409 Conflict) e detecção de duplicatas (Hash SHA-256 e Tipologia Jurídica).

──────
### 📂 Detalhamento das Alterações

#### 1. Detecção de Documentos Duplicados
• **Cálculo de Hash SHA-256:** Ao selecionar ou arrastar arquivos, o `ClientFormController` calcula o hash SHA-256 do conteúdo binário (`Uint8List`) de cada item.
• **Validação na Fila de Upload:** Identifica se o arquivo já existe nos documentos do cliente ou se está repetido na própria fila.
• **Interface de Alerta:**
  - O item na fila recebe o badge `"DUPLICADO"` e uma borda âmbar informativa com o motivo.
  - Ação rápida `"Remover Duplicatas"` para limpar automaticamente arquivos redundantes com um único clique.
• **Alerta de Tipologia Jurídica Repetida:** Na SplitView de conferência, se o tipo de documento selecionado já estiver cadastrado em outro documento do mesmo cliente (ex: duas Procurações), um banner de atenção é exibido no topo do formulário.

#### 2. Controle de Concorrência (HTTP 409 Conflict)
• **Versionamento e Optimistic Locking:** Adicionados os campos `version` e `updatedAt` no `DocumentModel` e `ClientModel`.
• **Tratamento de Exceções Unificado:** Criado `AppExceptions` com `ConflictException` e `NotFoundException`.
• **Modal Interativo de Conflito 409:** Ao ocorrer uma alteração concorrente por outro usuário/revisor, a aplicação exibe um diálogo com o botão `"Recarregar Dados"`, sincronizando a versão mais recente sem quebrar a sessão.
• **Botão de Teste no Cabeçalho:** Adicionado o botão `"Testar Conflito 409"` no topo do formulário do cliente para permitir validar e demonstrar o fluxo de concorrência a qualquer momento.

──────
### 🧪 Validações Realizadas
• Criado teste automatizado completo em `test/concurrency_and_duplicates_test.dart`.
• `flutter test`: 100% de sucesso em todos os testes.
• `flutter analyze`: 0 issues / avisos.

# COMENTARIOS DO DESENVOLVEDOR
- Remover validação desnecessaria de tipo de documento, pois usuarios podem ter mais de um documento com o mesmo tipo
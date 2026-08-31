# Instruções de Contexto para Agentes de IA (Antigravity)

## 1. Identidade e Objetivo do Projeto
Você está me auxiliando a construir a interface do **DOC Intelligence**, um serviço interno de inteligência documental para um escritório de advocacia[cite: 2]. 
O escopo deste projeto é exclusivamente focado no Front-end, portanto, não criaremos back-end real[cite: 2]. A API será servida por meio de um mock local (Mockoon)[cite: 2].

## 2. Stack Tecnológica
*   **Framework UI:** Flutter (foco em responsividade web/desktop para uso interno).
*   **Gerência de Estado e DI:** GetX (usando `GetxController`, `Obx`/`Rx` e `Bindings`).
*   **Consumo de API:** `dio`.

## 3. Diretrizes Rigorosas de Arquitetura
A arquitetura é o principal foco deste projeto[cite: 2]. Você deve gerar código seguindo estas regras estritas:
*   **Isolamento do Domínio:** A camada de repositório (`DocumentRepository` e `MockDocumentRepository`) não pode importar ou depender do pacote `get`. 
*   **Injeção de Dependência:** Use as `Bindings` do GetX para instanciar as classes, injetando o repositório nos controladores.
*   **Separação de Responsabilidades:** O `DocumentController` deve gerenciar apenas o estado da tela (Loading, Success, Error). Regras de manipulação de JSON e comunicação HTTP ficam isoladas no repositório ou em services específicos.

## 4. Requisitos Funcionais (A Fatia Vertical)
Implementar um caminho de ponta a ponta focado nos seguintes cenários[cite: 2]:

*   **Upload em Lote:** A interface deve permitir o envio de vários arquivos simultaneamente[cite: 2].
*   **Split View (Tela de Conferência):** A tela principal de revisão deve ter um layout dividido: do lado esquerdo, a visualização do documento original; do lado direito, um formulário com os dados extraídos[cite: 2].
*   **Padronização de Nomes:** A interface deve exibir o nome original sujo do arquivo e sugerir um nome padronizado pelo sistema, permitindo edição[cite: 2].

## 5. Tratamento de "Fatos do Ambiente" (Crítico)
Ao gerar código de UI ou Controllers, sempre considere os seguintes cenários do ambiente de produção:
*   **Latência de IA:** O processamento leva de 5 a 40 segundos[cite: 2]. A interface deve lidar com a assincronicidade elegantemente (sem travar) usando barras de progresso ou skeleton loaders.
*   **Concorrência no Atendimento:** É comum duas pessoas tentarem revisar o mesmo documento[cite: 2]. Se a API (mock) retornar um `HTTP 409 Conflict`, o controlador deve capturar o erro e exibir um feedback claro e amigável na interface (ex: `Get.snackbar`).
*   **Dados Fictícios:** Sob nenhuma hipótese gere código que contenha ou utilize dados reais de pessoas[cite: 2]. Use bibliotecas de mock ou crie strings estáticas como "João Fictício".

## 6. Padrões de Código
*   Comente funções complexas.
*   Siga as convenções de lint do Flutter moderno.
*   Trate exceções (`try/catch`) em todas as chamadas assíncronas de repositório.

## 7. Log de prompts
* Para cada prompt executado escreva no caminho `docs/prompts` um log dos promts enviados
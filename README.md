Monitoramento de Servidor com PowerShell
📌 Visão Geral

Este projeto implementa uma solução de monitoramento de servidor Windows utilizando PowerShell, com foco em automação e conceitos de infraestrutura.
O script realiza a coleta de métricas do sistema, armazena os dados em um banco MySQL e envia notificações em tempo real por Discord ou Telegram.

A proposta do projeto é simular um cenário real de ambiente corporativo, unindo script, agendamento de tarefas, banco de dados e integração com serviços externos.

* ⚙️ Funcionalidades
* Coleta automática de:
* Uso de CPU
* Uso de memória (RAM)
* Uso de disco (C:)
* Identificação do nome do servidor e endereço IP
* Persistência de dados em banco MySQL
* Notificações em tempo real via:
* Discord (Webhook)
* Alertas baseados em limites configuráveis
* Execução automatizada através do Windows Task Scheduler

🛠 Tecnologias Utilizadas

* PowerShell
* MySQL
* Discord Webhooks
* Windows Task Scheduler
* Git / GitHub

🏗 Arquitetura do Projeto

* O script em PowerShell coleta as métricas do sistema.
* As informações do servidor e as métricas são armazenadas no MySQL.
* Alertas e mensagens de status são enviados para Discord ou Telegram.
* O processo é executado automaticamente em intervalos definidos pelo Agendador de Tarefas.

▶️ Funcionamento

* O script é executado periodicamente (recomendado: a cada 5 minutos).
* As métricas são gravadas no banco para histórico e análise futura.
* Caso algum limite seja ultrapassado, um alerta é enviado automaticamente.
* O projeto pode ser facilmente expandido para dashboards ou novas métricas.

🔐 Observações de Segurança

* Credenciais de banco de dados e URLs de webhook não estão versionadas no repositório.
* Informações sensíveis devem ser definidas via variáveis de ambiente.
* O código disponibilizado contém apenas exemplos de configuração.

🎯 Objetivo do Projeto

Este projeto foi desenvolvido com o objetivo de demonstrar conhecimentos em:

* Automação de infraestrutura
* Scripting em PowerShell
* Administração de ambientes Windows
* Integração com serviços externos
* Monitoramento e alertas

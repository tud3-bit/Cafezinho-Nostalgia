# Cafezinho da Nostalgia – Lan "hause" (Windows XP Edition)

Bem-vindo ao **Cafezinho da Nostalgia**, um sistema de gestão de LAN House com uma interface nostálgica baseada no design clássico do **Windows XP (Luna)**. Este projeto foi desenvolvido para unir a praticidade de um painel de controle moderno com a estética icônica dos anos 2000.

## 🚀 Funcionalidades

* **Dashboard em Tempo Real:** Monitoramento visual do status de todos os PCs da rede.
* **Gestão de Sessões:** Abertura e fechamento de sessões com cálculo automático de valores.
* **Controle de Clientes:** Cadastro e ranking dos usuários mais assíduos.
* **Controle de Estoque:** Registro de vendas de produtos vinculadas às sessões ativas.
* **Caixa:** Relatórios de entradas, saídas e saldo final.

## 🎨 Design & Estilo
O painel foi construído sem dependências de frameworks CSS modernos (como o Bootstrap), utilizando CSS puro para replicar:
* Barra de tarefas clássica com "Menu Iniciar".
* Janelas com bordas chanfradas e gradientes característicos do Windows XP.
* Ícones e estados de computador (Disponível/Ocupado/Manutenção).

## 🛠️ Tecnologias Utilizadas
* **Front-end:** HTML5, CSS3 (Custom Properties) e JavaScript (Vanilla).
* **Back-end:** Node.js
* **API:** Integração via `fetch` para comunicação com o banco de dados.

## 📋 Como Executar

* docker compose up --build -d → INICIA A APLICAÇÃO DO CONTAINER EM MODO DETALHADO
* docker compose logs -f → FAZ A LEITURA DAS LOGS DO BD
* docker compose ps → FAZ A LEITURA DA APLICAÇÃO
* docker compose down → ENCERRA A APLICAÇÃO
  
👥 Equipe de Desenvolvimento
Este projeto foi desenvolvido colaborativamente por:

*Emmanuelle Talita Geraldo Ferreira da Silva

*Matheus Vinicius Coelho de Souza

*Hiago Souza Tude

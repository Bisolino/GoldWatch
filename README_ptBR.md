# GoldWatch - Rastreador de Ouro para WoW

**GoldWatch** é um addon para World of Warcraft que rastreia em tempo real o ouro que você ganha durante suas sessões de farm. Ele calcula seu ganho por hora (GPH) e fornece projeções precisas, além de incluir um sistema inteligente para detectar situações de "hyperspawn" (respawn anormalmente rápido de monstros).

## 📥 Instalação
1. Baixe a última versão
2. Extraia a pasta `GoldWatch` na pasta `Interface\AddOns` do seu WoW
3. Inicie ou reinicie o WoW

## 🚀 Como Começar
1. **Abra o addon**: Digite `/gw` ou clique no ícone do minimapa
2. **Entre na masmorra**: Vá para onde deseja farmar
3. **Inicie o rastreamento**: Clique em `Iniciar`
4. **Farme normalmente**: Mate monstros, colete saques, complete missões
5. **Venda para NPCs**: Venda todos os itens farmados para NPCs
6. **Pare o rastreamento**: Clique em `Parar` quando terminar

## ⚙️ Funcionalidades Principais
| Recurso | Descrição |
|---------|-----------|
| 📊 Rastreamento em Tempo Real | Monitora cada peça de ouro ganha |
| ⏱️ Projeção de 60 Minutos | Estima quanto ganharia em 1 hora no ritmo atual |
| 🗺️ Dados por Masmorra | Aprende seu GPH médio em cada local |
| 🚨 Sistema Anti-Hyperspawn | Detecta ganhos anormais e age automaticamente |
| 📜 Histórico Completo | Armazena todas as sessões com detalhes |

## 🚨 Sistema Anti-Hyperspawn
**O que é hyperspawn?**  
Quando monstros respawnam muito rápido, gerando ganhos irreais. O GoldWatch detecta isso comparando seu GPH atual com a média histórica.

**Modos de operação:**
- 🔔 `Alerta`: Notifica com som/texto (padrão)
- 📉 `Ajuste`: Reduz ganhos em 30% para valores realistas
- ⏸️ `Pausa`: Para o rastreamento por 10 minutos

Configure em: `/gw config`

## 💻 Comandos Úteis
| Comando | Função |
|---------|--------|
| `/gw` | Abre/fecha a janela principal |
| `/gw config` | Abre as configurações |
| `/gw summary` | Mostra resumo da sessão no chat |
| `/gw reset` | Reinicia a sessão atual |
| `/zd` | Mostra dados da masmorra atual |
| `/gw history` | Abre histórico gráfico |

## ❓ Perguntas Frequentes

### 1. O que é o GoldWatch?
R: Um addon que rastreia seu ouro em tempo real durante sessões de farm, mostrando quanto você ganha por hora.

### 2. Como inicio o rastreamento?
R: Entre na masmorra e clique em `Iniciar` na janela principal.

### 3. O addon conta vendas na casa de leilões?
R: Não, apenas saques, vendas a NPCs e recompensas de missões.

### 4. O que é o Anti-Hyperspawn?
R: Um sistema que detecta quando monstros respawnam rápido demais e ajusta os valores.

### 5. Como vejo meu histórico?
R: Use `/gw history` ou clique no botão `Histórico`.

### 6. Meus dados são salvos?
R: Sim, localmente na pasta `WTF\Account\<sua conta>\SavedVariables`.

### 7. Funciona com múltiplos personagens?
R: Sim! Dados de aprendizado são compartilhados, mas sessões são individuais.

### 8. Lista de todos os comandos
| Comando | Função |
|---------|--------|
| /gw | Abre/fecha a janela principal
| /goldwatch | Alternativa para abrir/fechar a janela principal
| /gw config | Abre as configurações do addon
| /gw summary | Mostra resumo da sessão atual no chat
| /gw summary all | Mostra histórico completo de sessões no chat
| /gw reset | Reinicia a sessão atual (dados em andamento)
| /gw reset data | Apaga dados de aprendizado (médias de masmorra)
| /gw reset all | Apaga TODOS os dados do addon (requer confirmação)
| /gw history | Abre o histórico de sessões
| /zd | Mostra dados da masmorra atual (GPH médio, amostras)
| /zd all | Mostra dados de todas as masmorras registradas

---

### Soporte e Atualizações
**Autor**: Levindo  
**Versão**: 1.0.0  
**Compatível com**: WoW Retail (v10.0+)
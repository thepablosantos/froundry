ZKVerifyDeFi - README
ZKVerifyDeFi

Visão Geral

ZKVerifyDeFi é um contrato inteligente desenvolvido para participação em um hackathon da ZKVerify. Ele oferece uma plataforma simples e segura para investidores amadores entrarem em pools de liquidez com níveis de risco definidos (baixo, médio e alto), utilizando proteção de privacidade com zk-SNARKs, integração com Chainlink para APY dinâmico e funções como recompensas compostas, retirada parcial e commit-reveal contra front-running.

------------------------------

Funcionalidades

- Criação de pools com diferentes níveis de risco
- Sistema de commit-reveal para depósito protegido
- Saques com proteção de identidade (ZK)
- Recompensas compostas (APY)
- Cálculo dinâmico de rendimento com Chainlink
- Retirada parcial de fundos
- Integração com tokens ERC-20
- Sistema de verificação com zk-SNARKs (mock para testes)
- Simples de usar para usuários leigos

------------------------------

Estrutura

Pool
- Token da pool (ERC20)
- Verificador ZK (mock ou real)
- Total depositado
- Depósitos individuais por endereço

Funções principais
- `createPool`: cria nova pool
- `commitDeposit`: usuário inicia um depósito com hash
- `revealDeposit`: revela o valor e efetiva o depósito
- `withdraw`: realiza o saque total com verificação ZK
- `partialWithdraw`: realiza um saque parcial
- `calculateAPY`: retorna APY simulado com Chainlink

------------------------------

Segurança

- Proteção contra front-running (commit-reveal)
- Verificação ZK para anonimato
- Apenas o usuário pode sacar seus fundos
- Chainlink para dados de rendimento seguros

------------------------------

Como usar

1. Crie uma pool com `createPool`
2. Usuário chama `commitDeposit(hash)`
3. Usuário chama `revealDeposit(value, salt)` com a prova
4. Pode sacar total ou parcialmente

------------------------------

Testes com Foundry

O projeto inclui testes em `test/ZKVerifyDeFi.t.sol` e simula o token ERC20 em `MockERC20.sol`. Para rodar os testes:

```bash
forge test
```

------------------------------

Considerações

Este contrato é voltado para testes em testnet e demonstração do conceito de uma plataforma DeFi amigável, segura e acessível a todos.

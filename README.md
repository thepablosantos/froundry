# zkVerify DeFi Protocol

Este projeto é uma aplicação DeFi construída para o hackaton da zkVerify. O objetivo é fornecer uma plataforma simplificada para investidores tradicionais aplicarem seus fundos em pools de liquidez com diferentes níveis de risco, integrando privacidade com zkVerify, segurança contra ataques como front-running e yield dinâmico com Chainlink.

## Funcionalidades

- Registro de investimentos em pools via carteira conectada (zkVerify).
- Suporte a tokens ERC-20 e ETH.
- Retirada total ou parcial de investimentos.
- Proteção contra front-running com esquema commit-reveal.
- Cálculo de yield dinâmico com Chainlink (APR e APY compostos).
- Restrições de saque (apenas quem investiu pode sacar).
- Transparência com logs de eventos.
- Adaptado para ser executado na testnet.

## Estrutura do Projeto

```
zkverify-defi/
├── src/
│   └── zkVerifyDeFi.sol
├── test/
│   └── zkVerifyDeFi.t.sol
├── lib/
├── foundry.toml
└── README.md
```

## Uso com Foundry

### 1. Instale o Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Clone e instale dependências

```bash
git clone https://github.com/seuusuario/zkverify-defi.git
cd zkverify-defi
forge install
```

### 3. Execute os testes

```bash
forge test
```

## Variáveis Importantes no Contrato

- `investors`: Mapeamento de quem investiu e quanto.
- `commits`: Proteção contra front-running usando commit-reveal.
- `apy`: Valor anual de rendimento com base em Chainlink.
- `rewards`: Armazena recompensas de cada investidor.

## Fluxo de Investimento

1. O usuário realiza `commitInvestment(hash)`.
2. Após o delay, chama `revealInvestment(value, tokenAddress, poolId)`.
3. O contrato valida o hash e registra o investimento.
4. O usuário pode visualizar `getYield` e realizar `partialWithdraw` ou `withdraw` total.

## Como são escolhidas as melhores pools?

Por trás, o frontend coleta via API:

- TVL
- Volume diário
- Histórico de rendimento (APR/APY)
- Relação risco: stable/stable, alt/stable, alt/alt

E apresenta de forma simplificada (baixo, médio e alto risco).

## Segurança

- **Commit-reveal**: Protege contra front-running.
- **Only investor**: Apenas quem investiu pode sacar.
- **zkVerify**: Integração com sistema de verificação anônima para proteger a identidade do investidor.
- **Chainlink**: Usa oráculo para garantir dados externos confiáveis de APY.

---

Desenvolvido para o hackaton da zkVerify. Testado com Foundry. Qualquer dúvida, entre em contato com os desenvolvedores.
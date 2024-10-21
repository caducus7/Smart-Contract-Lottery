# Smart Contract Lottery

A decentralized lottery system built using smart contracts, developed with [Foundry](https://getfoundry.sh/). The project allows users to enter a lottery, and a winner is chosen randomly through blockchain-based events.

## Features

- Ethereum smart contracts for managing lottery entries and rewards.
- Random selection of the lottery winner.
- Built with Solidity and tested with Foundry.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/caducus7/Smart-Contract-Lottery.git
   ```

2. Install Foundry:
   - Download and install Foundry:
     ```bash
     curl -L https://foundry.paradigm.xyz | bash
     ```
   - Initialize Foundry:
     ```bash
     foundryup
     ```

## Usage

### Build the project:

```bash
forge build
```

### Run tests:

```bash
forge test
```

### Deploy:

```bash
forge script script/DeployStuff.s.sol:DeployStuff --broadcast --rpc-url <RPC_URL>  --private-key <PRIVATE_KEY> -vvv
```

## Resources

Foundry Documentation: https://book.getfoundry.sh/

## License

This project is offered under [MIT](LICENSE-MIT) license.

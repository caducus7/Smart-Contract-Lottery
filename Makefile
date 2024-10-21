-include .env
.PHONY: all test clean deploy fund help install snapshot format anvil
help:
    @echo "Usage:"
    @echo " make deploy [ARGS=...]"

build:; forge build
install:; forge install Cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.0 --no-commit && forge install transmissions11/solmate@v6 --no-commit
test :; forge test 
deploy-sepolia :
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

    
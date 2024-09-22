import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
// import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
    solidity: {
        settings: {
            viaIR: true,
            optimizer: {
                enabled: true,
                runs: 1000,
            },
        },
        version: "0.8.20",
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
    },
    networks: {
        hardhat: {
            chainId: 31337,
            gas: 3000000,
        },
    },
};

export default config;
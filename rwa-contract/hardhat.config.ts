import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  "networks": {
    "ancient-testnet": {
      url: "https://rpcv2-testnet.ancient8.gg",
      accounts: ["b5c03e290e78040b117c807f9389eb24b0a02f3005d98d901e9af63aee43ecb5"]
    }
  },
};

export default config;

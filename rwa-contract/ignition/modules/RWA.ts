import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const RwaModule = buildModule("RwaModule", (m) => {
  const initialOwner = "0x90De83FD2cD4D01660cD6909692568a14661CdF1"
  const rwa = m.contract("RealEstateTokenization", [initialOwner]);

  return { rwa };
});

export default RwaModule;

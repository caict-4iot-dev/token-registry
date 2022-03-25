import { ethers } from "ethers";
import { ChainId } from ".";

export const AddressConstants = {
  Zero: ethers.constants.AddressZero,
  Burn: "0x000000000000000000000000000000000000dEaD",
};

export const RoleConstants = {
  DefaultAdmin: ethers.constants.HashZero,
  MinterRole: ethers.utils.id("MINTER_ROLE"),
  AccepterRole: ethers.utils.id("ACCEPTER_ROLE"),
  RestorerRole: ethers.utils.id("RESTORER_ROLE"),
};

export const ContractAddress: Record<string, Record<number, string | undefined>> = {
  TitleEscrowFactory: {
    [ChainId.Ethereum]: AddressConstants.Zero,
    [ChainId.Rinkeby]: AddressConstants.Zero,
    [ChainId.Ropsten]: AddressConstants.Zero,
    [ChainId.Goerli]: AddressConstants.Zero,
    [ChainId.Kovan]: AddressConstants.Zero,
    [ChainId.Polygon]: AddressConstants.Zero,
    [ChainId.PolygonMumbai]: "0xe19F168c75b1dE88bD95EEC44d65e05Ce6F79486",
  },
  Deployer: {
    [ChainId.Ethereum]: AddressConstants.Zero,
    [ChainId.Rinkeby]: AddressConstants.Zero,
    [ChainId.Ropsten]: AddressConstants.Zero,
    [ChainId.Goerli]: AddressConstants.Zero,
    [ChainId.Kovan]: AddressConstants.Zero,
    [ChainId.Polygon]: AddressConstants.Zero,
    [ChainId.PolygonMumbai]: "0xF902E899134E5b851631efE9080487BE589AD987",
  },
  TokenImplementation: {
    [ChainId.Ethereum]: AddressConstants.Zero,
    [ChainId.Rinkeby]: AddressConstants.Zero,
    [ChainId.Ropsten]: AddressConstants.Zero,
    [ChainId.Goerli]: AddressConstants.Zero,
    [ChainId.Kovan]: AddressConstants.Zero,
    [ChainId.Polygon]: AddressConstants.Zero,
    [ChainId.PolygonMumbai]: "0xd9B18aB7ecFD0CA9832c5b4CEaF4f6320f8B5DAf",
  },
};

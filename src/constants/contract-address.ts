import { defaultAddress } from "./default-address";

const ChainId = {
  Ethereum: 1,
  Ropsten: 3,
  Rinkeby: 4,
  Goerli: 5,
  Kovan: 42,
  Polygon: 137,
  PolygonMumbai: 80001,
};

export const contractAddress = {
  TitleEscrowFactory: {
    [ChainId.Ethereum]: defaultAddress.Zero,
    [ChainId.Rinkeby]: defaultAddress.Zero,
    [ChainId.Ropsten]: defaultAddress.Zero,
    [ChainId.Goerli]: defaultAddress.Zero,
    [ChainId.Kovan]: defaultAddress.Zero,
    [ChainId.Polygon]: defaultAddress.Zero,
    [ChainId.PolygonMumbai]: "0xe19F168c75b1dE88bD95EEC44d65e05Ce6F79486",
  },
  Deployer: {
    [ChainId.Ethereum]: defaultAddress.Zero,
    [ChainId.Rinkeby]: defaultAddress.Zero,
    [ChainId.Ropsten]: defaultAddress.Zero,
    [ChainId.Goerli]: defaultAddress.Zero,
    [ChainId.Kovan]: defaultAddress.Zero,
    [ChainId.Polygon]: defaultAddress.Zero,
    [ChainId.PolygonMumbai]: "0xF902E899134E5b851631efE9080487BE589AD987",
  },
  TokenImplementation: {
    [ChainId.Ethereum]: defaultAddress.Zero,
    [ChainId.Rinkeby]: defaultAddress.Zero,
    [ChainId.Ropsten]: defaultAddress.Zero,
    [ChainId.Goerli]: defaultAddress.Zero,
    [ChainId.Kovan]: defaultAddress.Zero,
    [ChainId.Polygon]: defaultAddress.Zero,
    [ChainId.PolygonMumbai]: "0xd9B18aB7ecFD0CA9832c5b4CEaF4f6320f8B5DAf",
  },
};

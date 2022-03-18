import { waffle, ethers } from "hardhat";
import faker from "faker";
import { ContractTransaction } from "ethers";
import { TitleEscrow, TitleEscrowFactory } from "@tradetrust/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from ".";
import { deployEscrowFactoryFixture } from "./fixtures";
import { getEventFromTransaction, getTestUsers, TestUsers } from "./utils";

const { loadFixture } = waffle;

describe("TitleEscrowFactory", async () => {
  let users: TestUsers;

  let titleEscrowFactory: TitleEscrowFactory;

  const createEventAbi = [
    "event TitleEscrowCreated (address indexed titleEscrow, address indexed tokenRegistry, uint256 indexed tokenId, address beneficiary, address holder)",
  ];

  beforeEach(async () => {
    users = await getTestUsers();

    titleEscrowFactory = await loadFixture(deployEscrowFactoryFixture({ deployer: users.carrier }));
  });

  describe("Create Title Escrow Contract", () => {
    let fakeRegistrySigner: SignerWithAddress;
    let titleEscrowFactoryCreateTx: ContractTransaction;
    let titleEscrowContract: TitleEscrow;
    let tokenId: string;

    beforeEach(async () => {
      tokenId = faker.datatype.hexaDecimal(64);
      fakeRegistrySigner = users.others[faker.datatype.number(users.others.length - 1)];
      titleEscrowFactoryCreateTx = await titleEscrowFactory
        .connect(fakeRegistrySigner)
        .create(users.beneficiary.address, users.holder.address, tokenId);

      const event = await getEventFromTransaction(titleEscrowFactoryCreateTx, createEventAbi, "TitleEscrowCreated");
      titleEscrowContract = (await ethers.getContractFactory("TitleEscrow")).attach(
        event.titleEscrow as string
      ) as TitleEscrow;
    });

    it("should create with the correct token registry address", async () => {
      const registryAddress = await titleEscrowContract.registry();

      expect(registryAddress).to.equal(fakeRegistrySigner.address);
    });

    it("should create with the correct beneficiary", async () => {
      const beneficiary = await titleEscrowContract.beneficiary();

      expect(beneficiary).to.equal(users.beneficiary.address);
    });

    it("should create with the correct holder ", async () => {
      const holder = await titleEscrowContract.holder();

      expect(holder).to.equal(users.holder.address);
    });

    it("should emit TitleEscrowCreated event", async () => {
      expect(titleEscrowFactoryCreateTx)
        .to.emit(titleEscrowFactory, "TitleEscrowCreated")
        .withArgs(
          titleEscrowContract.address,
          fakeRegistrySigner.address,
          tokenId,
          users.beneficiary.address,
          users.holder.address
        );
    });
  });
});

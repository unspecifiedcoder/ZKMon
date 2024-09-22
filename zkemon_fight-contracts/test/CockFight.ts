import { assert, expect } from "chai";
import { ethers } from "hardhat";
import * as util from "util";
import {
  BreedVerifier,
  BreedVerifier__factory,
  CockFight,
  CockFight__factory,
  CrossVerifier,
  CrossVerifier__factory,
  FightVerifier,
  FightVerifier__factory,
} from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
// import { initialize } from "zokrates-js";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
import crypto from "crypto";
import { ResolverResult, ZoKratesProvider } from "zokrates-js-node";
const { initialize } = require("zokrates-js-node");
import path from "path";
import fs from "fs";

interface IAttr {
  agility: number;
  power: number;
  defense: number;
  fam: number;
}

// async function lazyImport() : Promise<() => Promise<ZoKratesProvider>> {
//   let { initialize } = await import("zokrates-js");
//   return initialize;
// }
// https://github.dev/rickkdev/gain/blob/d8e5bc1daa470272dd05912e7a652373f705aef7/src/components/peggy.js#L4

// for now just getting things done with helper funcs cuz time constraint later will write proper class based helper funs
describe("CockFight", function () {
  let CockFight: CockFight;
  let breedverifier: BreedVerifier;
  let crossverifier: CrossVerifier;
  let fightverifier: FightVerifier;
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;
  // let initialize : () => Promise<ZoKratesProvider>

  let store: Record<number, IAttr> = {};

  function splitHash(hash: string) {
    if (hash.length !== 64) {
      throw new Error("Expected a 256-bit hash");
    }

    return [
      BigInt("0x" + hash.slice(0, 32)).toString(),
      BigInt("0x" + hash.slice(32)).toString(),
    ];
  }

  function computeCommitment(attr: IAttr): string[] {
    const [agility, power, defense, fam] = [
      attr.agility,
      attr.power,
      attr.defense,
      attr.fam,
    ];

    let hex1 = agility.toString(16).padStart(32, "0");
    let hex2 = power.toString(16).padStart(32, "0");
    let hex3 = defense.toString(16).padStart(32, "0");
    let hex4 = fam.toString(16).padStart(32, "0");

    let combinedHex = hex1 + hex2 + hex3 + hex4;

    // Create a buffer from the concatenated string
    let preimage = Buffer.from(combinedHex, "hex");

    // Hash the buffer using SHA-256
    let hash = crypto.createHash("sha256");
    hash.update(preimage);
    // let hashed = hash.digest('hex');

    return splitHash(hash.digest("hex"));
  }

  async function setupZokProvider(circuit: "breed" | "cross" | "fight") {
    let zokratesProvider: ZoKratesProvider = await initialize();
    let parentFolder = path.dirname(path.basename(__dirname));
    console.log(parentFolder, "parent");
    // return
    // let program: Uint8Array;
    const readFile = util.promisify(fs.readFile);
    let program =   await new Uint8Array(await readFile(parentFolder + `/contracts/${circuit}/out`))

    let abi = JSON.parse(
      fs.readFileSync(parentFolder + `/contracts/${circuit}/abi.json`, "utf-8")
    );

    let proving_key = new Uint8Array(
      fs.readFileSync(parentFolder + `/contracts/${circuit}/proving.key`)
    );
    let verification_key = new Uint8Array(
      fs.readFileSync(parentFolder + `/contracts/${circuit}/verification.key`)
    );
    let rawdata = fs.readFileSync(
      parentFolder + `/contracts/${circuit}/${circuit}.zok`
    );

    const source = rawdata.toString();

    // function myCallback(location: string, path: string): ResolverResult {
    //   // Your logic here
    //   // For example, you might return a new ResolverResult object
    //   return {
    //     source: parentFolder + `/contracts/${circuit}/${circuit}.zok`,
    //     location: './'
    //   };
    // }
    // let location = 'location string';

    // const artifacts = zokratesProvider.compile(source , "./" ,myCallback);

    return {
      Zkprovider: zokratesProvider,
      program,
      abi,
      proving_key,
      verification_key,
      // artifacts
    };
  }

  before("deploy contract", async () => {
    // initialize = await lazyImport();
    [owner, alice, bob] = await ethers.getSigners();

    let breedverifierFactory: BreedVerifier__factory =
      await ethers.getContractFactory("BreedVerifier");
    breedverifier = await breedverifierFactory.deploy();
    await breedverifier.waitForDeployment();

    let crossverifierFactory: CrossVerifier__factory =
      await ethers.getContractFactory("CrossVerifier");
    crossverifier = await crossverifierFactory.deploy();
    await crossverifier.waitForDeployment();

    let fightverifierFactory: FightVerifier__factory =
      await ethers.getContractFactory("FightVerifier");
    fightverifier = await fightverifierFactory.deploy();
    await fightverifier.waitForDeployment();

    // deploy CockFight
    let CockFightFactory: CockFight__factory = await ethers.getContractFactory(
      "CockFight"
    );
    CockFight = await CockFightFactory.deploy(
      bob.address,
      await breedverifier.getAddress(),
      await crossverifier.getAddress(),
      await fightverifier.getAddress()
    );
    await CockFight.waitForDeployment();

    // assert(CockFight.address != "");
    assert(await CockFight.name(), "CockFight NFT");
    // assert(CockFight.name == "CockFight NFT")
  });

  async function generateRandAttrCommitment() {
    let NextToken = await CockFight.tokenCount();
    store[Number(NextToken) + 1] = {
      agility: Math.floor(Math.random() * 71),
      defense: Math.floor(Math.random() * 71),
      power: Math.floor(Math.random() * 71),
      fam: Math.floor(Math.random() * 5),
    };
    let [cm1, cm2] = computeCommitment(store[Number(NextToken) + 1]);
    return [cm1, cm2];
  }
  // mint a new NFT with correct parameters
  // mint a new NFT with valid input
  it("should mint a new NFT with valid input", async () => {
    // Arrange
    const tokenURI = "https://example.com/nft";
    const commitment1 = 123n;
    const commitment2 = 456n;
    const expectedTokenCount = 1n;
    await mine(100000);
    const expectedCommitmentRecord = [
      commitment1,
      commitment2,
      BigInt(
        Math.floor((await ethers.provider.getBlockNumber()) / 10000) * 10000
      ),
    ];

    // Act
    const result = await CockFight.mint(tokenURI, commitment1, commitment2, {
      value: ethers.parseEther("1.0"), // Sending 1.0 ETH
    });
    await result.wait();

    expect(await CockFight.tokenCount()).to.equal(expectedTokenCount);
    expect(
      await CockFight.getCommitmentRecord(await CockFight.tokenCount())
    ).to.deep.equal(expectedCommitmentRecord);
  });

  it("should compute correct Results", async () => {
    let [cm1, cm2] = computeCommitment({
      agility: 0,
      defense: 0,
      power: 0,
      fam: 5,
    });
    expect(cm1).to.be.eq("263561599766550617289250058199814760685");
  });

  it("alice and bob should be able to Fight", async () => {
    // Arrange
    const tokenURAlice = "https://example.com/nft1";
    const tokenURIBob = "https://example.com/nft2";

    let CurrentToken = await CockFight.tokenCount();

    let [alice_cmt1, alice_cmt2] = await generateRandAttrCommitment();
    let AliceMint = await CockFight.connect(alice).mint(
      tokenURAlice,
      alice_cmt1,
      alice_cmt2,
      {
        value: ethers.parseEther("1.0"), // Sending 1.0 ETH
      }
    );
    await AliceMint.wait();
    let AliceTokenId = await CockFight.tokenCount();
    assert(CurrentToken + 1n == AliceTokenId);

    let [bob_cmt1, bob_cmt2] = await generateRandAttrCommitment();
    let BobMint = await CockFight.connect(bob).mint(
      tokenURIBob,
      bob_cmt1,
      bob_cmt2,
      {
        value: ethers.parseEther("1.0"), // Sending 1.0 ETH
      }
    );
    await BobMint.wait();
    let BobTokenId = await CockFight.tokenCount();

    // lock for each user
    let AliceLock = await CockFight.connect(alice).LockCockForFight(
      AliceTokenId,
      {
        value: ethers.parseEther("1.0"), // Sending 1.0 ETH
      }
    );
    await CockFight.connect(bob).LockCockForFight(BobTokenId, {
      value: ethers.parseEther("1.0"), // Sending 1.0 ETH
    });

    let AliceInitFight = await CockFight.connect(alice).InitFight(
      AliceTokenId,
      bob.address,
      BobTokenId
    );
    // alice
    let engagedCocks = await CockFight.engagedCocks(0);
    expect(engagedCocks[0]).to.be.eq(
      "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    );
    expect(engagedCocks[1]).to.be.eq(
      "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
    );
    expect(engagedCocks[2]).to.be.eq(2n);
    expect(engagedCocks[3]).to.be.eq(3n);
    console.log(store);

    let fight_circuit = await setupZokProvider("fight");

    // let
    let GameInputs = [
      [
        store[Number(AliceTokenId)].agility.toString(),
        store[Number(BobTokenId)].agility.toString(),
      ],
      [
        store[Number(AliceTokenId)].power.toString(),
        store[Number(BobTokenId)].power.toString(),
      ],
      [
        store[Number(AliceTokenId)].defense.toString(),
        store[Number(BobTokenId)].defense.toString(),
      ],
      [
        store[Number(AliceTokenId)].fam.toString(),
        store[Number(BobTokenId)].fam.toString(),
      ],
      [alice_cmt1, alice_cmt2],
      [bob_cmt1, bob_cmt2],
    ];
    console.log(
      GameInputs,
      GameInputs.length,
      fight_circuit.abi,
      fight_circuit.program,
      "ZKPZKP ZKZP"
    );
    let { witness, output } = fight_circuit.Zkprovider.computeWitness(
      {
        abi: JSON.stringify(fight_circuit.abi),
        program: fight_circuit.program,
      },
      GameInputs
    );

    // let gen_proof = fight_circuit.Zkprovider.generateProof(
    //   fight_circuit.program,
    //   witness,
    //   fight_circuit.proving_key
    // );
    // console.log(output);
  });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {BreedVerifier} from "./breed/breedverifier.sol";
import {CrossVerifier} from "./cross/crossverifier.sol";
import {FightVerifier} from "./fight/fightverifier.sol";
import "./pairing.sol";

interface ICockFight {
    struct Commitment {
        uint commitment1;
        uint commitment2;
        uint breedBlock;
    }

    struct engagedInFight {
        address initiator;
        address opponent;
        uint initiatorCockId;
        uint opponentCockId;
        uint atBlock;
    }

    function mint(
        string calldata _tokenURI,
        uint commitment1,
        uint commitment2
    ) external payable returns (uint);

    function isEngagedInFight(
        address _initiator,
        address _opponent,
        uint _initiatorCockId,
        uint _opponentCockId
    ) external returns (bool);

    function fight(
        uint FightTokenId,
        uint OpponentTokenId,
        address opponent,
        uint zkOutCome,
        FightVerifier.Proof memory proof
    ) external returns (uint);

    function crossCocks(
        uint fatherToken,
        uint motherToken,
        uint NewChildCommitment1,
        uint NewChildCommitment2,
        string memory ChildtokenUri,
        CrossVerifier.Proof memory proof
    ) external;

    function breedCocks(
        uint CockId,
        uint NewCommitment1,
        uint NewCommitment2,
        BreedVerifier.Proof memory proof
    ) external;

    function stakeCock(uint CockId) external payable;

    function unstakeCock(uint CockId) external;

    function LockCockForFight(uint CockId) external payable;

    function InitFight(
        uint CockId,
        address opponent,
        uint opponentCockId
    ) external payable;

    function slashUsers() external;
}

// workflow of this contract
// user mints a new NFT
// with a NFT user has four option Fight with another User , Breed his CockNft , cross mate his CockNft with another Cock
// in order to fight user has to lock his COckNft for Fight
// once he locked his nft and his opponent also locked their Nft buy sending 1th and calling LockCockForFight which does safetransferFrom both users
// then one of them should call InitFight
// we do a offchain computation and send ZKsnark proof to fight function
// fight function declares winner and burns loosers NFt send 0.5eth to winner
contract CockFight is ICockFight, ERC721URIStorage {
    // token count for tokenId
    uint public tokenCount;

    address public owner;

    // will add ROLE based access controll but as of now bobBot is account which opposite bids you he does need eth to mint new token
    address public bobBot;

    // map of commitments to validate proofs;
    mapping(uint => Commitment) public commitmentRecord;
    // locked for fight
    mapping(uint => bool) public lockedForFight;
    // Cocks which are engaged in a fight
    engagedInFight[] public engagedCocks;
    // staking Cocks
    mapping(uint => bool) public stakedCocks;

    BreedVerifier public breedVerifier;
    CrossVerifier public crossVerifier;
    FightVerifier public fightVerifier;

    constructor(
        address _bobBot,
        address _breedVerifier,
        address _crossVerifier,
        address _fightVerifier
    ) ERC721("CockFight NFT", "CockFight") {
        owner = msg.sender;
        bobBot = _bobBot;
        breedVerifier = BreedVerifier(_breedVerifier);
        crossVerifier = CrossVerifier(_crossVerifier);
        fightVerifier = FightVerifier(_fightVerifier);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // a modifier for checking if user has ownership of given tokenId
    modifier hasOwnership(uint tokenId, address ownedBy) {
        require(ownerOf(tokenId) == ownedBy, "You don't own this NFT");
        _;
    }

    // user needs 1eTh to mint a NewToken
    function mint(
        string calldata _tokenURI,
        uint commitment1,
        uint commitment2
    ) public payable returns (uint) {
        require(msg.value == 1 ether, "You need 1eTh to mint a new NFT");
        tokenCount++;
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        commitmentRecord[tokenCount] = Commitment(
            commitment1,
            commitment2,
            roundToFourZeros(block.number)
        );
        return (tokenCount);
    }

    function isEngagedInFight(
        address _initiator,
        address _opponent,
        uint _initiatorCockId,
        uint _opponentCockId
    ) public returns (bool) {
        for (uint i = 0; i < engagedCocks.length; i++) {
            if (
                engagedCocks[i].initiator == _initiator &&
                engagedCocks[i].opponent == _opponent &&
                engagedCocks[i].initiatorCockId == _initiatorCockId &&
                engagedCocks[i].opponentCockId == _opponentCockId
            ) {
                engagedCocks[i] = engagedCocks[engagedCocks.length - 1];
                engagedCocks.pop();
                return true;
            }
        }
        return false;
    }

    // check if messegae sender and oppnent mentioned are in engagedInFight Array else revert
    // do basic sanity checks for smart contract security like do the msg sender and opponent really hold the token they passed
    // get commitment of msg sender and opponent and send to  another ZkveriferContract along with zkoutCome if it returns false revert
    // if it returns true and zkOutCome is 0 then burn the Nft of opponent and send 0.5th to msg sender
    // else if zkOut is 1 then burn the Nft of msg sender and send 0.5 to opponent
    // here msg sender is considerred as initator
    function fight(
        uint FightTokenId,
        uint OpponentTokenId,
        address opponent,
        uint zkOutCome,
        FightVerifier.Proof memory proof
    )
        external
        hasOwnership(FightTokenId, msg.sender)
        hasOwnership(OpponentTokenId, opponent)
        returns (uint)
    {
        require(
            lockedForFight[FightTokenId] && lockedForFight[OpponentTokenId],
            "Both tokens must be locked for fight"
        );
        require(
            isEngagedInFight(
                msg.sender,
                opponent,
                FightTokenId,
                OpponentTokenId
            ),
            "You are not engaged in a fight"
        );
        // check if given args are in  engagedCocks
        // zk stuff yet to be done
        uint[5] memory input = [
            commitmentRecord[FightTokenId].commitment1,
            commitmentRecord[FightTokenId].commitment2,
            commitmentRecord[OpponentTokenId].commitment1,
            commitmentRecord[OpponentTokenId].commitment2,
            zkOutCome
        ];
        require(fightVerifier.verifyTx(proof, input), "Invalid proof");
        if (zkOutCome == 0) {
            _burn(OpponentTokenId);
            payable(msg.sender).transfer(0.5 ether);
        } else if (zkOutCome == 1) {
            _burn(FightTokenId);
            payable(opponent).transfer(0.5 ether);
        } else {
            revert("Unreachable code");
        }
        return (0);
    }

    // check if msg sender has ownership of father and mother token get commitment of father and mother and send to a another ZkveriferContract
    // if it returns true call mint function commitment and tokenUri
    function crossCocks(
        uint fatherToken,
        uint motherToken,
        uint NewChildCommitment1,
        uint NewChildCommitment2,
        string calldata ChildtokenUri,
        CrossVerifier.Proof memory proof
    )
        external
        hasOwnership(fatherToken, msg.sender)
        hasOwnership(motherToken, msg.sender)
    {
        // zkstuff
        uint[6] memory input = [
            commitmentRecord[fatherToken].commitment1,
            commitmentRecord[fatherToken].commitment2,
            commitmentRecord[motherToken].commitment1,
            commitmentRecord[motherToken].commitment2,
            NewChildCommitment1,
            NewChildCommitment2
        ];
        require(crossVerifier.verifyTx(proof, input), "Invalid proof");
        mint(ChildtokenUri, NewChildCommitment1, NewChildCommitment2);
    }

    function roundToFourZeros(uint number) public pure returns (uint) {
        return (number / 10000) * 10000;
    }

    // check if msg sender has ownership cockId passed
    // get the commitment of cockId passed and pass to another ZkveriferContract along with NewCommitment current block and past block to a
    // another ZkveriferContract if it returns true update commitment and breeBLock for given CockID
    function breedCocks(
        uint CockId,
        uint NewCommitment1,
        uint NewCommitment2,
        BreedVerifier.Proof memory proof
    ) external hasOwnership(CockId, msg.sender) {
        require(stakedCocks[CockId], "Cock must be staked");
        uint[6] memory input = [
            commitmentRecord[CockId].commitment1,
            commitmentRecord[CockId].commitment2,
            NewCommitment1,
            NewCommitment2,
            commitmentRecord[CockId].breedBlock,
            roundToFourZeros(block.number)
        ];
        // zkstuff
        require(breedVerifier.verifyTx(proof, input), "Invalid proof");

        // zkstuff
        commitmentRecord[CockId].commitment1 = NewCommitment1;
        commitmentRecord[CockId].commitment2 = NewCommitment2;
        commitmentRecord[CockId].breedBlock = roundToFourZeros(block.number);
    }

    // check if user is sending 1Eth and update the stakedCocks
    function stakeCock(
        uint CockId
    ) external payable hasOwnership(CockId, msg.sender) {
        require(!stakedCocks[CockId], "Cock is already staked");
        require(msg.value == 1 ether, "Must stake 1 eth");
        stakedCocks[CockId] = true;
    }

    // check if user was staking unstake it and update the stakedCocks
    function unstakeCock(
        uint CockId
    ) external hasOwnership(CockId, msg.sender) {
        require(stakedCocks[CockId], "Cock is not staked");
        stakedCocks[CockId] = false;
    }

    // check if user is sending 1Eth and update lockedForFight
    function LockCockForFight(
        uint CockId
    ) external payable hasOwnership(CockId, msg.sender) {
        require(!lockedForFight[CockId], "Cock is already locked");
        require(msg.value == 1 ether, "Must stake 1 eth");
        lockedForFight[CockId] = true;
    }

    // check lockedForFIght the the given nftId is locked by user and opponentNft is locked by opponent
    // if no revert if yes add an entry to engagedforFigth array
    function InitFight(
        uint CockId,
        address opponent,
        uint opponentCockId
    )
        external
        payable
        hasOwnership(CockId, msg.sender)
        hasOwnership(opponentCockId, opponent)
    {
        require(lockedForFight[CockId], "Cock is not Locked");
        require(lockedForFight[opponentCockId], "Cock is not Locked");
        // bytes32 index = keccak256(abi.encodePacked(msg.sender , opponent , CockId , opponentCockId));
        // engagedCocksMap[index] = block.number;
        // engagedCocks.push(index);
        lockedForFight[opponentCockId] = false;
        engagedCocks.push(
            engagedInFight(
                msg.sender,
                opponent,
                CockId,
                opponentCockId,
                block.number
            )
        );
    }

    // traverse through engagedForfight array and if atBlock difference is grater than 100 blocks from now then burn the nft of initator and send 0.5Eth to opponent
    // if atblock difference from now is less than 100 blocks then add the entry to newengagedForfight array
    // in the end of function replace engagedForfight with newengagedForfight
    // this function is called by server every 24 hours or so
    function slashUsers() external onlyOwner {
        uint originalLength = engagedCocks.length;
        uint i = 0;
        uint j = 0;

        while (i < originalLength) {
            // Move the pointer to the next fight if the current one is invalid
            if (block.number - engagedCocks[j].atBlock > 100) {
                _burn(engagedCocks[j].initiatorCockId);
                payable(engagedCocks[j].opponent).transfer(0.5 ether);

                // Remove the current fight by moving the last one to this position
                if (j < engagedCocks.length - 1) {
                    engagedCocks[j] = engagedCocks[engagedCocks.length - 1];
                }
                // Reduce the length of the array
                engagedCocks.pop();
            } else {
                j++;
            }
            i++;
        }
    }

    // getters
    function getCommitmentRecord(
        uint id
    ) public view returns (Commitment memory) {
        return commitmentRecord[id];
    }

    function getLockedForFight(uint id) public view returns (bool) {
        return lockedForFight[id];
    }

    function getStakedCocks(uint id) public view returns (bool) {
        return stakedCocks[id];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Emofty} from "./Emofty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EmoftiesProtocol is Emofty {
    using Counters for Counters.Counter;

    error SharingNotAllowed();
    error NoCoreEmotion();
    error CantClaimEmoftyForThisEmotion();
    error EmotionAlreadyRegistered();

    struct Emotion {
        string name;
        bool core;
    }

    struct SharedEmotion {
        bytes32 coreEmotion;
        bytes32 emotionShade;
        bytes32 associatedTx;
        uint256 timestamp;
        address receiver;
        string memo;
    }

    bytes32 public constant JOY = keccak256("JOY");
    bytes32 public constant FEAR = keccak256("FEAR");
    bytes32 public constant SADNESS = keccak256("SADNESS");
    bytes32 public constant DISGUST = keccak256("DISGUST");
    bytes32 public constant ANGER = keccak256("ANGER");
    bytes32 public constant LOVE = keccak256("LOVE");

    Counters.Counter private soulboundTokenIdCounter;
    Counters.Counter private shareTokenIdCounter;

    // emotions registry: emotion Hash => emotionName
    mapping(bytes32 => Emotion) emotions;

    // emofties: core emotion => (address => emoftyId)
    mapping(bytes32 => mapping(address => uint256)) emofties;

    // shared Emotions: sender => (timestamp or nftId => SharedEmotion)
    mapping(address => mapping(uint256 => SharedEmotion)) sharedEmotions;

    // sharing approvals: approver => (approved => true/false)
    mapping(address => mapping(address => bool)) allowances;

    // sharing approval for all
    mapping(address => bool) allowancesForAll;

    event EmotionRegistered(
        bytes32 indexed emotionHash,
        string indexed emotionName,
        address indexed registrar
    );

    event EmoftyClaimed(
        address indexed owner,
        bytes32 indexed coreEmotion,
        uint256 indexed emoftyId
    );

    event EmoftyShared(
        address indexed sender,
        uint256 indexed sharedEmoftyId,
        bytes32 indexed coreEmotion,
        address receiver,
        bytes32 emotionShade,
        bytes32 associatedTx,
        uint256 timestamp,
        string memo
    );

    constructor() {
        emotions[JOY] = Emotion("JOY", true);
        emotions[FEAR] = Emotion("FEAR", true);
        emotions[SADNESS] = Emotion("SADNESS", true);
        emotions[DISGUST] = Emotion("DISGUST", true);
        emotions[ANGER] = Emotion("ANGER", true);
        emotions[LOVE] = Emotion("LOVE", true);
    }

    function approveForAll() external {
        allowancesForAll[msg.sender] = true;
    }

    function approve(address _approved) external {
        allowances[msg.sender][_approved] = true;
    }

    // todo: limit name to bytes32
    function registerEmotion(string memory _name) external {
        bytes32 hashedName = keccak256(abi.encodePacked(_name));
        if (bytes(emotions[hashedName].name).length > 0) {
            revert EmotionAlreadyRegistered();
        }
        emotions[hashedName] = Emotion(_name, false);

        emit EmotionRegistered(hashedName, _name, msg.sender);
    }

    function claimSoulboundEmofty(bytes32 _coreEmotion, string memory _uri)
        external
    {
        if (!emotions[_coreEmotion].core) {
            revert CantClaimEmoftyForThisEmotion();
        }

        soulboundTokenIdCounter.increment();
        uint256 emoftyId = soulboundTokenIdCounter.current();
        mintEmofty(emoftyId, msg.sender, _uri);

        emofties[_coreEmotion][msg.sender] = emoftyId;

        emit EmoftyClaimed(msg.sender, _coreEmotion, emoftyId);
    }

    function shareEmofty(SharedEmotion memory _shared, string memory _uri)
        external
    {
        if (!emotions[_shared.coreEmotion].core) {
            revert NoCoreEmotion();
        }

        if (
            _shared.receiver != address(0) &&
            !allowancesForAll[_shared.receiver] &&
            !allowances[_shared.receiver][msg.sender]
        ) {
            revert SharingNotAllowed();
        }

        shareTokenIdCounter.increment();
        // Use shift for 128 for shared emofties
        uint256 sharedEmoftyId = shareTokenIdCounter.current() << 128;

        sharedEmotions[msg.sender][sharedEmoftyId] = _shared;

        // TODO: batch mint to x addresses - ERC1155 ?
        if (bytes(_uri).length > 0) {
            if (_shared.receiver != address(0)) {
                mintEmofty(sharedEmoftyId, _shared.receiver, _uri);
            } else {
                mintEmofty(sharedEmoftyId, msg.sender, _uri);
            }
        }

        emit EmoftyShared(
            msg.sender,
            sharedEmoftyId,
            _shared.coreEmotion,
            _shared.receiver,
            _shared.emotionShade,
            _shared.associatedTx,
            _shared.timestamp,
            _shared.memo
        );
    }

    function mintSharedEmofty(uint256 _tokenId) external {
        // TODO: check if it's a shareable NFT with bitwise logic
        // TODO: check if the sender is allowed to mint

        string memory sharedTokenUri = tokenURI(_tokenId);
        shareTokenIdCounter.increment();
        uint256 newSharedTokenId = shareTokenIdCounter.current() << 128;
        mintEmofty(newSharedTokenId, msg.sender, sharedTokenUri);
    }

    function getEmofty(address _owner, bytes32 _coreEmotion)
        public
        view
        returns (bool exists, uint256 emoftyId)
    {
        emoftyId = emofties[_coreEmotion][_owner];
        exists = emoftyId != 0;
    }
}

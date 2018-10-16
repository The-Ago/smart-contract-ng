pragma solidity ^0.4.20;

import "./AgoInterface.sol";
import "./AgoClaimer.sol";

/* solium-disable security/no-block-members */

contract TheAgo {
    AgoInterface ago = AgoInterface(0x2F5e044ad4Adac34C8d8dF738Fac7743edA1409C);
    AgoClaimer claimer;
    uint annoncePrice = 1;
    uint premiumPrice = 10;
    address owner;

    mapping(address => bool) moderators;
    mapping(uint => Annonce) annonces;

    uint lastAnnonceId = 0;

    struct Annonce {
        uint id;
        address annonceOwner;
        string title;
        string descHash;
        string picHash;
        bool moderated;
    }

    event AnnonceCreated(
        uint id,
        string title,
        address annonceOwner,
        uint timestamp
    );

    event AnnoncePremium(
        uint id,
        uint expireAt
    );

    constructor(address claimerAddr) public {
        owner = msg.sender;
        moderators[msg.sender] = true;
        claimer = AgoClaimer(claimerAddr);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyModerators() {
        require(moderators[msg.sender], "Not moderator");
        _;
    }

    modifier requireSenderProvision(uint amountRequired) {
        require(ago.allowance(msg.sender, this) >= amountRequired*(10**18), "Not provisioned");
        _;
    }

    function setAnnoncePrice(uint price) public onlyOwner {
        annoncePrice = price;
    }

    function addModerator(address moderator) public onlyOwner {
        moderators[moderator] = true;
    }

    function revokeModerator(address moderator) public onlyOwner {
        moderators[moderator] = false;
    }

    function killApp() public onlyOwner {
        selfdestruct(owner);
    }

    function debitProvision(uint amount) private returns (bool success) {
        success = ago.transferFrom(msg.sender, claimer, amount*(10**18));
    }

    function premiumAnnonce(uint id) public requireSenderProvision(premiumPrice) {
        require(annonces[id].moderated, "Annonce not live");
        require(debitProvision(premiumPrice), "Could not debit provision for premium");
        emit AnnoncePremium(id, block.timestamp + 1296000);
    }

    function createAnnonce(
        string title,
        string descHash,
        string picHash
    ) public requireSenderProvision(annoncePrice) {
        require(debitProvision(annoncePrice), "Could not debit provision");
        uint id = lastAnnonceId++;
        Annonce storage a = annonces[id];
        a.id = id;
        a.annonceOwner = msg.sender;
        a.title = title;
        a.descHash = descHash;
        a.picHash = picHash;
    }

    function approveAnnonce(uint id) public onlyModerators {
        Annonce storage a = annonces[id];
        a.moderated = true;
        emit AnnonceCreated(a.id, a.title, msg.sender, block.timestamp);
    }

    function discardAnnonce(uint id) public onlyModerators {
        Annonce storage a = annonces[id];
        a.id = 0;
        a.title = "";
        a.descHash = "";
        a.picHash = "";
        a.moderated = false;
    }
}

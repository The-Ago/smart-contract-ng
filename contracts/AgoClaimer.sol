pragma solidity ^0.4.20;

import "./AgoInterface.sol";

contract AgoClaimer {
    AgoInterface ago = AgoInterface(0x2F5e044ad4Adac34C8d8dF738Fac7743edA1409C);
    address owner;

    mapping (uint256 => uint256) claimerBalances;
    mapping (uint256 => mapping (address => bool)) claimings;

    event Claim(address indexed _owner, uint256 _value);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Gets your Ether for the AGO tokens you own.
    function claim(address target) public returns (bool success) {
        // Gets the latest reference block number from the Agora Token contract.
        uint256 latestReferenceBlockNumber = ago.latestReferenceBlockNumber();

        // Require that the user did not make a withdrwal given this reference
        // block number already.
        require(!claimings[latestReferenceBlockNumber][target], "Claimings");

        // Get the AGO token balance of the User at the latest reference block
        uint256 userAgoraBalance = ago.balanceAtBlock(target, latestReferenceBlockNumber);

        // Calculate the part of the user.
        uint256 userValue = (userAgoraBalance / ago.totalSupply()) * claimerBalanceAtBlock(latestReferenceBlockNumber);

        // Require the user to have something to withdraw.
        require(userValue > 0, "Nothing to take");

        // Write that the transaction have been done for this reference block number.
        claimings[latestReferenceBlockNumber][target] = true;

        // Make the transaction
        ago.transfer(address(this), userValue);
        emit Claim(target, userValue);

        return true;
    }

    // This method return the balance of the Claimer at a known reference block number.
    // If it is the first time it is asked for this reference number, we save it.
    // That way, when another ask for this reference number, the grand total to
    // share between AGO owners is known and static.
    function claimerBalanceAtBlock(uint256 blockNumber) private returns (uint256 balance) {
        uint256 possible_balance = claimerBalances[blockNumber];

        if(possible_balance == 0) {
            claimerBalances[blockNumber] = ago.balanceOf(address(this));
        }

        return claimerBalances[blockNumber];
    }

    function killApp() public onlyOwner {
        ago.transfer(owner, ago.balanceOf(address(this)));
        selfdestruct(owner);
    }
}

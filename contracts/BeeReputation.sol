pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract BeeReputation is Ownable {

    address public beeTokenAddress;
    struct PlatformStruct {
        address sharingPlatform;
        address platformAdmin;
        bytes32 userId;
    }


    // userId mapped to platform specific rep score
    mapping(bytes32 => mapping(uint8 => PlatformStruct)) public reputation;

    function BeeReputation(address _beeTokenAddress) public {
        //TODO: initilize with bootstrap reputation
        beeTokenAddress = _beeTokenAddress;
    }

    // Accept eth as a donation
    function () public payable {
    }

    function updateReputation(address platform) public onlyOwner {
        // check address of score to be updated
        // update specified score
        revert();
    }

    function remove(address platform) public onlyOwner {
        // remove specified platform from reputation system
        revert();
    }

    // User needs to call approve on token address before calling
    function boostReputationWithBees(uint256 amount) public {
        ERC20 tokenContract = ERC20(beeTokenAddress);
        require(tokenContract.transferFrom(msg.sender, this, amount));
    }

    function ownerWithdrawBee() external onlyOwner {
        ERC20 tokenContract = ERC20(beeTokenAddress);
        uint256 tokenBalance = tokenContract.balanceOf(this);
        require(tokenContract.transfer(owner, tokenBalance));
    }

    function ownerWithdrawEther() external onlyOwner {
        owner.transfer(this.balance);
    }


    function checkReputation(address platform, bytes32 userId) public pure returns(uint8) {
        // spit out the reputation score of an individual
        revert();
    }

}

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract Reputation is Ownable {


    struct PlatformStruct {
        address sharingPlatform;
        address platformAdmin;
        bytes32 userId;
    }


    // userId mapped to platform specific rep score
    mapping(bytes32 => mapping(uint8 => PlatformStruct)) public reputation;

    function BeeReputation() public {
        //TODO: initilize with bootstrap reputation
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

    function checkReputation(address platform, bytes32 userId) public pure returns(uint8) {
        // spit out the reputation score of an individual
        revert();
    }

}

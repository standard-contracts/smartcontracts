pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract BeeReputation is Ownable {

    struct PlatformStruct {
        address sharingPlatform;
        bytes32 userId;
    }

    // 
    mapping(address => PlatformStruct) public whitelistedPlatforms;
    // userId mapped to platform specific rep score
    mapping(bytes32 => mapping(address => uint8)) public reputation;
    // platform admins
    mapping(address => address) public platformAdmins;

    function BeeReputation() public {
        //TODO: initilize with bootstrap reputation
    }

    function addPlatform(address _platform, address _admin) {
        //TODO: add platform and admin addresses
    }

    function updateReputation(address _platform, bytes32 _userId, uint8 _newScore) public onlyOwner returns(bool success) {
        // TODO: check for whitelistedPlatforms and admin
        require(_newScore > 0);
        if(reputation[_userId][_platform] > 0) {
            reputation[_userId][_platform] = _newScore;
            // TODO: add event to record update
        } else if(reputation[_userId][_platform] == 0){
            reputation[_userId][_platform] = _newScore;
            // TODO: add event for new user reputation
        } else return false;

        return true;
        // check address of score to be updated
        // update specified score

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

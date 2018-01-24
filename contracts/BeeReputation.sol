pragma solidity ^0.4.18;

<<<<<<< HEAD
import 'zeppelin-solidity/contracts/token/ERC20.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract BeeReputation is Ownable {

    using SafeMath for uint8;

    address public beeTokenAddress;
    uint256 public tokenPrice;
    // address[0] == beenest
    address[] public sharingPlatform;
    
    /*
    struct PlatformStruct {
        address sharingPlatform;
        address platformAdmin;
    }
    */
    event BootstrapNewUserReputation(address platform, bytes32 userId, uint8 initialRepScore);
    event UpdateUserReputation(address platform, bytes32 userId, uint8 newRepScore);
    event IndexHelper(uint256 index);

    modifier onlyPlatformAdmin(address _platform) {
        require(msg.sender == platformAdmins[_platform]);
        _;
    }

    // whitelist platforms
    //mapping(address => PlatformStruct) public whitelistedPlatforms;
    // userId mapped to platform specific rep score
    mapping(bytes32 => mapping(address => uint8)) public reputation;
    // userId to rep score
    mapping(bytes32 => uint8) public averageReputation;
    // platform admins
    mapping(address => address) public platformAdmins;
    // keep track of sharingPlatform indicies
    mapping(address => uint32) public platformIndex;

    // external functions
    function ownerWithdrawBee() external onlyOwner {
        ERC20 tokenContract = ERC20(beeTokenAddress);
        uint256 tokenBalance = tokenContract.balanceOf(this);
        require(tokenContract.transfer(owner, tokenBalance));
    }

    function ownerWithdrawEther() external onlyOwner {
        owner.transfer(this.balance);
    }
    // public functions
    function BeeReputation(address _beeTokenAddress, uint256 _tokenPrice) public {
        //TODO: initilize with bootstrap reputation
        tokenPrice = _tokenPrice;
        beeTokenAddress = _beeTokenAddress;
        platformAdmins[this] = msg.sender;
    }

    // Accept eth as a donation
    function () public payable {
    }
    /*
    //sharingPlatform[0] = this;
    function addPlatformToWhitelist(address _platform, address _admin) public onlyOwner {
        //TODO: add platform and admin addresses
        //TODO: avoid struct storage limitations by using arrays. This will allow us to take the average rep score easier
        require(sharingPlatform.push(_platform));
        platformIndex[_platform] = sharingPlatform.length;
        platformAdmins[_platform] = _admin;
        IndexHelper(platformIndex[_platform]);

    }
    */
    function updateTokenPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function updatePlatformAdmin(address _platform, address _admin) public onlyPlatformAdmin(_platform) {
        // Struct or admin mapping? 
        platformAdmins[_platform] = _admin;
    }

//iterate through all sharing platforms, then average all non-zero scores > internal function?

    function updateReputation(address _platform, bytes32 _userId, uint8 _newScore) public onlyOwner returns(bool success) {
        // TODO: check for whitelistedPlatforms and admin
        require(_newScore > 0);
        if(reputation[_userId][_platform] > 0) {
            reputation[_userId][_platform] = _newScore;
            UpdateUserReputation(_platform, _userId, _newScore);
        } else if(reputation[_userId][_platform] == 0){
            reputation[_userId][_platform] = _newScore;
            BootstrapNewUserReputation(_platform, _userId, _newScore);
        } else return false;

        return true;
        // check address of score to be updated
        // update specified score

    }

    function removePlatform(address _platform) public onlyOwner {
        // remove specified platform from reputation system
        //whitelistedPlatforms[_platform] = 0;
        platformAdmins[_platform] = 0x0;
    }

    // User needs to call approve on token address before calling
    // User can pay a fixed amount of Bees to boost reputation a marginal amount
    function boostReputationWithBees(address _platform, bytes32 _userId) public {
        ERC20 tokenContract = ERC20(beeTokenAddress);
        // needs to be updatable... Use state variable later
        require(reputation[_userId][_platform] > 0);
        if(reputation[_userId][_platform] < 30) {
            require(tokenContract.transferFrom(msg.sender, this, tokenPrice));
            reputation[_userId][_platform] = reputation[_userId][_platform] + 2;
        } else if(reputation[_userId][_platform] < 60) {
            require(tokenContract.transferFrom(msg.sender, this, tokenPrice));
            reputation[_userId][_platform] = reputation[_userId][_platform] + 1;
        } else revert();
    }

    function checkPlatfomReputation(address _platform, bytes32 _userId) public view returns(uint8 repScore) {
        // spit out the reputation score of an individual
        uint8 userScore = reputation[_userId][_platform];
        return userScore;
    }

    function checkAvgReputation(bytes32 _userId) public view returns(uint8 repScore) {
        uint8 avgScore = averageReputation[_userId];
        return avgScore;
    }
    /*
    // internal functions
    // TODO: iterate through rep scores and get average of non-zero rep scores
    function calculateAvgRepScore(bytes32 _userId) internal returns(uint8 repScore) {
        // iterate through sharing platforms to check for reputation scores.
        // skip scores of 0 and keep track of to how many sharing platforms the userId belongs
        uint8 repScoreSum
        for(uint256 i = 0, i < sharingPlatform.length; i++) {
            repScoreSum = repScoreSum.add(sharingPlatform[_userId][i])
        }
    }
    */
=======
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
>>>>>>> Init commit for BeeReputation

}

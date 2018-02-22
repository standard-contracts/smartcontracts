pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract BeePayments is Ownable { 
    
    
    using SafeMath for uint256;
    address public arbitrationAddress;
    uint256 public arbitrationFee;

    // add fee pool enum, or add mappings

    enum PaymentStatus {
        NOT_FOUND,      // payment does not exist
        INITIALIZED,    // awaiting payment from supply & demand entities
        IN_PROGRESS,    // awaiting dispatch time to pass, or a dispute
        IN_ARBITRATION, // dispute has been raised, to be handled by Arbitration
        CANCELED,       // payment canceled 
        COMPLETED       // payment successful 
    }

    // We can call functions inside of structs. Might be nice to have a callback in here
    struct PaymentStruct {
        bool exist;
        PaymentStatus paymentStatus;
        bytes32 paymentId; // keccak256 hash of all fields
        address paymentTokenContractAddress;
        address demandEntityAddress;
        address supplyEntityAddress;
        uint256 cost;
        uint256 securityDeposit;
        uint256 demandCancellationFee;
        uint256 supplyCancellationFee;
        uint64 cancelDeadlineInS;
        uint64 paymentDispatchTimeInS;
        bool demandPaid;
        bool supplyPaid;
    }

    event Pay(address user, bool paid, uint256 amount);
    event CancelPayment(address user, bytes32 paymentId, uint256 time);
    event DisputePayment(address user, bytes32 paymentId, uint256 time, uint256 amount);

    modifier demandOrSupplyEntity(bytes32 paymentId) {
        require(
            msg.sender == allPayments[paymentId].demandEntityAddress ||
            msg.sender == allPayments[paymentId].supplyEntityAddress
        );
        _;
    }

    modifier onlyPaymentStatus(bytes32 paymentId, PaymentStatus paymentStatus) {
        require(allPayments[paymentId].paymentStatus == paymentStatus);
        _;
    }

    modifier beforePaymentDeadline(bytes32 paymentId) {
        require(now <= paymentDeadlines[paymentId]);
        _;
    }
    // maps the paymentIds to the struct
    mapping (bytes32 => PaymentStruct) public allPayments;
    // maps paymentIds to payment deadline time in seconds
    mapping (bytes32 => uint64) public paymentDeadlines;

    function BeePayments(address arbitrationAddress_, uint256 arbitrationFee_) public {
        arbitrationAddress = arbitrationAddress_;
        arbitrationFee = arbitrationFee_;
    }

    function () public payable {
        revert();
    }

    function updateArbitrationAddress(address arbitrationAddress_) public onlyOwner {
        arbitrationAddress = arbitrationAddress_;
    }

    function updateArbitrationFee(uint256 arbitrationFee_) public onlyOwner {
        arbitrationFee = arbitrationFee_;
    }

    /**
     * Initializes a new payment, and awaits for supply & demand entities to
     * pay.
     * 
     * @return a payment id for the caller to keep.
     */
    function initPayment(
        bytes32 paymentId,
        address paymentTokenContractAddress,
        address demandEntityAddress,
        address supplyEntityAddress,
        uint256 cost,
        uint256 securityDeposit,
        uint256 demandCancellationFee,
        uint256 supplyCancellationFee,
        uint64 payDeadlineInS,
        uint64 cancelDeadlineInS,
        uint64 paymentDispatchTimeInS
    ) public onlyOwner returns(bool success)
    {
        if (allPayments[paymentId].exist) {
            revert();
        }
        require(cost > demandCancellationFee);

        allPayments[paymentId] = PaymentStruct(
            true,
            PaymentStatus.INITIALIZED,
            paymentId,
            paymentTokenContractAddress,
            demandEntityAddress,
            supplyEntityAddress,
            cost,
            securityDeposit,
            demandCancellationFee,
            supplyCancellationFee,
            cancelDeadlineInS,
            paymentDispatchTimeInS,
            false,
            false
        );
        paymentDeadlines[paymentId] = payDeadlineInS;

        return true;
    }

    /**
     * To be invoked after both parties approve transaction.
     */
    // must call approve on token contract to allow pay to transfer on their behalf
    function pay(
        bytes32 paymentId
    ) public
    onlyPaymentStatus(paymentId, PaymentStatus.INITIALIZED)
    beforePaymentDeadline(paymentId)
    returns (bool success)
    {
        PaymentStruct storage payment = allPayments[paymentId];
        ERC20 tokenContract = ERC20(payment.paymentTokenContractAddress);
        uint256 amountToPay = SafeMath.add(
            payment.securityDeposit,
            payment.cost
        );

        if (tokenContract.transferFrom(payment.demandEntityAddress, this, amountToPay) &&
        tokenContract.transferFrom(payment.supplyEntityAddress, this, payment.supplyCancellationFee)) {
            Pay(msg.sender, true, payment.supplyCancellationFee);
            Pay(msg.sender, true, amountToPay);
        }

        payment.supplyPaid = true;
        payment.demandPaid = true;

        if (payment.demandPaid && payment.supplyPaid) {
            payment.paymentStatus = PaymentStatus.IN_PROGRESS;
        }
        return true;
    }

    function dispatchPayment(bytes32 paymentId) public onlyPaymentStatus(paymentId, PaymentStatus.IN_PROGRESS) {
        PaymentStruct storage payment = allPayments[paymentId];
        ERC20 tokenContract = ERC20(payment.paymentTokenContractAddress);
        require(payment.paymentDispatchTimeInS <= now);
        
        uint256 supplyPayout = SafeMath.add(payment.supplyCancellationFee, payment.cost);
        uint256 demandPayout = payment.securityDeposit;
        
        if (tokenContract.transfer(payment.supplyEntityAddress, supplyPayout)
            && tokenContract.transfer(payment.demandEntityAddress, demandPayout)) {
            payment.paymentStatus = PaymentStatus.COMPLETED;
        }
    }
    /**
     * Dispatches in progress payments daily based on paymentDispatchTimeInS.
     * Get the list of inProgress payments mapping through backend. 
     */
    function dispatchPayments(bytes32[] paymentId) external {
        // check gas costs - limit iterating through every IN_PROGRESS payment
        for (uint32 i = 0; i < paymentId.length; i++) {
            dispatchPayment(paymentId[i]);
        }
    }

    /**
     * Cancels that payment in progress. Runs canclation rules as appropriate.
     * @return true if cancel is successful, false otherwise
     */
    function cancelPayment(bytes32 paymentId) public demandOrSupplyEntity(paymentId) onlyPaymentStatus(paymentId, PaymentStatus.IN_PROGRESS) returns(bool success) {
        PaymentStruct storage payment = allPayments[paymentId];
        ERC20 tokenContract = ERC20(payment.paymentTokenContractAddress);
        if (msg.sender == payment.demandEntityAddress) {
            // If demand entity cancels after deadline, only return security deposit
            if (payment.cancelDeadlineInS < now) {
                uint256 amountReturnedSupply = SafeMath.add(
                    payment.cost,
                    payment.supplyCancellationFee
                );
                if (tokenContract.transfer(payment.demandEntityAddress, payment.securityDeposit)
                    && tokenContract.transfer(payment.supplyEntityAddress, amountReturnedSupply)) {
                        payment.paymentStatus = PaymentStatus.CANCELED;
                        CancelPayment(msg.sender, paymentId, now);

                    }
                } else {
                    amountReturnedSupply = SafeMath.add(
                        payment.supplyCancellationFee,
                        payment.demandCancellationFee
                    );
                    uint256 costSubCancellationFee = SafeMath.sub(payment.cost, payment.demandCancellationFee);
                    uint256 amountReturnedDemand = SafeMath.add(
                        payment.securityDeposit,
                        costSubCancellationFee
                    );
                    if (tokenContract.transfer(payment.demandEntityAddress, amountReturnedDemand)
                        && tokenContract.transfer(payment.supplyEntityAddress, amountReturnedSupply)) {
                        payment.paymentStatus = PaymentStatus.CANCELED;
                        CancelPayment(msg.sender, paymentId, now);

                    }
                }
            } else {
                amountReturnedDemand = SafeMath.add(payment.cost,
                    SafeMath.add(
                        payment.securityDeposit,
                        payment.supplyCancellationFee
                    )
                );
                if (tokenContract.transfer(payment.demandEntityAddress, amountReturnedDemand)) {
                    payment.paymentStatus = PaymentStatus.CANCELED;
                    CancelPayment(msg.sender, paymentId, now);
                }
            return true;
        }
    }

    /**
     * Moves the in progress payment into arbitration.
     * Needs web3 approve call
     */

    function disputePayment(bytes32 paymentId) 
    public
    demandOrSupplyEntity(paymentId)
    onlyPaymentStatus(paymentId, PaymentStatus.IN_PROGRESS)
    returns(bool success)
    {
        PaymentStruct storage payment = allPayments[paymentId];
        ERC20 tokenContract = ERC20(payment.paymentTokenContractAddress);
        uint256 total = SafeMath.add(
            payment.securityDeposit,
            SafeMath.add(
                payment.cost,
                payment.supplyCancellationFee
            )
        );

        require(tokenContract.transferFrom(msg.sender, arbitrationAddress, arbitrationFee)
        && tokenContract.transfer(arbitrationAddress, total));
        payment.paymentStatus = PaymentStatus.IN_ARBITRATION;
        DisputePayment(msg.sender, paymentId, now, total);

        return true;
    }
    /**
     * Used to get all info about the payment.
     * @return all info of the payment, including payment id and status.
     */
    // Will not work until solidity version updates with #3272
    /*
    function getPaymentStatus(bytes32 paymentId) public view returns(PaymentStruct) {
        if (allPayments[paymentId].exist) {
            return allPayments[paymentId];
        } else {
            revert();
        }
    }
    */
}

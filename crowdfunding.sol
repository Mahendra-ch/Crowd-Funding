// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract CrowdFunding {

    address public owner;
    mapping (address => uint) public funders;
    uint public goal;
    uint public minAmount;
    uint public noOfFunders;
    uint public fundsRaised;
    uint public timeperiod;

    event Refunded(string msg);
    event RequestCreated(string msg);
    event VotedSuccssfully(string msg);
    event PaymentMade(string msg);

    constructor(uint _goal, uint _timeperiod) {
        goal = _goal;
        timeperiod = block.timestamp + _timeperiod;
        owner = msg.sender;
        minAmount = 1000 wei;
    }

    function contribution() public payable toCheckIfFundingIsStillOn() toCheckMinimumAmountCriteria() {
        if ( funders[msg.sender] == 0) {
            noOfFunders++;
        }
        funders[msg.sender] += msg.value;
        fundsRaised += msg.value;
    }

    receive() payable external {
        contribution();
    }

    function getRefund()  public toCheckifFunder() toCheckIfFundingIsStillOn() toCheckIfFundingIsSuccessfull() {
        payable(msg.sender).transfer(funders[msg.sender]);
        fundsRaised -= funders[msg.sender];
        funders[msg.sender] = 0;
        emit Refunded("Rufund Initited!");
    }

    struct Requests{
        string description;
        uint amount;
        address payable receiver;
        uint noOfVoters;
        mapping(address => bool) votes;
        bool completed;
    }

    mapping(uint => Requests) public AllRequests;
    uint public numReq;

    function createRequest(string memory _description,
                            uint _amount,
                            address payable _receiver) isOwner() public {
        Requests storage newReqest = AllRequests[numReq];
        numReq++;

        newReqest.description = _description;
        newReqest.amount = _amount;
        newReqest.receiver = _receiver;
        newReqest.completed = false;
        newReqest.noOfVoters = 0;

        emit RequestCreated("Request Created Successfully!");
     }

    function votingForRequest(uint reqNum)  public  toCheckifFunder() ifAlreadyVoted(reqNum)  {
        Requests storage thisRequest = AllRequests[reqNum];
        thisRequest.votes[msg.sender] == true;
        thisRequest.noOfVoters++;

        emit VotedSuccssfully("Voted Successfully!");
    }

    function makePayment(uint reqNum)  public isOwner() checkVotingIsInFavour(reqNum){
        Requests storage thisRequest = AllRequests[reqNum];
        thisRequest.receiver.transfer(thisRequest.amount);
        thisRequest.completed = true;
        
        emit PaymentMade("Payment made successfully!");
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    modifier checkVotingIsInFavour(uint reqNum) {
        Requests storage thisRequest = AllRequests[reqNum];
        require(thisRequest.noOfVoters >= noOfFunders/2, "Voting is not in favour!");
        _;
    }

    modifier toCheckifFunder() {
        require(funders[msg.sender] >= 0, "Not a Funder!");
        _;
    }

    modifier ifAlreadyVoted(uint reqNum) {
        Requests storage thisRequest = AllRequests[reqNum];
        require(thisRequest.votes[msg.sender] == false, "Already Voted!");
        _;
    }

    modifier toCheckIfFundingIsStillOn() {
        require(block.timestamp < timeperiod, "Funding is not on!");
        _;
    }

    modifier toCheckIfFundingIsSuccessfull() {
        require(fundsRaised < goal, "Funding was successful");
        _;
    }

    modifier toCheckMinimumAmountCriteria() {
            require(msg.value >= minAmount, "Minimum amount criteria is not satisfied!");
            _;
    }

}

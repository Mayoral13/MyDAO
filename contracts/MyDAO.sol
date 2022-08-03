pragma solidity ^0.8.11;
import "./DAOTOKEN.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyDAO is Ownable,AccessControl,ReentrancyGuard{ 
    DAOToken private Token;
    using Counters for Counters.Counter;
    using SafeMath for uint;

    constructor(address _tokenAddress){
        Token = DAOToken(_tokenAddress);
    }
    // List of the roles
    bytes32 public constant CFO = keccak256("CFO");
    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant COO = keccak256("COO");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMEBER");
    bytes32 public constant DIRECTOR_ROLE = keccak256("DIRECTOR");

    // The struct that will house our grant request
    struct Request{
        address payable candidate;
        string description;
        uint256 votingDuration;
        uint8 directorVotes;
        uint8 directorAgainst;
        uint8 membersVotes;
        uint8 membersAgainst;
        bool paid;
        bool won;
        uint256 id;
    }
    // Mappings for roles
    mapping(address => uint256)Purchased;
    mapping(uint256 => Request)Proposals;
    mapping(address => bool)private CLevel;
    mapping(address => bool)private Member;
    mapping(address => bool)private Director;
    mapping(uint256 => mapping(address => bool))Voted;
   // mapping(uint256 => mapping(address => uint8))MembersVotes;
   // mapping(uint256 => mapping(address => uint8))DirectorVotes;

    Counters.Counter private ID;
    Counters.Counter private MEMBER_COUNT;
    Counters.Counter private DIRECTOR_COUNT;

    uint private constant DIRECTOR_LEVEL = 1e12;
    uint private constant MEMBER_LEVEL = 1e5;

    // Access modifiers
    modifier CLevelRole(address _candidate){
        require(CLevel[_candidate] == false,"Address has a CLEVEL role");
        _;
    }
    modifier OnlyCEO(){
        require(hasRole(CEO,msg.sender),"You are not the CEO");
        _;
    }
    modifier OnlyCFO(){
        require(hasRole(CFO,msg.sender),"You are not the CFO");
        _;
    }
    modifier OnlyCOO(){
        require(hasRole(COO,msg.sender),"You are not the COO");
        _;
    }
    modifier OnlyMember(){
        require(hasRole(MEMBER_ROLE,msg.sender),"You are not a MEMBER");
        _;
    }
     modifier OnlyDirector(){
        require(hasRole(DIRECTOR_ROLE,msg.sender),"You are not a DIRECTOR");
        _;
    }

    function PurchaseTokens()external payable returns(bool success){
    require(msg.value >= 100,"Send at least 10000 wei");
    uint amount = msg.value.div(10000);
    _TokenTransfer(amount);
    Purchased[msg.sender].add(amount);
    return true;
    }

    function AssignCFO(address _candidate)external onlyOwner CLevelRole(_candidate) returns(bool success){
    _setupRole(CFO,_candidate);
     CLevel[_candidate] = true;
    return true;
    }
     function AssignCEO(address _candidate)external onlyOwner CLevelRole(_candidate) returns(bool success){
    _setupRole(CEO,_candidate);
     CLevel[_candidate] = true;
    return true;
    }
     function AssignCOO(address _candidate)external onlyOwner CLevelRole(_candidate) returns(bool success){
    _setupRole(COO,_candidate);
    CLevel[_candidate] = true;
    return true;
    }

     function StartProposal(address payable _beneficiary,string memory _description) external OnlyDirector() returns(bool success){
     ID.increment();
     uint count = ID.current();
     Proposals[count].candidate = _beneficiary;
     Proposals[count].description = _description;
     Proposals[count].votingDuration = 5 minutes;
     Proposals[count].id = count;
     return true;
    }

    function VoteForProposal(uint id) external OnlyMember OnlyDirector returns(bool success){
        
    }


    function AssignRole(address _candidate)external OnlyCEO OnlyCOO returns(bool success){
        if(Purchased[_candidate] < MEMBER_LEVEL){
            return true;
        }
        else if(Purchased[_candidate] >= MEMBER_LEVEL){
            require(!hasRole(MEMBER_ROLE,_candidate),"You are already a MEMBER");
            _setupRole(MEMBER_ROLE,_candidate);
            MEMBER_COUNT.increment();
            Member[_candidate] = true;
        }
        else if(Purchased[_candidate] >= DIRECTOR_LEVEL){
            require(!hasRole(DIRECTOR_ROLE,_candidate),"You are already a DIRECTOR");
            Member[_candidate] = false;
            _setupRole(DIRECTOR_ROLE,_candidate);
            DIRECTOR_COUNT.increment();
            Director[_candidate] = true;
        }
        return true;

    }

    function TokenBalance()public view returns(uint){
        return Purchased[msg.sender];
    }
    function _TokenTransfer(uint amount)internal returns(bool success){
        Token.transferFrom(address(this),msg.sender,amount);
        return true;
    }
   
  
    
    

}
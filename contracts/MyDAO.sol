pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyDAO is Ownable,AccessControl,ReentrancyGuard,ERC20{ 
    using SafeMath for uint;
    using Counters for Counters.Counter;
    
    constructor()
    ERC20("DAOTOKEN","DAOTOK"){
        
    }
    // ROLES AVALAIBLE
    bytes32 public constant CFO = keccak256("CFO");
    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant COO = keccak256("COO");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER");
    bytes32 public constant DIRECTOR_ROLE = keccak256("DIRECTOR");

    //STRUCT
    struct Request{
        bool paid;
        bool won;
        uint256 id;
        uint8 membersVotes;
        string description;
        uint8 directorVotes;
        uint8 membersAgainst;
        uint8 directorAgainst;
        uint256 votingDuration;
        address payable candidate;   
    }

    //ARRAY FOR ADDRESSES THAT REQUESTED A ROLE
    address[] private RoleRequest;

    // MAPPINGS
    mapping(uint256 => Request)Proposals;
    mapping(address => bool)private CLevel;
    mapping(address => bool)private Member;
    mapping(address => bool)private Director;
    mapping(address => bool)private Stakeholder;
    mapping(address => bool)private RequestedMember;
    mapping(address => bool)private RequestedDirector;
    mapping(uint256 => mapping(address => bool))Voted;
    
    // STATE VARIABLE DECLARATION
    Counters.Counter private ID;
    Counters.Counter private MEMBER_COUNT;
    Counters.Counter private DIRECTOR_COUNT;
    
    uint256 private MEMBER_LEVEL = 100;
    uint256 private VOTING_AMOUNT = 10;
    uint256 private DIRECTOR_LEVEL = 1000;
    uint8 private MEMBER_VOTING_WEIGHT = 1; 
    uint8 private DIRECTOR_VOTING_WEIGHT = 2;
    uint256 private VOTING_DURATION = 5 minutes;

    //EVENTS
    event donate(address indexed by,uint amount,uint when);
    event withdraw(address indexed by,uint amount,uint when);
    event purchaseTokens(address indexed candidate,uint amount,uint when);
    event assignCEO(address indexed candidate,address indexed by,uint when);
    event assignCFO(address indexed candidate,address indexed by,uint when);
    event assignCOO(address indexed candidate,address indexed by,uint when);
    event assignRole(address indexed candidate,address indexed by,uint when);
    event voteProposal(address indexed candidate,uint ID,bool vote,uint when);
    event createProposal(address indexed candidate,string description,uint when);
    event revokeCLevelRole(address indexed candidate,address indexed by,uint when);
    
    

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
    modifier OnlyStakeholder(){
        require(Stakeholder[msg.sender] == true,"You are not a MEMBER");
        _;
    }
     modifier OnlyDirector(){
        require(hasRole(DIRECTOR_ROLE,msg.sender),"You are not a DIRECTOR");
        _;
    }
    modifier EitherCEOorCOO(){
        require(hasRole(COO,msg.sender) || hasRole(CEO,msg.sender) == true,"You are not a CEO or COO");
        _;
    }
    
    //FUNCTION TO PURCHASE TOKENS
    function PurchaseTokens()external payable returns(bool success){
    require(msg.value <= 100000 wei,"You cannot send more than 100000 wei");
    uint amount = msg.value.div(100);
    _mint(msg.sender,amount);
    emit purchaseTokens(msg.sender,amount,block.timestamp);
    return true;
    }
    
    //FUNCTION TO ASSIGN CFO ROLE ONLY OWNER CAN ASSIGN
    function AssignCFO(address _candidate)external onlyOwner CLevelRole(_candidate) returns(bool success){
    require(_candidate != msg.sender,"You cannot take on a CLevelRole");
    _grantRole(CFO,_candidate);
     CLevel[_candidate] = true;
     emit assignCFO(_candidate,msg.sender,block.timestamp);
    return true;
    }
    //FUNCTION TO ASSIGN CEO ROLE ONLY OWNER CAN ASSIGN
     function AssignCEO(address _candidate)external onlyOwner CLevelRole(_candidate) returns(bool success){
    require(_candidate != msg.sender,"You cannot take on a CLevelRole");
    _grantRole(CEO,_candidate);
     CLevel[_candidate] = true;
     emit assignCEO(_candidate,msg.sender,block.timestamp);
    return true;
    }
    //FUNCTION TO ASSIGN COO ROLE ONLY OWNER CAN ASSIGN
     function AssignCOO(address _candidate)external onlyOwner CLevelRole(_candidate) returns(bool success){
    require(_candidate != msg.sender,"You cannot take on a CLevelRole");
    _grantRole(COO,_candidate);
    CLevel[_candidate] = true;
    emit assignCOO(_candidate,msg.sender,block.timestamp);
    return true;
    }
     
     //FUNCTION TO START A PROPOSAL THE TYPE OF PROPOSAL
     //DEPENDS ON THE DESCRIPTION 
     //IE IF ITS A CHARITY THE DESCRIPTION WILL SAY CHARITY 
     //IF ITS FOR A DECISION THE DESCRIPTION WILL SAY 
     function CreateProposal(address payable _beneficiary,string memory _description) external OnlyDirector returns(bool success){
     ID.increment();
     uint count = ID.current();
     Proposals[count].candidate = _beneficiary;
     Proposals[count].description = _description;
     Proposals[count].votingDuration = block.timestamp.add(5 minutes);
     Proposals[count].id = count;
     emit createProposal(_beneficiary,_description,block.timestamp);
     return true;
    }
     
     //VOTE FOR A PROPOSAL
    function VoteForProposal(uint id, bool vote) external OnlyStakeholder{
     require(Proposals[id].candidate != address(0),"Proposal does not exist");
     require(balanceOf(msg.sender) >= VOTING_AMOUNT,"Insufficient token balance");
     require(Proposals[id].votingDuration > block.timestamp,"Voting has already ended");
     require(Voted[id][msg.sender] == false,"You can vote only once");
     Voted[id][msg.sender] = true;
     uint256 FOR;
     uint256 AGAINST;
     if(Member[msg.sender] == true && vote == true){
        _Vote();
        Proposals[id].membersVotes + MEMBER_VOTING_WEIGHT;
        FOR += MEMBER_VOTING_WEIGHT;
     }
      if(Member[msg.sender] == true && vote == false){
        _Vote();
        Proposals[id].membersAgainst + MEMBER_VOTING_WEIGHT;
        AGAINST += MEMBER_VOTING_WEIGHT;
     }
      if(Director[msg.sender] == true && vote == true){
        _Vote();
        Proposals[id].directorVotes + DIRECTOR_VOTING_WEIGHT;
        FOR += DIRECTOR_VOTING_WEIGHT;
     }
      if(Director[msg.sender] == true && vote == false){
        _Vote();
        Proposals[id].directorAgainst + DIRECTOR_VOTING_WEIGHT;
       AGAINST += DIRECTOR_VOTING_WEIGHT;
     }
     _COLLATION(id, FOR, AGAINST);
     emit voteProposal(msg.sender,id,vote,block.timestamp);
     return true;
    }
    //FUNCTION TO COLLATE RESULT OF VOTE AND DECIDE OUTCOME 
    function _COLLATION(uint id,uint _for,uint _against) internal returns(bool success){
        require(block.timestamp > Proposals[id].votingDuration);
      if(_for > _against){
        Proposals[id].won = true;
      }
      else Proposals[id].won = false;
       return true; 
    }
      //FUNCTION FOR VOTING FOR A PROPOSAL
      function _Vote()internal returns(bool success){
        transfer(address(this),VOTING_AMOUNT);
        return true;
    } 
   
    //FUNCTION TO ASSIGN ROLE ITS BASED ON NUMBER OF TOKENS BOUGHT
    function AssignMemberRole(address _candidate)external EitherCEOorCOO CLevelRole(_candidate) returns(bool success){
        require(RequestedMember[_candidate] == true,"Request Member Role First");
        require(Stakeholder[_candidate] == false,"You are already a Stakeholder");
        require(!hasRole(MEMBER_ROLE,_candidate),"You are already a MEMBER");
            _grantRole(MEMBER_ROLE,_candidate);
            RoleRequest.pop();
            MEMBER_COUNT.increment();
            Stakeholder[_candidate] = true;
            emit assignRole(_candidate,msg.sender,block.timestamp);
            return true;
        }

         function AssignDirectorRole(address _candidate)external EitherCEOorCOO CLevelRole(_candidate) returns(bool success){
        require(RequestedDirector[_candidate] == true,"Request Director Role First");
        require(Stakeholder[_candidate] == false,"You are already a Stakeholder");
        require(!hasRole(DIRECTOR_ROLE,_candidate),"You are already a MEMBER");
        _revokeRole(MEMBER_ROLE,_candidate);
         _grantRole(DIRECTOR_ROLE,_candidate);
            RoleRequest.pop();
            DIRECTOR_COUNT.increment();
            Stakeholder[_candidate] = true;
            emit assignRole(_candidate,msg.sender,block.timestamp);
            return true;
        }
    
        
        //FUNCTION TO REVOKE CLEVEL ROLE ONLY COO CEO AND OWNER CAN CALL IT
    function RevokeCLevelRole(address _candidate)external EitherCEOorCOO returns(bool success){
        require(CLevel[_candidate] == true,"Address must have a CLevel role");
        if(hasRole(COO,_candidate)){
            _revokeRole(COO,_candidate);
        }
        if(hasRole(CFO,_candidate)){
            _revokeRole(CFO,_candidate);
        }
        if(hasRole(CEO,_candidate)){
            _revokeRole(CEO,_candidate);
        }
        emit revokeCLevelRole(_candidate,msg.sender,block.timestamp);
        return true;
    }
    //FUNCTION TO VIEW PROPOSAL DETAILS
    function ViewProposal(uint id)public view returns
    ( uint256 _id,
    address _candidate,
    string memory _description,
    uint8 _membersVotes,
    uint8 _membersAgainst,
    uint8 _directorVotes,
    uint8 _directorAgainst,
    uint256 _votingDuration,
    bool _paid,
    bool _won )
    {
    require(Proposals[id].candidate != address(0),"Proposal does not exist");
    _id = Proposals[id].id;
    _candidate = Proposals[id].candidate;
    _description = Proposals[id].description;
    _membersVotes = Proposals[id].membersVotes;
    _membersAgainst = Proposals[id].membersAgainst;
    _directorVotes = Proposals[id].directorVotes;
    _directorAgainst = Proposals[id].directorAgainst;
    _votingDuration = Proposals[id].votingDuration;
    _paid = Proposals[id].paid;
    _won = Proposals[id].won;  
    }
    
    //FUNCTION TO WITHDRAW ETHER ONLY CFO CAN USE
    function Treasury(address payable _to,uint amount)external OnlyCFO returns(bool success){
    require(amount <= address(this).balance);
    (success) = _to.send(amount);
    require(success);
    emit withdraw(msg.sender,amount,block.timestamp);
    return true;
    }
    
    //FUNCTION TO ACCEPT ETHER
    function Donate()public payable{
     emit donate(msg.sender,msg.value,block.timestamp);

    } 
    //FUNCTION TO VIEW TOKEN BALANCE OF USER
    function TokenBalance()public view returns(uint){
        return balanceOf(msg.sender);
    }
    
    //FUNCTION TO CHECK STAKEHOLDER ROLE
    function CheckRole(address _candidate)public view returns(string memory ROLE){
        require(Stakeholder[_candidate] == true,"User is not a stakeholder");
        if(hasRole(MEMBER_ROLE,_candidate)){
            return " : MEMBER";
        }
         if (hasRole(DIRECTOR_ROLE,_candidate)){
            return " : DIRECTOR";
        }

    }
    //FUNCTION TO REQUEST STAKEHOLDER ROLE
    function RequestMemberRole()CLevelRole(msg.sender) external returns(bool success){
    require(RequestedMember[msg.sender] == false,"You have requested a role");
    require(balanceOf(msg.sender) >= MEMBER_LEVEL,"You have not reached the Token requirements");
    RoleRequest.push(msg.sender);
    RequestedMember[msg.sender] = true;
    return true;
    }

    function RequestDirectorRole()CLevelRole(msg.sender) external returns(bool success){
    require(RequestedDirector[msg.sender] == false,"You have requested a role");
    require(balanceOf(msg.sender) >= DIRECTOR_LEVEL,"You have not reached the Token requirements");
    RoleRequest.push(msg.sender);
    RequestedDirector[msg.sender] = true;
    return true;
    }

    //VIEW ADDRESSES THAT REQUESTED A ROLE
    function RoleRequesters()public view returns(address[]memory){
        return RoleRequest;
    }

}
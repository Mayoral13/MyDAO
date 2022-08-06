const DAO = artifacts.require("MyDAO");
let catchRevert = require("../execption").catchRevert;
contract("MyDAO",(accounts)=>{

    let OWNER = accounts[0];
    let CEO = accounts[1];
    let COO = accounts[2];
    let CFO = accounts[3];
    let MEMBER1 = accounts[4];
    let MEMBER2 = accounts[5]; //USELESS
    let MEMBER3 = accounts[6];
    let DIRECTOR1 = accounts[7];
    let DIRECTOR2 = accounts[8]; //USELESS
    let DIRECTOR3 = accounts[9];

    it("Should deploy successfully",async()=>{
        const alpha = await DAO.deployed();
        console.log("Deployed Address is :",alpha.address.toString());
        assert(alpha.address != "");
    });
    it("Token name should be correct",async()=>{
        const expected = "DAOTOKEN";
        const alpha = await await DAO.deployed();
        const beta = await alpha.name();
        console.log("The Token name is :",beta.toString());
        assert.equal(beta,expected);
   });
   it("Token symbol should be correct",async()=>{
       const expected = "DAOTOK";
       const alpha = await DAO.deployed();
       const beta = await alpha.symbol();
       console.log("The Token symbol is :",beta.toString());
       assert.equal(beta,expected);
    });
    it("Can purchase tokens",async()=>{
       const expected = 100;
       const alpha = await DAO.deployed();
       const beta = await alpha.PurchaseTokens({from:MEMBER1,value:10000});
       const gamma = await alpha.balanceOf(MEMBER1);
       assert.equal(expected,gamma);
    });
    it("Should revert if non owner tries to assign CEO",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.AssignCEO(CEO,{from:MEMBER1}));
    });
    it("Should revert if non owner tries to assign COO",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.AssignCOO(COO,{from:MEMBER1}));
    });
    it("Should revert if non owner tries to assign CFO",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.AssignCEO(CFO,{from:MEMBER1}));
    });
    it("Can assign CEO",async()=>{
        const role = web3.utils.keccak256("CEO");
        const alpha = await DAO.deployed();
        const beta = await alpha.AssignCEO(CEO,{from:OWNER});
        const gamma = await alpha.hasRole(role,CEO);
        assert.equal(gamma,true);
    });
    it("Can assign COO",async()=>{
        const role = web3.utils.keccak256("COO");
        const alpha = await DAO.deployed();
        const beta = await alpha.AssignCOO(COO,{from:OWNER});
        const gamma = await alpha.hasRole(role,COO);
        assert.equal(gamma,true);
    });
    it("Can assign CFO",async()=>{
        const role = web3.utils.keccak256("CFO");
        const alpha = await DAO.deployed();
        const beta = await alpha.AssignCFO(CFO,{from:OWNER});
        const gamma = await alpha.hasRole(role,CFO);
        assert.equal(gamma,true);
    });
    it("Should revert when owner tries to assign a CLevel role again to same user",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.AssignCEO(COO,{from:OWNER}));
    });
    it("Should revert if non director creates proposal",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.CreateProposal(OWNER,"should fail",{from:OWNER}));
    });
    it("Cannot Request member role if balance is below 100 tokens",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.RequestMemberRole({from:MEMBER2}));
    });
    it("Should revert if CLevel requests Member role",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.RequestMemberRole({from:CEO}));
    });
    it("Should revert if CLevel requests Director role",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.RequestDirectorRole({from:COO}));
    });
 
    it("Only CEO/COO can assign MEMBER/DIRECTOR role",async()=>{
        const role = web3.utils.keccak256("MEMBER");
        const alpha = await DAO.deployed();
        const ray = await alpha.RequestMemberRole({from:MEMBER1});
        const beta = await alpha.AssignMemberRole(MEMBER1,{from:CEO});
        const gamma = await alpha.hasRole(role,MEMBER1);
        assert.equal(gamma,true);
    });
    it("Either CEO/COO can revoke CLevel role",async()=>{
        const role = web3.utils.keccak256("COO");
        const alpha = await DAO.deployed();
        const beta = await alpha.RevokeCLevelRole(COO,{from:CEO});
        const gamma = await alpha.hasRole(role,COO);
        assert.equal(gamma,false); 
    });
    it("CFO cannot revoke CLevel role",async()=>{
        const role = web3.utils.keccak256("CEO");
        const alpha = await DAO.deployed();
        await catchRevert(alpha.RevokeCLevelRole(CEO,{from:CFO}));
    });
    it("Should revert if not CFO tries to access treasury",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.Treasury(MEMBER1,10,{from:MEMBER1}));
    });
    it("Only CFO can access treasury",async()=>{
        const alpha = await DAO.deployed();
        const before = await web3.eth.getBalance(alpha.address)
        const beta = await alpha.Treasury(MEMBER1,10,{from:CFO});
        const after = await web3.eth.getBalance(alpha.address)
        assert(before != after);
    });
    it("Can Check role assigned",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.CheckRole(MEMBER1,{from:MEMBER1});
        console.log("Assigned role is : ",beta.toString());
        assert(beta != "");
    });
    it("Should revert if non member/director checks role",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.CheckRole(MEMBER2,{from:MEMBER2}));
    });
    it("Should revert if user request Director role without passing requirement",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.RequestDirectorRole({from:DIRECTOR2}));
    });
    it("Can assign Director role",async()=>{
        const role = web3.utils.keccak256("DIRECTOR");
        const alpha = await DAO.deployed();
        const sama = await alpha.PurchaseTokens({from:DIRECTOR1,value:100000});
        const ray = await alpha.RequestDirectorRole({from:DIRECTOR1});
        const beta = await alpha.AssignDirectorRole(DIRECTOR1,{from:CEO});
        const gamma = await alpha.hasRole(role,DIRECTOR1);
        assert.equal(gamma,true);
    });
    it("Director can check role",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.CheckRole(DIRECTOR1,{from:DIRECTOR1});
        console.log("Assigned role is : ",beta.toString());
        assert(beta != "");
    });
    it("Should revert if Member creates proposal",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.CreateProposal(MEMBER1,"FAIL HARD",{from:MEMBER1}));
    });
    it("Director can create proposal",async()=>{
        const alpha = await DAO.deployed();
        await alpha.CreateProposal(DIRECTOR1,"SHOULD PASS",{from:DIRECTOR1});
    });
    it("Should revert if user tries to view proposal that does not exist",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.ViewProposal(43));
    });
    it("Should revert if user tries to view proposal with id 0",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.ViewProposal(0));
    });
    it("Should revert only Member can for proposal",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.VoteProposalMember(1,true,{from:MEMBER2}));
    });
    it("Only member can vote using VoteProposalMember",async()=>{
        const alpha = await DAO.deployed();
        const balancebefore = await alpha.balanceOf(MEMBER1);
        const beta = await alpha.VoteProposalMember(1,true,{from:MEMBER1});
        const balanceafter =  await alpha.balanceOf(MEMBER1);
        assert(balancebefore != balanceafter);
        
    });
    it("Only Director can vote using VoteProposalDirector",async()=>{
        const alpha = await DAO.deployed();
        const balancebefore = await alpha.balanceOf(MEMBER1);
        const beta = await alpha.VoteProposalDirector(1,true,{from:DIRECTOR1});
        const balanceafter =  await alpha.balanceOf(DIRECTOR1);
        assert(balancebefore != balanceafter);
    });
    it("Should revert if Member votes with VoteProposalDirector",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.VoteProposalDirector(1,true,{from:MEMBER1}));
    });
    it("Should revert if Director votes with VoteProposalMember",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.VoteProposalMember(1,true,{from:DIRECTOR1}));
    });
    it("Should revert if member tries to vote twice",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.VoteProposalMember(1,true,{from:MEMBER1}));
    });
    it("Should revert if Director tries to vote twice",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.VoteProposalDirector(1,true,{from:DIRECTOR1}));
    });
    it("Should revert if user tries to vote for proposal with id that does not exist",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.VoteProposalDirector(100,true,{from:DIRECTOR1}));
    });
    it("User can view proposals",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.ViewProposal(1);
        assert(beta != "");
    });
    it("Can show addresses of users that requested Member role",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.PurchaseTokens({from:MEMBER3,value:10000});
        const gamma = await alpha.RequestMemberRole({from:MEMBER3});
        const ray = await alpha.MemberRoleRequesters();
        console.log("Address of users that requested is :",ray.toString());
        assert(ray != "");
    });
    it("Can show addresses of users that requested Director role",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.PurchaseTokens({from:DIRECTOR3,value:100000});
        const gamma = await alpha.RequestDirectorRole({from:DIRECTOR3});
        const ray = await alpha.DirectorRoleRequesters();
        console.log("Address of users that requested is :",ray.toString());
        assert(ray != "");
    });
    it("Should remove address of member role requester after assigned role",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.AssignMemberRole(MEMBER3,{from:CEO});
        const gamma = await alpha.MemberRoleRequesters();
        assert(gamma == "");
    });
    it("Should remove address of director role requester after assigned role",async()=>{
        const alpha = await DAO.deployed();
        const beta = await alpha.AssignDirectorRole(DIRECTOR3,{from:CEO});
        const gamma = await alpha.DirectorRoleRequesters();
        assert(gamma == "");
    });
    it("Can Donate",async()=>{
        const alpha = await DAO.deployed();
        const balancebefore = await web3.eth.getBalance(alpha.address);
        const beta = await alpha.Donate({value:1000000});
        const balanceafter = await  await web3.eth.getBalance(alpha.address);
        assert(balancebefore != balanceafter);
    });
    it("Cannot collate result of proposal that does not exist",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.COLLATION(100));
    });
    it("Should revert if user tries to collate result when time is not up",async()=>{
        const alpha = await DAO.deployed();
        await catchRevert(alpha.COLLATION(1));
    });

});




  

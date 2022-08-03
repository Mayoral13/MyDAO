pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract DAOToken is ERC20,Ownable{
    constructor(uint amount)
    ERC20("DAOTOKEN","DAOTOK"){
        _mint(msg.sender,amount);
        
    }

}
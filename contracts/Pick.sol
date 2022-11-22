// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev Pick token.
 */
contract Pick is ERC20, ERC20Burnable, Ownable , Pausable {
    // minter.
    address public minter;
    
    // Emitted when set the minter.
    event SetMinter(address _old , address _new);

    constructor() ERC20("Meet48 PICK", "PICK") {
        minter = msg.sender;
    }

    /**
     * @dev Set the minter.
     */ 
    function setMinter(address _minter) external onlyOwner {
        emit SetMinter(minter , minter = _minter);
    }


    /**
     * @dev Triggers stopped state.
     */    
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev mint.
     */ 
    function mintTo(address to , uint256 amount) external whenNotPaused {
        require(minter == msg.sender , "Pick: Caller unauthorized");
        require(to != address(0) , "Pick: Zero address");
        _mint(to, amount);
    }



}
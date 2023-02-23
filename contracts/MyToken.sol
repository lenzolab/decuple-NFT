// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Decuple is ERC721, Pausable, Ownable {
    constructor() ERC721("Decuple NFT", "CDPN") {}



    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                     Mint                                        ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    
        function safeMint(address to, uint256 tokenId) public onlyOwner {
            _safeMint(to, tokenId);
        }

        function mint(uint256 tokenId) public {
            address sndr = msg.sender;

            _safeMint(to, tokenId);

        }
    //  =============== END of Mint

    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                 Payments                                        ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    

        IERC busd, usdc, usdt, fourth, fifth, sixth;


        
    //  =============== END of Mint



    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                   Administrative                                ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //
        function pause() public onlyOwner {
            _pause();
        }

        function unpause() public onlyOwner {
            _unpause();
        }


        function _beforeTokenTransfer(address from, address to, uint256 tokenId)
            internal
            whenNotPaused
            //override
        {
            super._beforeTokenTransfer(from, to, tokenId, 1);
        }

    //  =============== END of Administration

}

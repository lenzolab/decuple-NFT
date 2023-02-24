// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";


contract Decuple is ERC721, ContextMixin, NativeMetaTransaction, Pausable, Ownable {

    constructor() ERC721("Decuple NFT", "CDPN") {
        isMinted = new bool[](maxSupply+1);
        setBaseTokenURI("https://ipfs.io/ipfs/QmR5N9289NPeTnVRjwRs7oMELGkshn52k31wXnn7aFesfn/");

    }
    


    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                  Token Specs                                    ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    

        // ==========  FOR MAINNET ------------------------------------------------------------------------------------------------------------------
            // // Tiers prices Legendary - epic - rare - common   ---  in the 10**10
            // uint256[] public tiersPrices = [4000000000000000000000, 2000000000000000000000, 1000000000000000000000, 500000000000000000000];
            // //                               4000 USD                2000 USD                1000 USD                500 USD
            // // Number of avaliable tokens:   555                     1000                    2000                    5000
            // // Token tier index
            // uint256[] public ind = [5000,7000,8000,8555];

            // uint256 public maxSupply = 8555;
            // uint256 public totalSupply = 0;
        // ------------------------------------------------------------------------------------------------------------------

        // ==========  FOR TESTNET

            // baseTOkenURI for the 21 warriors NFT collection metadate IPFS folder:
            // https://ipfs.io/ipfs/QmR5N9289NPeTnVRjwRs7oMELGkshn52k31wXnn7aFesfn
            // https://gateway.pinata.cloud/ipfs/QmR5N9289NPeTnVRjwRs7oMELGkshn52k31wXnn7aFesfn/

            // Tiers prices Legendary - epic - rare - common   ---  in the 10**10
            uint256[] public tiersPrices = [400000000000000000, 200000000000000000, 100000000000000000, 50000000000000000];
            //                               0.4 USD                0.2 USD                0.1 USD                0.05 USD
            // Number of avaliable tokens:   3                      4                      6                      8
            // Token tier index
            uint256[] public ind = [8,14,18,21];

            uint256 public maxSupply = 21;
            uint256 public totalSupply = 0;
        //










        function getTokenTier(uint256 id) public view returns (uint256){
            require(id > 0, "No such a token");
            require(id <= maxSupply, "No such a token");
            if (id<=ind[0]) {
                return 4;
            }
            if (id<=ind[1]) {
                return 3;
            }
            if (id<=ind[2]) {
                return 2;
            }
            if (id<=ind[3]) {
                return 1;
            }
            return 0;
        }

        function setPrices(uint256[] memory prices) public onlyOwner {
            require(prices.length == 4);
            tiersPrices = prices;
        }



        //  ==========================   TOKEN  URI   ==========================

            string public _baseTokenURI ;

            function setBaseTokenURI(string memory URI) public onlyOwner {
                _baseTokenURI = URI;
            }

            function baseTokenURI() public view returns(string memory){
                return _baseTokenURI;
            }

            function tokenURI(uint256 tokenId) override public view returns (string memory) {
                return string(abi.encodePacked(baseTokenURI(),
                        Strings.toString(tokenId),
                        ".json")
                        ); 
            }

        //

    //  =============== END of Token Specs


    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                     Mint                                        ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    

        // Indicates the token has been minted or not;
        bool[] public isMinted;

        function getMinted() public view returns(bool[] memory){
            return isMinted;
        }

        function safeMint(address to, uint256 tokenId) public onlyOwner {
            require(!_exists(tokenId), "ERC721: token already minted");
            getTokenTier(tokenId);
            _safeMint(to, tokenId);
            totalSupply ++;
            isMinted[tokenId]=true;
        }


        /*
        *   @dev Mint by paying stable coins (On a third-party ERC20 token Contract).
        */
        function mint(uint256 tokenId, uint256 currency) public  whenNotPaused{
            require(AC[currency], "Currency is not allowed.");
            require(!_exists(tokenId), "ERC721: token already minted");

            uint256 mintFee =  tiersPrices[getTokenTier(tokenId)-1];
            address to = tx.origin;
            
            // Paying fee
            bool result = makePayment(to,mintFee,currency);
            
            // operation
            if(result){
                // Minting
                _safeMint(to, tokenId);
                totalSupply ++;
                isMinted[tokenId]=true;

                // Referral action
                if(referralIsOn){
                    RC.newMint(to);
                }
            }
        }


        /*
        *   @dev Mint by paying stable coins and claiming a Referral code
        */
        function mintWithCode(uint256 tokenId, uint256 currency, uint256 code) public whenNotPaused {
            require(AC[currency], "Currency is not allowed.");
            require(!_exists(tokenId), "ERC721: token already minted");
            
            uint256 mintFee =  tiersPrices[getTokenTier(tokenId)-1];
            address to = tx.origin;
            
            // Paying fee
            bool result = makePayment(to,mintFee,currency);
            
            // operation
            if(result){
                // Minting
                _safeMint(to, tokenId);
                totalSupply ++;
                isMinted[tokenId]=true;
                // Referral action
                if(referralIsOn){
                    RC.newMintWithCode(code, to);
                }
            }
        }


        // ========================= REFERRAL CONTRACT =========================

            // Defines the referral program is on or off.
            bool public referralIsOn = false;

            function swithReferral(bool isOn) public onlyOwner {
                referralIsOn = isOn;
            }


            ReferralContract RC;
            address public referralAddress;

            function setRCAddress(address adr) public onlyOwner{
                referralAddress = adr;
                RC = ReferralContract(referralAddress);
            }

            /*      
            *   @dev Returns the amount of referal bonus for the refered. ( referred is the new minter who is 
            *   using the referral code.)
            */
            function inquiry(uint256 code) public view returns(uint256){
                return RC.inquiry(code);
            }
        //

    //  =============== END of Mint


    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                 Payments                                        ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    
        /*
        *   @Dev Pays the fee on a third-party ERC20 contract
        */
        function makePayment (address from, uint256 amount, uint256 currency) internal returns (bool){
            if (currency == 0) {
                return BUSD.transferFrom(from, address(this), amount);
            } 

            if (currency == 1) {
                return USDT.transferFrom(from, address(this), amount);
            } 

            if (currency == 2) {
                return USDC.transferFrom(from, address(this), amount);
            } 

            if (currency == 3) {
                return THIRD.transferFrom(from, address(this), amount);
            } 

            if (currency == 4) {
                return FORTH.transferFrom(from, address(this), amount);
            } 

            if (currency == 5) {
                return FIFTH.transferFrom(from, address(this), amount);
            } 

            return false;
            
        }
 
        /*
        *   @Dev >> Allowed Currencies << for payment
        */
        bool[] public AC = [true,true,true,false,false,false];

        // function getetAllowedCurrencies () public view returns (bool[] memory){
        //     return allowedCurrencies;
        // }

        function setAllowedCurrencies (bool[] memory alwd) public onlyOwner{
            AC = alwd;
        }

        IERC20 BUSD;
        IERC20 USDT;
        IERC20 USDC;
        IERC20 THIRD;
        IERC20 FORTH;
        IERC20 FIFTH;

        function setPaymentContracts(address busd, address usdt, address usdc, address third, address forth, address fifth) public onlyOwner {
            BUSD = IERC20(busd);
            USDT = IERC20(usdt);
            USDC = IERC20(usdc);
            THIRD = IERC20(third);
            FORTH = IERC20(forth);
            FIFTH = IERC20(fifth);
        }
        

        
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



    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                Proxy registery                                  ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    

        address proxyRegistryAddress;

        /**
        * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
        */
        function isApprovedForAll(address owner, address operator)
            override
            public
            view
            returns (bool)
        {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }

            return super.isApprovedForAll(owner, operator);
        }

        /**
        * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
        */
        function _msgSender()
            internal
            override
            view
            returns (address sender)
        {
            return ContextMixin.msgSender();
        }
    //  =============== END of Proxy registery    




    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                                Easy Transfer                                    ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //    

        // Easy transfer fee:
        // [0]: Legendary fee - [1]: Epic fee - [2]: Rare fee - [3]: Common fee
        // [0]: 0.01 BNB - [1]: 0.005 BNB - [2]: 0.003 BNB - [3]: 0.001 BNB
        uint256[] public easyFee =[10000000000000000, 5000000000000000, 3000000000000000, 1000000000000000];

        function easyTransferTo(address to, uint256 id) public payable whenNotPaused {
            uint256 fee = easyFee[getTokenTier(id)-1];
            require(msg.value == fee,"ERC721: service fee is not correct");
            require(tx.origin == ownerOf(id),"Sender is not the Owner");
            
            safeTransferFrom(tx.origin, to, id);
        }

        function setEasyFees(uint256[] memory prices) public onlyOwner {
            require(prices.length == 4);
            easyFee = prices;
        }
    //  =============== END of Easy Transfer 



}




    //╔═════════════════════════════════════════════════════════════════════════════════╗
    //║                                                                                 ║
    //║                          External Contracts Interfaces                          ║
    //║                                                                                 ║
    //╚═════════════════════════════════════════════════════════════════════════════════╝
    //

        // ========================= REFERRAL CONTRACT =========================

            interface ReferralContract {
                function inquiry(uint256 code) external view returns (uint256);

                function isCodeValid(uint256 code) external  view returns (bool);

                function newMintWithCode(uint256 code, address ED) external;

                function newMint(address adr) external;
            }
        //


        // ========================= PROXY REGISTERY =========================

            // This part is for proxy registry wich will be used for gass free marketplace operations

            contract OwnableDelegateProxy {}

            /**
            * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
            */
            contract ProxyRegistry {
                mapping(address => OwnableDelegateProxy) public proxies;
            }   
        //
    //
// SPDX-License-Identifier: MIT
//
// ███████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ ███████╗██████╗ ███████╗     ██████╗ ███████╗
// ██╔════╝██╔═══██╗██║   ██║████╗  ██║██╔══██╗██╔════╝██╔══██╗██╔════╝    ██╔═══██╗██╔════╝
// █████╗  ██║   ██║██║   ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝███████╗    ██║   ██║█████╗  
// ██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗╚════██║    ██║   ██║██╔══╝  
// ██║     ╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝███████╗██║  ██║███████║    ╚██████╔╝██║     
// ╚═╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═╝     
//  
// ███████╗ ██████╗     ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗                          
// ╚══███╔╝██╔═══██╗    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗                         
//   ███╔╝ ██║   ██║    ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║                         
//  ███╔╝  ██║   ██║    ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║                         
// ███████╗╚██████╔╝    ╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝                         
// ╚══════╝ ╚═════╝      ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝                          
//

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC721A.sol";


contract Founder is Ownable, ERC721A, ReentrancyGuard {
    bool public frozen;
    
    uint256 public immutable teamMintMax = 1111;

    uint256 public teamMinted;
    uint256 public publicMax;
    uint256 public pricePerMint;

    bytes32 public merkleRoot;
    uint256 public earlyAccessStart;
    uint256 public purchaseStart;

    string private tokenBaseURI;
    string private tokenBaseURIExt;
    uint256 private immutable preSaleMaxMint = 4;
    
    constructor(
    ) ERC721A(
        "Founders of Zo World", 
        "\\z/", 
        10, 
        11111
    ) {}

    function tokenURI(
        uint256 tokenId
    ) public view override returns (
        string memory
    ) {
        require(
            _exists(tokenId),
            "Nonexistent token"
        );
        return string(
            abi.encodePacked(
                tokenBaseURI, 
                Strings.toString(tokenId), 
                tokenBaseURIExt
            )
        );
    }

    function mint(
        uint256 amount
    ) external payable {
        require(
            block.timestamp >= purchaseStart,
            "sale hasn't started"
        );
        _mintPublic(
            _msgSender(),
            amount,
            msg.value
        );
    }

    function mintEarly(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable {
        require(
            block.timestamp >= earlyAccessStart,
            "window closed"
        );
        require(
            balanceOf(_msgSender()) + amount <= preSaleMaxMint,
            "wallet mint limit"
        );
        require(
            tx.origin == _msgSender(), 
            "contracts not allowed"
        );
        bytes32 node = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "invalid proof"
        );
        _mintPublic(
            _msgSender(),
            amount,
            msg.value
        );
    }
    
    function setPublicMax(
        uint256 _publicMax
    ) external onlyOwner {
        require(
            _publicMax <= collectionSize - teamMintMax, 
            "too high"
        );
        publicMax = _publicMax;
    }
    
    function setPricePerMint(
        uint256 _pricePerMint
    ) external onlyOwner {
        pricePerMint = _pricePerMint;
    }
    
    function setMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    function setEarlyAccessStart(
        uint256 _earlyAccessStart
    ) external onlyOwner {
        earlyAccessStart = _earlyAccessStart;
    }
    
    function setPurchaseStart(
        uint256 _purchaseStart
    ) external onlyOwner {
        purchaseStart = _purchaseStart;
    }

    function mintGrant(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(
            _addresses.length == _amounts.length,
            "length mismatch"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(
                teamMinted + _amounts[i] <= teamMintMax,
                "team limit reached"
            );
            for (uint256 j = 0; j < _amounts[i] / maxBatchSize; j++) {
                _safeMint(_addresses[i], maxBatchSize);
            }
            _safeMint(_addresses[i], _amounts[i] % maxBatchSize);
            teamMinted += _amounts[i];
        }
    }

    function setURI(
        string calldata _tokenBaseURI,
        string calldata _tokenBaseURIExt
    ) external onlyOwner {
        require(
            !frozen,
            "Contract is frozen"
        );
        tokenBaseURI = _tokenBaseURI;
        tokenBaseURIExt = _tokenBaseURIExt;
    }

    function freezeBaseURI(
    ) external onlyOwner {
        frozen = true;
    }
    
    function withdraw(
    ) external onlyOwner {
        payable(
            0x19aFb0C4f63983d619A3f983D065A68780734336
        ).transfer(
            address(this).balance
        );
    }

    function _mintPublic(
        address _address,
        uint256 amount,
        uint256 value
    ) internal {
        require(
            amount <= maxBatchSize,
            "max batch limit"
        );
        require(
            totalSupply() + amount <= collectionSize, 
            "reached max supply"
        );
        require(
            totalSupply() + amount <= publicMax + teamMinted, 
            "reached max public"
        );
        require(
            value >= pricePerMint * amount,
            "Not enough ETH sent"
        );
        _safeMint(_address, amount);
    }

}

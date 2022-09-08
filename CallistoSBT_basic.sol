// SPDX-License-Identifier: GPL

pragma solidity ^0.8.16;

interface ICallistoSBT {

    event NewBid       (uint256 indexed tokenID, uint256 indexed bidAmount, bytes bidData);
    event TokenTrade   (uint256 indexed tokenID, address indexed new_owner, address indexed previous_owner, uint256 priceInWEI);
    event Transfer     (address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferData (bytes data);
    
    struct Properties {
        
        // In this example properties of the given SBT are stored
        // in a dynamically sized array of strings
        // properties can be re-defined for any specific info
        // that a particular SBT is intended to store.
        
        /* Properties could look like this:
        bytes   property1;
        bytes   property2;
        address property3;
        */
        
        string[] properties;
    }
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function standard() external view returns (string memory);
    function balanceOf(address _who) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transfer(address _from, address _to, uint256 _tokenId, bytes memory _data, bool _invoke_callback) external returns (bool);
    
    function getTokenProperties(uint256 _tokenId) external view returns (Properties memory);
    function getTokenProperty(uint256 _tokenId, uint256 _propertyId) external view returns (string memory);

    function getUserContent(uint256 _tokenId) external view returns (string memory _content, bool _all);
    function setUserContent(uint256 _tokenId, string calldata _content) external returns (bool);
}

abstract contract TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external virtual returns(bytes4);
}

abstract contract CallistoSBT is ICallistoSBT {
    
    mapping (uint256 => Properties) internal _tokenProperties;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_, uint256 _defaultFee) {
        _name   = name_;
        _symbol = symbol_;
    }
    
    function standard() public pure override returns (string memory)
    {
        return "CallistoSBT";
    }
    
    function getTokenProperties(uint256 _tokenId) public view override returns (Properties memory)
    {
        return _tokenProperties[_tokenId];
    }
    
    function getTokenProperty(uint256 _tokenId, uint256 _propertyId) public view override returns (string memory)
    {
        return _tokenProperties[_tokenId].properties[_propertyId];
    }

    function getUserContent(uint256 _tokenId) public view override returns (string memory _content, bool _all)
    {
        return (_tokenProperties[_tokenId].properties[0], true);
    }

    function setUserContent(uint256 _tokenId, string calldata _content) public override returns (bool success)
    {
        require(msg.sender == ownerOf(_tokenId), "SBT: only owner can change SBT content");
        _tokenProperties[_tokenId].properties[0] = _content;
        return true;
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "SBT: balance query for the zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "SBT: owner query for nonexistent token");
        return owner;
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function configureSBT(uint256 tokenId) internal
    {
        if(_tokenProperties[tokenId].properties.length == 0)
        {
            _tokenProperties[tokenId].properties.push("");
        }
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "SBT: mint to the zero address");
        require(!_exists(tokenId), "SBT: token already minted");

        configureSBT(tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal {
        address owner = CallistoSBT.ownerOf(tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}

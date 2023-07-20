// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract PTAHDAO_lmrpartners is Ownable {

    uint256 private _id = 0;

    struct AssetPack {
        uint256     id;
        uint256     apid;
        uint256     userid;
        address     userAddress;
        string      orderNumber;
        uint256     orderCreatime;
        bool        orderIsValid;
    }

    mapping(address => bool) public memberShip;
    mapping(address=> uint256) public userMapping;
    mapping(uint256 => AssetPack) public assetPack;
    mapping(string => uint256) public orderList;
    mapping(uint256 => uint256) public blockMapping;

    mapping(address => uint256[]) public userAssetPack;
    mapping(uint256 => uint256) public assetPackHolding;

    function setMemberShip(address payable userAddress, bool valid) onlyOwner public payable {
        require(userAddress != address(0), "illegal address");
        memberShip[userAddress] = valid;

        if(msg.value > 0) 
            userAddress.transfer(msg.value);
    }

    function setUserMapping(address payable userAddress, uint256 userid) onlyOwner public payable {
        require(userAddress != address(0), "illegal address");
        userMapping[userAddress] = userid;

        if(msg.value > 0) 
            userAddress.transfer(msg.value);
    }

    function initMember(address payable userAddress, uint256 userid) onlyOwner public payable {
        require(userAddress != address(0), "illegal address");
        require(userid > 0, "membership number must be greater than zero");

        userMapping[userAddress] = userid;
        memberShip[userAddress] = true;

        if(msg.value > 0) 
            userAddress.transfer(msg.value);
    }

    function createAssetPack(uint256 ap_id, uint256 creatime, string memory order_number) external {
        require(memberShip[msg.sender], "only members can create asset-pack.");
        require(userMapping[msg.sender] > 0, "user has not existed");
        require(ap_id > 0, "asset-pack id must be greater than 0");
        require(creatime > 0, "create time must be greater than 0");
        require(orderList[order_number] <= 0, "order has exists");

        uint256 user_id = userMapping[msg.sender];
        uint256 id = generateId();

        assetPack[id] = AssetPack({
            id: id,
            apid:ap_id,
            userid:user_id,
            userAddress:msg.sender,
            orderNumber:order_number,
            orderCreatime:creatime,
            orderIsValid:true
        });
        orderList[order_number] = id;

        userAssetPack[msg.sender].push(id);
        assetPackHolding[ap_id]++;

        blockMapping[id] = block.number;
    }

    function updateAssetPackValid(uint256 id, bool is_valid) onlyOwner external {
        require(existsAssetPack(id),"asset-pack has not exists");
        AssetPack storage ap = assetPack[id];
        ap.orderIsValid = is_valid;
    }

    function existsAssetPack(uint256 id) public view returns (bool) {
        return assetPack[id].id != 0;
    }

    function getUserAssetPackCount(address userAddress) public view returns (uint) {
        return userAssetPack[userAddress].length;
    }

    function withdraw(uint256 amount) onlyOwner public {
        require(address(this).balance >= amount, "Only the contract owner can withdraw.");
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}

    function generateId() private returns (uint256) {
        _id++;
        return _id;
    }
}
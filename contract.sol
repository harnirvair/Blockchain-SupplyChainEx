pragma solidity ^0.6.0;

contract Ownable {
    address payable _owner;
    constructor() public{
        _owner = msg.sender;
    } 
    modifier onlyOwner(){
        require(isOwner(), "You are not the owner");
        _;

        
    }
    function isOwner() public view returns(bool){
        return(msg.sender==_owner);
    }
}

contract Item {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;
    
    ItemManager parentContract;
    
    constructor(ItemManager _parentContract, uint _priceInWei, uint _index) public{
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
    }
    receive() external payable {
        require(pricePaid == 0, "Item is paid already");
        require(priceInWei == msg.value, "Only full payments allowed");
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call.value(msg.value)(abi.encodeWithSignature("triggerPayment(uint256)",index));
        require(success, "The transaction wasn't successful, canceling");
    }
    fallback() external {}
}
contract ItemManager is Ownable{
 enum SupplyChainSteps{Created, Paid, Delivered}

 struct S_Item {
 Item _item;
 ItemManager.SupplyChainSteps _step;
 string _identifier;
 uint _priceInWei;
 }
 mapping(uint => S_Item) public items;
 uint index;

 event SupplyChainStep(uint _itemIndex, uint _step, address _itemAddress);

 function createItem(string memory _identifier, uint _priceInWei) public onlyOwner{
 Item item = new Item(this, _priceInWei, index);
 items[index]._item = item;
 items[index]._priceInWei = _priceInWei;
 items[index]._step = SupplyChainSteps.Created;
 items[index]._identifier = _identifier;
 emit SupplyChainStep(index, uint(items[index]._step), address(item));
 index++;
 }

 function triggerPayment(uint _index) public payable {
 require(items[index]._priceInWei <= msg.value, "Not fully paid");
 require(items[index]._step == SupplyChainSteps.Created, "Item is further in the supply chain");
 items[_index]._step = SupplyChainSteps.Paid;
 emit SupplyChainStep(_index, uint(items[_index]._step), address(items[index]._item));
 }

 function triggerDelivery(uint _index) public onlyOwner {
 require(items[_index]._step == SupplyChainSteps.Paid, "Item is further in the supply chain");
 items[_index]._step = SupplyChainSteps.Delivered;
 emit SupplyChainStep(_index, uint(items[_index]._step), address(items[index]._item));
 }
}

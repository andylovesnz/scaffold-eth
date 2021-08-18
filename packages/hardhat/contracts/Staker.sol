pragma solidity >=0.6.0 <0.7.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

// rinkeby deployed address: https://rinkeby.etherscan.io/tx/0x639fbc45d45051056021ae5b3b6fe8c577da9eac6f5c79d363ee4d6d51c57fbc

// contract Staker is Ownable {
contract Staker {
    event Stake(
        address addr,
        uint256 amount
    );

    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = now + 30 seconds;
    bool private openForWithdraw = false;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // function enableOpenForWithdraw() external onlyOwner
    // remove `onlyOwner`, easier to test
    function enableOpenForWithdraw() external
    {
        openForWithdraw = true;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() external payable
    {
        require(!exampleExternalContract.completed(), "completed");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    modifier deadlinePassed() {
        require(now >= deadline, "not ready");
        _;
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() external deadlinePassed
    {
        require(!exampleExternalContract.completed(), "completed");
        if (address(this).balance > threshold)
        {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw(address payable addr) external
    {
        require(address(this).balance <= threshold, "not available");
        require(openForWithdraw, "not open");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        addr.transfer(balance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() external view returns(uint256)
    {
        if (now >= deadline) {
            return 0;
        }
        // console.log("%s %s ", deadline, now);
        return (deadline - now);
    }
}

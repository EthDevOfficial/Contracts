pragma solidity >=0.6.0;

contract NodeEmitter {
    event NodeTest(string txHash, string nodeId);

    function nodeEmit(string memory txHash, string memory nodeId) external {
        emit NodeTest(txHash, nodeId);
    }
}
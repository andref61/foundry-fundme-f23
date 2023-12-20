// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();


/**
 * @author  Andre Ferrara
 * @title   Educational FundMe contract
 * @dev     There is a minimum deposit of 5 USD
 * @notice  Allow users to deposit and withdraw funds.
 */
contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    // state variables
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface public s_priceFeed;
    
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
         s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
    
    
    /**
     * @notice  Returns the version of the price feed aggregator.
     * @dev     .
     * @return  uint256  .
     */
    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }
    
    /**
     * @notice  .
     * @dev     .
     */
    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; // read from storage once to get the length of the array
        for (uint256 funderIndex=0; funderIndex < fundersLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // transfer - reverts on error
        // payable(msg.sender).transfer(address(this).balance);
        
        // send - must check bool return for success/fail
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call - prefered method to send ETH
        (bool callSuccess, /* bytes dataReturned - not used */ ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

        
    /**
     * @notice  Gets the funded amount for a given address
     * @dev     .
     * @param   fundingAddress  funded address
     * @return  uint256  .
     */
    function getAddressToAmountFunded( address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    /**
     * @notice  Gets address of funder
     * @dev     .
     * @param   index  .
     * @return  address  .
     */
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    /**
     * @notice  .
     * @dev     .
     * @return  address  .
     */
    function getOwner() external view returns (address) {
        return i_owner;
    }
 }

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
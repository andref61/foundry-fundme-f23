// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks
    // otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMAL = 8;
    int public constant INITIAL_PRICE = 2000e8;
 // Chainlink price feed ETH/USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
    address public constant PRICE_FEED_ADDRESS = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) { // current chain Id Sepolia testnet == 11155111
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else {
            {
                activeNetworkConfig = getAnvilConfig();
            }
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: PRICE_FEED_ADDRESS
        });

        return ethConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {

        if (activeNetworkConfig.priceFeed != address(0)) {return activeNetworkConfig;}

        // deploy mock Aggregator contract
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMAL, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
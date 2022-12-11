// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MintableERC20BLWithDecimals} from "mgv_test/lib/tokens/MintableERC20BLWithDecimals.sol";

contract PixieMATIC is MintableERC20BLWithDecimals {
  constructor(address admin) MintableERC20BLWithDecimals(admin, "Pixie MATIC", "PxMATIC", 18) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {MgvLib} from "./MgvLib.sol";

import {MgvOfferMaking} from "./MgvOfferMaking.sol";
import {MgvOfferTakingWithPermit} from "./MgvOfferTakingWithPermit.sol";
import {MgvHasAppendix} from "./MgvHasAppendix.sol";

/* `AbstractMangrove` inherits the three contracts that implement generic Mangrove functionality (`MgvGovernable`,`MgvOfferTakingWithPermit` and `MgvOfferMaking`) but does not implement the abstract functions. */
abstract contract AbstractMangrove is MgvHasAppendix, MgvOfferTakingWithPermit, MgvOfferMaking {
  constructor(address governance, uint gasprice, uint gasmax, string memory contractName)
    MgvOfferTakingWithPermit(contractName)
    MgvHasAppendix(governance, gasprice, gasmax)
  {}
}

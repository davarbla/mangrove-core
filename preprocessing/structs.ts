/* # Mangrove Summary
   * The Mangrove holds order books for `outbound_tkn`,`inbound_tkn` pairs.
   * Offers are sorted in a doubly linked list.
   * Each offer promises `outbound_tkn` and requests `inbound_tkn`.
   * Each offer has an attached `maker` address.
   * In the normal operation mode (called Mangrove for Maker Mangrove), when an offer is executed, we:
     1. Flashloan some `inbound_tkn` to the offer's `maker`.
     2. Call an arbitrary `execute` function on that address.
     3. Transfer back some `outbound_tkn`.
     4. Call back the `maker` so they can update their offers.
    
   **Let the devs know about any error, typo etc, by contacting 	devs@mangrove.exchange**
 */
//+clear+

/* # Preprocessing

The current file (`structs.js`) is used in `MgvStructs.pre.sol` (not shown here) to generate the libraries in `MgvType.pre.sol`. Here is an example of js struct specification and of a generated library:
```
struct_defs = {
  universe: [
    {name: "serialnumber", bits: 16, type: "uint"},
    {name: "hospitable",bits: 8, type:"bool"}
  ]
}
```

The generated file will store all data in a single EVM stack slot (seen as an abstract type `<TypeName>` by Solidity); here is a simplified version:

```
struct UniverseUnpacked {
  uint serialnumber;
  bool hospitable;
}

library Library {
  // use Solidity 0.8* custom types
  type Universe is uint;

  // test word equality
  function eq(Universe ,Universe) returns (bool);

  // word <-> struct conversion
  function to_struct(Universe) returns (UniverseUnpacked memory);
  function t_of_struct(UniverseUnpacked memory) returns (Universe);

  // arguments <-> word conversion
  function unpack(Universe) returns (uint serialnumber, bool hospitable);
  function pack(uint serialnumber, bool hospitable) returns(Universe);

  // read and write first property
  function serialnumber(Universe) returns (uint);
  function serialnumber(Universe,uint) returns (Universe);

  // read and write second property
  function hospitable(Universe) returns (bool);
  function hospitable(Universe,bool) returns (Universe);
}
```
Then, in Solidity code, one can write:
```
Universe uni = UniverseLib.pack(32,false);
uint num = uni.serialnumber();
uni.hospitable(true);
```
*/

/* # Data stuctures */

/* Struct-like data structures are stored in storage and memory as 256 bits words. We avoid using structs due to significant gas savings gained by extracting data from words only when needed. The generation is defined in `lib/preproc.js`. */

/* Struct fields that are common to multiple structs are factored here. Multiple field names refer to offer identifiers, so the `id` field is a function that takes a name as argument. */

const fields = {
  gives: { name: "gives", bits: 96, type: "uint" },
  gasprice: { name: "gasprice", bits: 26, type: "uint" },
  gasreq: { name: "gasreq", bits: 24, type: "uint" },
  kilo_offer_gasbase: { name: "kilo_offer_gasbase", bits: 9, type: "uint" },
};

const id_field = (name: string) => {
  return { name, bits: 32, type: "uint" };
};

/* # Structs */

/* ## `Offer` */
//+clear+
/* `Offer`s hold the doubly-linked list pointers as well as ratio and volume information. 256 bits wide, so one storage read is enough. They have the following fields: */
//+clear+
const struct_defs = {
  offer: {
    fields: [
      /* * `prev` points to immediately better offer. The best offer's `prev` is 0. _32 bits wide_. */

      id_field("prev"),
      /* * `next` points to the immediately worse offer. The worst offer's `next` is 0. _32 bits wide_. */
      id_field("next"),
      {name:"tick",bits:21,type:"Tick",underlyingType: "int"},
      /* * `gives` is the amount of `outbound_tkn` the offer will give if successfully executed.
      _96 bits wide_, so assuming the usual 18 decimals, amounts can only go up to
      10 billions. */
      fields.gives,
    ],
    additionalDefinitions: `import "mgv_lib/BinLib.sol";
import "mgv_lib/TickLib.sol";

using OfferExtra for Offer global;
using OfferUnpackedExtra for OfferUnpacked global;

// cleanup-mask: 0s at location of fields to hide from maker, 1s elsewhere
uint constant HIDE_FIELDS_FROM_MAKER_MASK = ~(OfferLib.prev_mask_inv | OfferLib.next_mask_inv);

library OfferExtra {
  // Compute wants from tick and gives
  function wants(Offer offer) internal pure returns (uint) {
    return offer.tick().inboundFromOutbound(offer.gives());
  }
  // Sugar to test offer liveness
  function isLive(Offer offer) internal pure returns (bool resp) {
    uint gives = offer.gives();
    assembly ("memory-safe") {
      resp := iszero(iszero(gives))
    }
  }
  function bin(Offer offer, uint tickSpacing) internal pure returns (Bin) {
    // Offers are always stored with a tick that corresponds exactly to a tick
    return offer.tick().nearestBin(tickSpacing);
  }
  function clearFieldsForMaker(Offer offer) internal pure returns (Offer) {
    unchecked {
      return Offer.wrap(
        Offer.unwrap(offer)
        & HIDE_FIELDS_FROM_MAKER_MASK);
    }
  }
}

library OfferUnpackedExtra {
  // Compute wants from tick and gives
  function wants(OfferUnpacked memory offer) internal pure returns (uint) {
    return offer.tick.inboundFromOutbound(offer.gives);
  }
  // Sugar to test offer liveness
  function isLive(OfferUnpacked memory offer) internal pure returns (bool resp) {
    uint gives = offer.gives;
    assembly ("memory-safe") {
      resp := iszero(iszero(gives))
    }
  }
  function bin(OfferUnpacked memory offer, uint tickSpacing) internal pure returns (Bin) {
    // Offers are always stored with a tick that corresponds exactly to a tick
    return offer.tick.nearestBin(tickSpacing);
  }

}
`
  },

  /* ## `OfferDetail` */
  //+clear+
  /* `OfferDetail`s hold the maker's address and provision/penalty-related information.
They have the following fields: */
  offerDetail: {
    fields: [
      /* * `maker` is the address that created the offer. It will be called when the offer is executed, and later during the posthook phase. */
      { name: "maker", bits: 160, type: "address" },
      /* * <a id="structs.js/gasreq"></a>`gasreq` gas will be provided to `execute`. _24 bits wide_, i.e. around 16M gas. Note that if more room was needed, we could bring it down to 16 bits and have it represent 1k gas increments.

    */
      fields.gasreq,
      /*
        * <a id="structs.js/gasbase"></a>  `offer_gasbase` represents the gas overhead used by processing the offer inside Mangrove + the overhead of initiating an entire order, in 1k gas increments.

      The gas considered 'used' by an offer is the sum of
      * gas consumed during the call to the offer
      * `offer_gasbase`
      
    (There is an inefficiency here. The overhead could be split into an "offer-local overhead" and a "general overhead". That general overhead gas penalty could be spread between all offers executed during an order, or all failing offers. It would still be possible for a cleaner to execute a failing offer alone and make them pay the entire general gas overhead. For the sake of simplicity we keep only one "offer overhead" value.)

    If an offer fails, `gasprice` mwei is taken from the
    provision per unit of gas used. `gasprice` should approximate the average gas
    ratio at offer creation time.

    `kilo_offer_gasbase` is the actual field name, and is _9 bits wide_ and represents 1k gas increments. The accessor `offer_gasbase` returns `kilo_offer_gasbase * 1e3`.

    `kilo_offer_gasbase` is also the name of a local Mangrove
    parameters. When an offer is created, their current value is copied from Mangrove local configuration. The maker does not choose it.

    So, when an offer is created, the maker is asked to provision the
    following amount of wei:
    ```
    (gasreq + offer_gasbase) * gasprice * 1e6
    ```

      where `offer_gasbase` and `gasprice` are Mangrove's current configuration values (or a higher value for `gasprice` if specified by the maker).


      When an offer fails, the following amount is given to the taker as compensation:
    ```
    (gasused + offer_gasbase) * gasprice * 1e6
    ```

    where `offer_gasbase` and `gasprice` are Mangrove's current configuration values.  The rest is given back to the maker.

      */
      fields.kilo_offer_gasbase,
      /* * `gasprice` is in mwei/gas and _26 bits wide_, which accomodates 0.001 to ~67k gwei / gas.  `gasprice` is also the name of a global Mangrove parameter. When an offer is created, the offer's `gasprice` is set to the max of the user-specified `gasprice` and Mangrove's global `gasprice`. */
      fields.gasprice,
    ],
    additionalDefinitions: (struct) => `
using OfferDetailExtra for OfferDetail global;
using OfferDetailUnpackedExtra for OfferDetailUnpacked global;

library OfferDetailExtra {
  function offer_gasbase(OfferDetail offerDetail) internal pure returns (uint) { unchecked {
    return offerDetail.kilo_offer_gasbase() * 1e3;
  }}
  function offer_gasbase(OfferDetail offerDetail,uint val) internal pure returns (OfferDetail) { unchecked {
    return offerDetail.kilo_offer_gasbase(val/1e3);
  }}
}

library OfferDetailUnpackedExtra {
  function offer_gasbase(OfferDetailUnpacked memory offerDetail) internal pure returns (uint) { unchecked {
    return offerDetail.kilo_offer_gasbase * 1e3;
  }}
  function offer_gasbase(OfferDetailUnpacked memory offerDetail,uint val) internal pure { unchecked {
    offerDetail.kilo_offer_gasbase = val/1e3;
  }}
}
`,
  },

  /* ## Configuration and state
   Configuration information for a `outbound_tkn`,`inbound_tkn` pair is split between a `global` struct (common to all pairs) and a `local` struct specific to each pair. Configuration fields are:
*/
  /* ### Global Configuration */
  global: {
    fields: [
      /* * The `monitor` can provide realtime values for `gasprice` and `density` to the dex, and receive liquidity events notifications. */
      { name: "monitor", bits: 160, type: "address" },
      /* * If `useOracle` is true, the dex will use the monitor address as an oracle for `gasprice` and `density`, for every outbound_tkn/inbound_tkn pair, except if the oracle-provided values do not pass a check performed by Mangrove. In that case the oracle values are ignored. */
      { name: "useOracle", bits: 1, type: "bool" },
      /* * If `notify` is true, the dex will notify the monitor address after every offer execution. */
      { name: "notify", bits: 1, type: "bool" },
      /* * The `gasprice` is the amount of penalty paid by failed offers, in mwei per gas used. `gasprice` should approximate the average gas price and will be subject to regular updates. */
      fields.gasprice,
      /* * `gasmax` specifies how much gas an offer may ask for at execution time. An offer which asks for more gas than the block limit would live forever on the book. Nobody could take it or remove it, except its creator (who could cancel it). In practice, we will set this parameter to a reasonable limit taking into account both practical transaction sizes and the complexity of maker contracts.
      */
      { name: "gasmax", bits: 24, type: "uint" },
      /* * `dead` dexes cannot be resurrected. */
      { name: "dead", bits: 1, type: "bool" },
      /* * `maxRecursionDepth` is the maximum number of times a market order can recursively execute offers. This is a protection against stack overflows. */
      { name: "maxRecursionDepth", bits: 8, type: "uint" },      
      /* * `maxGasreqForFailingOffers` is the maximum gasreq failing offers can consume in total. This is used in a protection against failing offers consuming gaslimit for transaction. Setting it too high would make it possible for successive failing offers to consume gaslimit, setting it too low will make a non-healthy book not execute enough offers. `gasmax` and `maxRecursionDepth` bit sizes constrain this.  */
      { name: "maxGasreqForFailingOffers", bits: 32, type: "uint" },      
    ],
  },

  /* ### Local configuration */
  local: {
    fields: [
      /* * A `outbound_tkn`,`inbound_tkn` pair is in`active` by default, but may be activated/deactivated by governance. */
      { name: "active", bits: 1, type: "bool" },
      /* * `fee`, in basis points, of `outbound_tkn` given to the taker. This fee is sent to Mangrove. Fee is capped to ~2.5%. */
      { name: "fee", bits: 8, type: "uint" },
      /* * `density` is similar to a 'dust' parameter. We prevent spamming of low-volume offers by asking for a minimum 'density' in `outbound_tkn` per gas requested. For instance, if `density` is worth 10,, `offer_gasbase == 5000`, an offer with `gasreq == 30000` must promise at least _10 × (30000 + 5000) = 350000_ `outbound_tkn`. _9 bits wide_.

      We store the density as a float with 2 bits for the mantissa, 7 for the exponent, and an exponent bias of 32, so density ranges from $2^{-32}$ to $1.75 \times 2^{95}$. For more information, see `DensityLib`.
      
      */
      { name: "density", bits: 9, type: "Density", underlyingType: "uint"},
      { name: "binPosInLeaf", bits: 2, type: "uint" },
      { name: "level3", bits: 64, type: "Field", underlyingType: "uint" },
      { name: "level2", bits: 64, type: "Field", underlyingType: "uint" },
      { name: "level1", bits: 64, type: "Field", underlyingType: "uint" },
      { name: "root", bits: 2, type: "Field", underlyingType: "uint" },
      /* * `offer_gasbase` is an overapproximation of the gas overhead associated with processing one offer. The Mangrove considers that a failed offer has used at least `offer_gasbase` gas. The actual field name is `kilo_offer_gasbase` and the accessor `offer_gasbase` returns `kilo_offer_gasbase*1e3`. Local to a pair, because the costs of calling `outbound_tkn` and `inbound_tkn`'s `transferFrom` are part of `offer_gasbase`. Should only be updated when ERC20 contracts change or when opcode prices change. */
      fields.kilo_offer_gasbase,
      /* * If `lock` is true, orders may not be added nor executed.

        Reentrancy during offer execution is not considered safe:
      * during execution, an offer could consume other offers further up in the book, effectively frontrunning the taker currently executing the offer.
      * it could also cancel other offers, creating a discrepancy between the advertised and actual market price at no cost to the maker.
      * an offer insertion consumes an unbounded amount of gas (because it has to be correctly placed in the book).

  Note: An optimization in the `marketOrder` function relies on reentrancy being forbidden.
      */
      { name: "lock", bits: 1, type: "bool" },
      /* * `best` holds the current best offer id. Has size of an id field. *Danger*: reading best inside a lock may give you a stale value. */
      // id_field("best"),
      /* * `last` is a counter for offer ids, incremented every time a new offer is created. It can't go above $2^{32}-1$. */
      id_field("last"),
    ],
    additionalDefinitions: (struct) => `
import {Bin,BinLib,Field} from "mgv_lib/BinLib.sol";
import {Density, DensityLib} from "mgv_lib/DensityLib.sol";

using LocalExtra for Local global;
using LocalUnpackedExtra for LocalUnpacked global;

// cleanup-mask: 0s at location of fields to hide from maker, 1s elsewhere
uint constant HIDE_FIELDS_FROM_MAKER_MASK = ~(LocalLib.binPosInLeaf_mask_inv | LocalLib.level3_mask_inv | LocalLib.level2_mask_inv | LocalLib.level1_mask_inv | LocalLib.root_mask_inv | LocalLib.last_mask_inv);

library LocalExtra {

  function densityFrom96X32(Local local, uint density96X32) internal pure returns (Local) { unchecked {
    return local.density(DensityLib.from96X32(density96X32));
  }}
  function offer_gasbase(Local local) internal pure returns (uint) { unchecked {
    return local.kilo_offer_gasbase() * 1e3;
  }}
  function offer_gasbase(Local local,uint val) internal pure returns (Local) { unchecked {
    return local.kilo_offer_gasbase(val/1e3);
  }}
  function bestBin(Local local) internal pure returns (Bin) {
    return BinLib.bestBinFromLocal(local);
  }
  function clearFieldsForMaker(Local local) internal pure returns (Local) {
    unchecked {
      return Local.wrap(
        Local.unwrap(local)
        & HIDE_FIELDS_FROM_MAKER_MASK);
    }
  }
}

library LocalUnpackedExtra {
  function densityFrom96X32(LocalUnpacked memory local, uint density96X32) internal pure { unchecked {
    local.density = DensityLib.from96X32(density96X32);
  }}
  function offer_gasbase(LocalUnpacked memory local) internal pure returns (uint) { unchecked {
    return local.kilo_offer_gasbase * 1e3;
  }}
  function offer_gasbase(LocalUnpacked memory local,uint val) internal pure { unchecked {
    local.kilo_offer_gasbase = val/1e3;
  }}
  function bestBin(LocalUnpacked memory local) internal pure returns (Bin) {
    return BinLib.bestBinFromBranch(local.binPosInLeaf,local.level3,local.level2,local.level1,local.root);
  }
}
`,
  }
};

export default struct_defs;

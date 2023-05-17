// MgvOfferDetail.post.sol

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

pragma solidity ^0.8.13;

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

uint constant ONES = type(uint).max;

struct OfferDetailUnpacked {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}

//some type safety for each struct
type OfferDetailPacked is uint;
using Library for OfferDetailPacked global;

// number of bits in each field
uint constant maker_bits         = 160;
uint constant gasreq_bits        = 24;
uint constant offer_gasbase_bits = 24;
uint constant gasprice_bits      = 16;

// number of bits before each field
uint constant maker_before         = 0                    + 0;
uint constant gasreq_before        = maker_before         + maker_bits;
uint constant offer_gasbase_before = gasreq_before        + gasreq_bits;
uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

// cleanup-mask: 0s at field location, 1s elsewhere
uint constant maker_mask         = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant gasreq_mask        = 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
uint constant gasprice_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

library Library {
  function to_struct(OfferDetailPacked __packed) internal pure returns (OfferDetailUnpacked memory __s) { unchecked {
    __s.maker         = address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256 - maker_bits)));
    __s.gasreq        = (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256 - gasreq_bits);
    __s.offer_gasbase = (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256 - offer_gasbase_bits);
    __s.gasprice      = (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256 - gasprice_bits);
  }}

  function eq(OfferDetailPacked __packed1, OfferDetailPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferDetailPacked.unwrap(__packed1) == OfferDetailPacked.unwrap(__packed2);
  }}

  function unpack(OfferDetailPacked __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker         = address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256 - maker_bits)));
    __gasreq        = (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256 - gasreq_bits);
    __offer_gasbase = (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256 - offer_gasbase_bits);
    __gasprice      = (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256 - gasprice_bits);
  }}

  function maker(OfferDetailPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256 - maker_bits)));
  }}

  function maker(OfferDetailPacked __packed,address val) internal pure returns(OfferDetailPacked) { unchecked {
    uint __clean_struct = OfferDetailPacked.unwrap(__packed) & maker_mask;
    uint __clean_field  = (uint(uint160(val)) << (256 - maker_bits)) >> maker_before;
    return OfferDetailPacked.wrap(__clean_struct | __clean_field);
  }}
  
  function gasreq(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256 - gasreq_bits);
  }}

  function gasreq(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    uint __clean_struct = OfferDetailPacked.unwrap(__packed) & gasreq_mask;
    uint __clean_field  = (val << (256 - gasreq_bits)) >> gasreq_before;
    return OfferDetailPacked.wrap(__clean_struct | __clean_field);
  }}
  
  function offer_gasbase(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256 - offer_gasbase_bits);
  }}

  function offer_gasbase(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    uint __clean_struct = OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask;
    uint __clean_field  = (val << (256 - offer_gasbase_bits)) >> offer_gasbase_before;
    return OfferDetailPacked.wrap(__clean_struct | __clean_field);
  }}
  
  function gasprice(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256 - gasprice_bits);
  }}

  function gasprice(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    uint __clean_struct = OfferDetailPacked.unwrap(__packed) & gasprice_mask;
    uint __clean_field  = (val << (256 - gasprice_bits)) >> gasprice_before;
    return OfferDetailPacked.wrap(__clean_struct | __clean_field);
  }}
  
}

function t_of_struct(OfferDetailUnpacked memory __s) pure returns (OfferDetailPacked) { unchecked {
  return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
}}

function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) pure returns (OfferDetailPacked) { unchecked {
  uint __packed = 0;
  __packed |= (uint(uint160(__maker)) << (256 - maker_bits)) >> maker_before;
  __packed |= (__gasreq << (256 - gasreq_bits)) >> gasreq_before;
  __packed |= (__offer_gasbase << (256 - offer_gasbase_bits)) >> offer_gasbase_before;
  __packed |= (__gasprice << (256 - gasprice_bits)) >> gasprice_before;
  return OfferDetailPacked.wrap(__packed);
}}

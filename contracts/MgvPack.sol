// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

pragma solidity ^0.8.10;

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]
// $for ns in struct_defs
// $def sname ns[0]
// $def struct_def ns[1]

library $$(capitalize(sname)) {
  //some type safety for each struct
  type t is bytes32;

  struct s {
    $$(solidity_struct_of(struct_def))
  }

  function eq(t a, t b) internal pure returns (bool) {
    return t.unwrap(a) == t.unwrap(b);
  }

/* $def arguments
  join(map(struct_def,(field) => `$${f_type(field)} $${f_name(field)}`),', ')
*/

/* $def params
    map(struct_def, (field) => [f_name(field),`__$${f_name(field)}`])
*/

  function pack($$(arguments)) internal pure returns (t) {
    return t.wrap($$(make(
      struct_def,
      map(struct_def, (field) =>
    [f_name(field),`$${f_name(field)}`]))));
  }

  function unpack(t __packed) internal pure returns ($$(arguments)) {
    // $for field in struct_def
    $$(f_name(field)) = $$(get('t.unwrap(__packed)',struct_def,f_name(field)));
    // $done
  }

  // $for field in struct_def
  function $$(f_name(field))(t __packed) internal pure returns($$(f_type(field))) {
    return $$(get('t.unwrap(__packed)',struct_def,f_name(field)));
  }
  function $$(f_name(field))(t __packed,$$(f_type(field)) val) internal pure returns(t) {
    return t.wrap($$(set1('t.unwrap(__packed)',struct_def,f_name(field),'val')));
    // return $$(get('t.unwrap(__packed)',struct_def,f_name(field)));
  }
  // $done
}

//$done

 
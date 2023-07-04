// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.13;

import "mgv_lib/Test2.sol";
import "mgv_src/MgvLib.sol";

// Warning: fuzzer will run tests with malformed packed arguments, e.g. bool fields that are > 1.

contract MgvLocalTest is Test2 {

  // cleanup arguments with variable number of bits since `pack` also does a cleanup
  function cast(uint u, uint8 to) internal pure returns (uint) {
    return u & (type(uint).max >> (256-to));
  }

  function cast(int u, uint8 to) internal pure returns (int) {
    return u << (256-to) >> (256-to);
  }

  function test_pack(bool active, uint fee, Density density, Tick tick, uint offer_gasbase, bool lock, uint best, uint last) public {
    MgvStructs.LocalPacked packed = MgvStructs.Local.pack(active, fee, density, tick, offer_gasbase, lock, best, last);
    assertEq(packed.active(),active,"bad active");
    assertEq(packed.fee(),cast(fee,8),"bad fee");
    assertEq(Density.unwrap(packed.density()),cast(Density.unwrap(density),9),"bad density");
    assertEq(Tick.unwrap(packed.tick()),cast(Tick.unwrap(tick),24),"bad tick");
    assertEq(packed.offer_gasbase(),cast(offer_gasbase,24),"bad offer_gasbase");
    assertEq(packed.lock(),lock,"bad lock");
    assertEq(packed.best(),cast(best,32),"bad best");
    assertEq(packed.last(),cast(last,32),"bad last");
  }

  /* test_set_x tests:
     - setting works
     - get(set(get(x))) = get(x)
     - dirty bit cleaning 
     - no additional bits being dirtied
  */
  function test_set_active(MgvStructs.LocalPacked packed,bool active) public {
      MgvStructs.LocalPacked original = packed.active(packed.active());
      assertEq(original.active(),packed.active(), "original: bad active");

      MgvStructs.LocalPacked modified = packed.active(active);

      assertEq(modified.active(),active,"modified: bad active");

      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.best(),packed.best(),"modified: bad best");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_fee(MgvStructs.LocalPacked packed,uint fee) public {
      MgvStructs.LocalPacked original = packed.fee(packed.fee());
      assertEq(original.fee(),packed.fee(), "original: bad fee");

      MgvStructs.LocalPacked modified = packed.fee(fee);

      assertEq(modified.fee(),cast(fee,8),"modified: bad fee");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.best(),packed.best(),"modified: bad best");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_density(MgvStructs.LocalPacked packed,Density density) public {
      MgvStructs.LocalPacked original = packed.density(packed.density());
      assertEq(Density.unwrap(original.density()),Density.unwrap(packed.density()), "original: bad density");

      MgvStructs.LocalPacked modified = packed.density(density);

      assertEq(Density.unwrap(modified.density()),cast(Density.unwrap(density),9),"modified: bad density");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.best(),packed.best(),"modified: bad best");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_tick(MgvStructs.LocalPacked packed,Tick tick) public {
      MgvStructs.LocalPacked original = packed.tick(packed.tick());
      assertEq(Tick.unwrap(original.tick()),Tick.unwrap(packed.tick()), "original: bad tick");

      MgvStructs.LocalPacked modified = packed.tick(tick);

      assertEq(Tick.unwrap(modified.tick()),cast(Tick.unwrap(tick),24),"modified: bad tick");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.best(),packed.best(),"modified: bad best");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_offer_gasbase(MgvStructs.LocalPacked packed,uint offer_gasbase) public {
      MgvStructs.LocalPacked original = packed.offer_gasbase(packed.offer_gasbase());
      assertEq(original.offer_gasbase(),packed.offer_gasbase(), "original: bad offer_gasbase");

      MgvStructs.LocalPacked modified = packed.offer_gasbase(offer_gasbase);

      assertEq(modified.offer_gasbase(),cast(offer_gasbase,24),"modified: bad offer_gasbase");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.best(),packed.best(),"modified: bad best");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_lock(MgvStructs.LocalPacked packed,bool lock) public {
      MgvStructs.LocalPacked original = packed.lock(packed.lock());
      assertEq(original.lock(),packed.lock(), "original: bad lock");

      MgvStructs.LocalPacked modified = packed.lock(lock);

      assertEq(modified.lock(),lock,"modified: bad lock");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.best(),packed.best(),"modified: bad best");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_best(MgvStructs.LocalPacked packed,uint best) public {
      MgvStructs.LocalPacked original = packed.best(packed.best());
      assertEq(original.best(),packed.best(), "original: bad best");

      MgvStructs.LocalPacked modified = packed.best(best);

      assertEq(modified.best(),cast(best,32),"modified: bad best");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.last(),packed.last(),"modified: bad last");
    }
  function test_set_last(MgvStructs.LocalPacked packed,uint last) public {
      MgvStructs.LocalPacked original = packed.last(packed.last());
      assertEq(original.last(),packed.last(), "original: bad last");

      MgvStructs.LocalPacked modified = packed.last(last);

      assertEq(modified.last(),cast(last,32),"modified: bad last");

      assertEq(modified.active(),packed.active(),"modified: bad active");
      assertEq(modified.fee(),packed.fee(),"modified: bad fee");
      assertEq(Density.unwrap(modified.density()),Density.unwrap(packed.density()),"modified: bad density");
      assertEq(Tick.unwrap(modified.tick()),Tick.unwrap(packed.tick()),"modified: bad tick");
      assertEq(modified.offer_gasbase(),packed.offer_gasbase(),"modified: bad offer_gasbase");
      assertEq(modified.lock(),packed.lock(),"modified: bad lock");
      assertEq(modified.best(),packed.best(),"modified: bad best");
    }

  function test_unpack(MgvStructs.LocalPacked packed) public {
    (bool active, uint fee, Density density, Tick tick, uint offer_gasbase, bool lock, uint best, uint last) = packed.unpack();

    assertEq(packed.active(),active,"bad active");
    assertEq(packed.fee(),fee,"bad fee");
    assertEq(Density.unwrap(packed.density()),Density.unwrap(density),"bad density");
    assertEq(Tick.unwrap(packed.tick()),Tick.unwrap(tick),"bad tick");
    assertEq(packed.offer_gasbase(),offer_gasbase,"bad offer_gasbase");
    assertEq(packed.lock(),lock,"bad lock");
    assertEq(packed.best(),best,"bad best");
    assertEq(packed.last(),last,"bad last");
  }

  /* neither of_struct nor to_struct are injective. 
    - of_struct cuts of the high-order bits
    - to_struct removes the information in booleans
    So they're not inverses of each other.
    Instead we test field by field. The getters could be the constant function but no: they are tested in test_pack.
  */

  function test_inverse_1(MgvStructs.LocalPacked packed) public {
    MgvStructs.LocalUnpacked memory unpacked = packed.to_struct();
    assertEq(unpacked.active,packed.active(),"bad active");
    assertEq(unpacked.fee,packed.fee(),"bad fee");
    assertEq(Density.unwrap(unpacked.density),Density.unwrap(packed.density()),"bad density");
    assertEq(Tick.unwrap(unpacked.tick),Tick.unwrap(packed.tick()),"bad tick");
    assertEq(unpacked.offer_gasbase,packed.offer_gasbase(),"bad offer_gasbase");
    assertEq(unpacked.lock,packed.lock(),"bad lock");
    assertEq(unpacked.best,packed.best(),"bad best");
    assertEq(unpacked.last,packed.last(),"bad last");
  }

  function test_inverse_2(MgvStructs.LocalUnpacked memory unpacked) public {
    MgvStructs.LocalPacked packed = MgvStructs.Local.t_of_struct(unpacked);
    MgvStructs.LocalPacked packed2;
    packed2 = packed2.active(unpacked.active);
    packed2 = packed2.fee(unpacked.fee);
    packed2 = packed2.density(unpacked.density);
    packed2 = packed2.tick(unpacked.tick);
    packed2 = packed2.offer_gasbase(unpacked.offer_gasbase);
    packed2 = packed2.lock(unpacked.lock);
    packed2 = packed2.best(unpacked.best);
    packed2 = packed2.last(unpacked.last);
    assertEq(packed.active(),packed2.active(),"bad active");
    assertEq(packed.fee(),packed2.fee(),"bad fee");
    assertEq(Density.unwrap(packed.density()),Density.unwrap(packed2.density()),"bad density");
    assertEq(Tick.unwrap(packed.tick()),Tick.unwrap(packed2.tick()),"bad tick");
    assertEq(packed.offer_gasbase(),packed2.offer_gasbase(),"bad offer_gasbase");
    assertEq(packed.lock(),packed2.lock(),"bad lock");
    assertEq(packed.best(),packed2.best(),"bad best");
    assertEq(packed.last(),packed2.last(),"bad last");
  }
}

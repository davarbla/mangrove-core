// SPDX-License-Identifier:	BSD-2-Clause

// AaveTrader.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./AaveLender.sol";

abstract contract MultiUserAaveTrader is MultiUser, AaveModule {
  uint public immutable interestRateMode;

  constructor(uint _interestRateMode) {
    interestRateMode = _interestRateMode;
  }

  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    // 1. Computing total borrow and redeem capacities of underlying asset
    (uint redeemable, uint liquidity_after_redeem) = maxGettableUnderlying(
      order.outbound_tkn,
      true,
      owner
    );
    // Fail early to prevent AAVE manipulation by flashloans
    if (redeemable + liquidity_after_redeem < amount) {
      return amount;
    }
    // 2. trying to redeem liquidity from AAVE
    uint toRedeem = min(redeemable, amount);
    if (toRedeem == 0) {
      return amount;
    }
    IEIP20 aToken = overlying(IEIP20(order.outbound_tkn));
    try aToken.transferFrom(owner, address(this), amount) returns (
      bool success
    ) {
      if (!success) {
        // notRedeemed > 0 should not happen unless lender is out of cash, thus no need to try to borrow
        // log already emitted by `aaveRedeem`
        emit LogIncident(
          order.outbound_tkn,
          order.inbound_tkn,
          order.offerId,
          "Multi/aaveTrader/aTkn/Transfer"
        );
        return amount;
      }
      // overlying transfer has succeeded, anything wrong beyond this point should revert
      require(aaveRedeem(toRedeem, address(this), order) == 0); // throwing to cancel transfer of overlying
      amount = amount - toRedeem;
      if (amount == 0) {
        return 0;
      }
      uint toBorrow = min(liquidity_after_redeem, amount);
      // 3. trying to borrow missing liquidity, failure to borrow will revert
      lendingPool.borrow(
        order.outbound_tkn,
        toBorrow,
        interestRateMode,
        referralCode,
        address(this)
      );
    } catch {
      // overlying transfer reverted.
      emit LogIncident(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "Multi/aaveTrader/aTkn/Transfer"
      );
      return amount;
    }
  }

  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    //optim
    if (amount == 0) {
      return 0;
    }
    // trying to repay debt if user is in borrow position for inbound_tkn token
    DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(
      order.inbound_tkn
    );

    uint debtOfUnderlying;
    if (interestRateMode == 1) {
      debtOfUnderlying = IEIP20(reserveData.stableDebtTokenAddress).balanceOf(
        address(this)
      );
    } else {
      debtOfUnderlying = IEIP20(reserveData.variableDebtTokenAddress).balanceOf(
          address(this)
        );
    }

    uint toRepay = min(debtOfUnderlying, amount);

    uint toMint;
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    try lendingPool.repay(order.inbound_tkn, toRepay, interestRateMode, owner) {
      toMint = sub_(amount, toRepay);
    } catch {
      emit LogIncident(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "Multi/aaveTrader/aTkn/repay"
      );
      toMint = amount;
    }
    return aaveMint(toMint, owner, order);
  }
}

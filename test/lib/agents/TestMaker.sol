// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.13;

import "mgv_src/AbstractMangrove.sol";
import {IERC20, MgvLib, IMaker, OL} from "mgv_src/MgvLib.sol";
import {Test} from "forge-std/Test.sol";
import {TransferLib} from "mgv_lib/TransferLib.sol";
import "mgv_lib/Debug.sol";

contract TrivialTestMaker is IMaker {
  function makerExecute(MgvLib.SingleOrder calldata) external virtual returns (bytes32) {
    return "";
  }

  function makerPosthook(MgvLib.SingleOrder calldata, MgvLib.OrderResult calldata) external virtual {}
}

//TODO add posthookShouldRevert/posthookReturnData
struct OfferData {
  bool shouldRevert;
  string executeData;
}

contract SimpleTestMaker is TrivialTestMaker {
  AbstractMangrove public mgv;
  OL ol;
  bool shouldFail_; // will set mgv allowance to 0
  bool shouldRevert_; // will revert
  bool shouldRepost_; // will try to repost offer with identical parameters
  bytes32 expectedStatus;
  ///@notice stores parameters for each posted offer
  ///@notice overrides global @shouldFail/shouldReturn if true

  mapping(bytes32 => mapping(uint => OfferData)) offerDatas;

  constructor(AbstractMangrove _mgv, OL memory _ol) {
    mgv = _mgv;
    ol = _ol;
  }

  receive() external payable {}

  event Execute(
    address mgv, address base, address quote, uint tickScale, uint offerId, uint takerWants, uint takerGives
  );

  function logExecute(address _mgv, OL calldata ol, uint offerId, uint takerWants, uint takerGives) external {
    emit Execute(_mgv, ol.outbound, ol.inbound, ol.tickScale, offerId, takerWants, takerGives);
  }

  function shouldRevert(bool should) external {
    shouldRevert_ = should;
  }

  function shouldFail(bool should) external {
    shouldFail_ = should;
  }

  function shouldRepost(bool should) external {
    shouldRepost_ = should;
  }

  function approveMgv(IERC20 token, uint amount) public {
    TransferLib.approveToken(token, address(mgv), amount);
  }

  function expect(bytes32 mgvData) external {
    expectedStatus = mgvData;
  }

  function transferToken(IERC20 token, address to, uint amount) external {
    TransferLib.transferToken(token, to, amount);
  }

  function makerExecute(MgvLib.SingleOrder calldata order) public virtual override returns (bytes32) {
    if (shouldRevert_) {
      revert("testMaker/shouldRevert");
    }

    OfferData memory offerData = offerDatas[order.ol.id()][order.offerId];

    if (offerData.shouldRevert) {
      revert(offerData.executeData);
    }

    if (shouldFail_) {
      TransferLib.approveToken(IERC20(order.ol.outbound), address(mgv), 0);
    }

    emit Execute(
      msg.sender, order.ol.outbound, order.ol.inbound, order.ol.tickScale, order.offerId, order.wants, order.gives
    );

    return bytes32(bytes(offerData.executeData));
  }

  bool _shouldFailHook;

  function setShouldFailHook(bool should) external {
    _shouldFailHook = should;
  }

  function makerPosthook(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result) public virtual override {
    order; //shh
    result; //shh
    if (_shouldFailHook) {
      revert("posthookFail");
    }

    if (shouldRepost_) {
      mgv.updateOfferByVolume(
        order.ol, order.offer.wants(), order.offer.gives(), order.offerDetail.gasreq(), 0, order.offerId
      );
    }
  }

  function newOfferByVolume(uint wants, uint gives, uint gasreq) public returns (uint) {
    return newOfferByVolume(ol, wants, gives, gasreq);
  }

  function newOfferByVolume(uint wants, uint gives, uint gasreq, OfferData memory offerData) public returns (uint) {
    return newOfferByVolume(ol, wants, gives, gasreq, offerData);
  }

  function newOfferByVolumeWithFunding(uint wants, uint gives, uint gasreq, uint amount) public returns (uint) {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, 0, amount);
  }

  function newOfferByVolumeWithFunding(uint wants, uint gives, uint gasreq, uint amount, OfferData memory offerData)
    public
    returns (uint)
  {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, 0, amount, offerData);
  }

  function newOfferByVolumeWithFunding(uint wants, uint gives, uint gasreq, uint gasprice, uint amount)
    public
    returns (uint)
  {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, gasprice, amount);
  }

  function newOfferByVolume(OL memory ol, uint wants, uint gives, uint gasreq) public returns (uint) {
    OfferData memory offerData;
    return newOfferByVolume(ol, wants, gives, gasreq, offerData);
  }

  function newOfferByVolume(OL memory ol, uint wants, uint gives, uint gasreq, OfferData memory offerData)
    public
    returns (uint)
  {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, 0, 0, offerData);
  }

  function newOfferByVolumeWithFunding(OL memory ol, uint wants, uint gives, uint gasreq, uint amount)
    public
    returns (uint)
  {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, 0, amount);
  }

  function newOfferByVolumeWithFunding(
    OL memory ol,
    uint wants,
    uint gives,
    uint gasreq,
    uint amount,
    OfferData memory offerData
  ) public returns (uint) {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, 0, amount, offerData);
  }

  function newOfferByVolume(uint wants, uint gives, uint gasreq, uint gasprice) public returns (uint) {
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, gasprice, 0);
  }

  function newOfferByVolumeWithFunding(OL memory ol, uint wants, uint gives, uint gasreq, uint gasprice, uint amount)
    public
    returns (uint)
  {
    OfferData memory offerData;
    return newOfferByVolumeWithFunding(ol, wants, gives, gasreq, gasprice, amount, offerData);
  }

  function newOfferByVolumeWithFunding(
    OL memory ol,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint amount,
    OfferData memory offerData
  ) public returns (uint) {
    uint offerId = mgv.newOfferByVolume{value: amount}(ol, wants, gives, gasreq, gasprice);
    offerDatas[ol.id()][offerId] = offerData;
    return offerId;
  }

  function newOfferByLogPrice(int logPrice, uint gives, uint gasreq, uint gasprice) public returns (uint) {
    return newOfferByLogPriceWithFunding(ol, logPrice, gives, gasreq, gasprice, 0);
  }

  function newOfferByLogPriceWithFunding(
    OL memory ol,
    int logPrice,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint amount
  ) public returns (uint) {
    OfferData memory offerData;
    return newOfferByLogPriceWithFunding(ol, logPrice, gives, gasreq, gasprice, amount, offerData);
  }

  function newOfferByLogPriceWithFunding(
    OL memory ol,
    int logPrice,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint amount,
    OfferData memory offerData
  ) public returns (uint) {
    uint offerId = mgv.newOfferByLogPrice{value: amount}(ol, logPrice, gives, gasreq, gasprice);
    offerDatas[ol.id()][offerId] = offerData;
    return offerId;
  }

  function updateOfferByVolume(uint wants, uint gives, uint gasreq, uint offerId, OfferData memory offerData) public {
    updateOfferByVolumeWithFunding(wants, gives, gasreq, offerId, 0, offerData);
  }

  function updateOfferByVolume(uint wants, uint gives, uint gasreq, uint offerId) public {
    OfferData memory offerData;
    updateOfferByVolumeWithFunding(wants, gives, gasreq, offerId, 0, offerData);
  }

  function updateOfferByVolumeWithFunding(uint wants, uint gives, uint gasreq, uint offerId, uint amount) public {
    OfferData memory offerData;
    updateOfferByVolumeWithFunding(wants, gives, gasreq, offerId, amount, offerData);
  }

  function updateOfferByVolumeWithFunding(
    uint wants,
    uint gives,
    uint gasreq,
    uint offerId,
    uint amount,
    OfferData memory offerData
  ) public {
    mgv.updateOfferByVolume{value: amount}(ol, wants, gives, gasreq, 0, offerId);
    offerDatas[ol.id()][offerId] = offerData;
  }

  function retractOffer(uint offerId) public returns (uint) {
    return mgv.retractOffer(ol, offerId, false);
  }

  function retractOfferWithDeprovision(uint offerId) public returns (uint) {
    return mgv.retractOffer(ol, offerId, true);
  }

  function provisionMgv(uint amount) public payable {
    mgv.fund{value: amount}(address(this));
  }

  function withdrawMgv(uint amount) public returns (bool) {
    return mgv.withdraw(amount);
  }

  function mgvBalance() public view returns (uint) {
    return mgv.balanceOf(address(this));
  }
}

contract TestMaker is SimpleTestMaker, Test {
  constructor(AbstractMangrove mgv, OL memory ol) SimpleTestMaker(mgv, ol) {}

  function makerPosthook(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result) public virtual override {
    if (expectedStatus != bytes32("")) {
      assertEq(result.mgvData, expectedStatus, "Incorrect status message");
    }
    super.makerPosthook(order, result);
  }
}

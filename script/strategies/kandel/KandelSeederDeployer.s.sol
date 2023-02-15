// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IMangrove, IERC20, KandelSeeder} from "mgv_src/strategies/offer_maker/market_making/kandel/KandelSeeder.sol";
import {CoreKandel} from "mgv_src/strategies/offer_maker/market_making/kandel/abstract/CoreKandel.sol";
import {AavePooledRouter} from "mgv_src/strategies/offer_maker/market_making/kandel/AaveKandel.sol";
import {Deployer} from "mgv_script/lib/Deployer.sol";
import {MangroveTest, Test} from "mgv_test/lib/MangroveTest.sol";

/**
 * @notice deploys a Kandel seeder
 */

contract KandelSeederDeployer is Deployer {
  function run() public {
    innerRun({
      mgv: IMangrove(fork.get("Mangrove")),
      addressesProvider: fork.get("Aave"),
      aaveKandelGasreq: vm.envUint("AAVE_KANDEL_GASREQ"),
      kandelGasreq: vm.envUint("KANDEL_GASREQ"),
      aaveRouterGasreq: vm.envUint("AAVE_ROUTER_GASREQ")
    });
    smokeTest(KandelSeeder(fork.get("KandelSeeder")));
    outputDeployment();
  }

  function innerRun(
    IMangrove mgv,
    address addressesProvider,
    uint aaveRouterGasreq,
    uint aaveKandelGasreq,
    uint kandelGasreq
  ) public {
    prettyLog("Deploying Kandel seeder...");

    prettyLog("Deploying AavePooledRouter...");
    broadcast();
    AavePooledRouter aavePooledRouter = new AavePooledRouter(addressesProvider, aaveRouterGasreq);

    broadcast();
    KandelSeeder seeder = new KandelSeeder(mgv, aavePooledRouter, aaveKandelGasreq, kandelGasreq);
    broadcast();
    aavePooledRouter.setAdmin(address(seeder));

    fork.set("KandelSeeder", address(seeder));
    console.log("Deployed!");
  }

  function smokeTest(KandelSeeder kandelSeeder) internal {
    string memory baseName;
    string memory quoteName;
    if (keccak256(abi.encode(fork.NAME())) == keccak256("mumbai")) {
      baseName = "WETH_AAVE";
      quoteName = "DAI_AAVE";
    } else {
      baseName = "WETH";
      quoteName = "DAI";
    }
    IERC20 base = IERC20(fork.get("WETH"));
    IERC20 quote = IERC20(fork.get("DAI"));

    KandelSeeder.KandelSeed memory seed =
      KandelSeeder.KandelSeed({base: base, quote: quote, gasprice: 0, onAave: true, liquiditySharing: true});
    CoreKandel kdl = kandelSeeder.sow(seed);
    require(address(kdl.router()) == address(kandelSeeder.AAVE_ROUTER()), "Incorrect router address");
    require(kdl.admin() == address(this), "Incorrect admin");
    require(kdl.RESERVE_ID() == kdl.admin(), "Incorrect id");
    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = base;
    tokens[1] = quote;
    kdl.checkList(tokens);
  }
}

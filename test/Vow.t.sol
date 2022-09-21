// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { Ball } from '../src/ball.sol';
import { GemLike } from '../src/abi.sol';
import { VatLike } from '../src/abi.sol';
import { RicoSetUp } from "./RicoHelper.sol";
import { Asset, BalSetUp, PoolArgs } from "./BalHelper.sol";

contract VowTest is Test, RicoSetUp, BalSetUp {
    uint256 public init_join = 1000;
    uint stack = WAD * 10;
    bytes32[] ilks;
    bytes32 pool_id_rico_risk;
    bytes32 pool_id_gold_rico;

    function setUp() public {
        make_bank();
        init_gold();
        ilks.push(gilk);
        rico.approve(address(flow), type(uint256).max);
        dock.join_gem(avat, gilk, self, init_join * WAD);

        flow.setVault(BAL_VAULT);
        vow.grant(address(gold));
        vow.grant(address(rico));
        vow.grant(address(risk));

        feed.push(gtag, bytes32(RAY * 1000), block.timestamp + 1000);
        vat.frob(gilk, address(this), int(init_join * WAD), int(stack) * 1000);
        dock.exit_rico(avat, arico, self, 10000 * WAD);
        risk.mint(address(this), 10000 * WAD);

        vow.pair(agold, 'vel', 1e18);
        vow.pair(agold, 'rel', 1e12);
        vow.pair(agold, 'cel', 600);
        vow.pair(arico, 'vel', 1e18);
        vow.pair(arico, 'rel', 1e12);
        vow.pair(arico, 'cel', 600);
        vow.pair(arisk, 'vel', 1e18);
        vow.pair(arisk, 'rel', 1e12);
        vow.pair(arisk, 'cel', 600);
        vow.pair(address(0), 'vel', 1e18);
        vow.pair(address(0), 'rel', 1e12);
        vow.pair(address(0), 'cel', 600);

        // have 10k each of rico, risk and gold
        gold.approve(BAL_VAULT, type(uint256).max);
        rico.approve(BAL_VAULT, type(uint256).max);
        risk.approve(BAL_VAULT, type(uint256).max);
        gold.approve(address(flow), type(uint256).max);
        rico.approve(address(flow), type(uint256).max);
        risk.approve(address(flow), type(uint256).max);

        Asset memory gold_asset = Asset(agold, 5 * WAD / 10, 1000 * WAD);
        Asset memory rico_asset = Asset(arico, 5 * WAD / 10, 1000 * WAD);
        Asset memory risk_asset = Asset(arisk, 5 * WAD / 10, 1000 * WAD);

        PoolArgs memory rico_risk_args = PoolArgs(rico_asset, risk_asset, "mock", "MOCK", WAD / 100);
        PoolArgs memory gold_rico_args = PoolArgs(gold_asset, rico_asset, "mock", "MOCK", WAD / 100);

        pool_id_rico_risk = create_pool(rico_risk_args);
        pool_id_gold_rico = create_pool(gold_rico_args);

        flow.setPool(arico, arisk, pool_id_rico_risk);
        flow.setPool(arisk, arico, pool_id_rico_risk);
        flow.setPool(arico, agold, pool_id_gold_rico);
        flow.setPool(agold, arico, pool_id_gold_rico);
    }

    // goldusd, par, and liqr all = 1 after set up.
    function test_risk_ramp_is_used() public {
        // set rate of risk sales to near zero
        address[] memory tokens;
        uint256[] memory balances0;
        uint256[] memory balances1;
        uint256 lastChangeBlock;
        uint rico_index = 0;
        uint risk_index = 1;
        vow.pair(arisk, 'vel', 1);
        vow.pair(arisk, 'rel', 1);
        vow.pair(arisk, 'cel', 1);
        (tokens, balances0, lastChangeBlock) = vault.getPoolTokens(pool_id_rico_risk);
        if (arisk == tokens[0]) {
            risk_index = 0;
            rico_index = 1;
        }

        // setup frobbed to edge, dropping gold price puts system way underwater
        feed.push(gtag, bytes32(RAY), block.timestamp + 10000);

        // create the sin and kick off risk sale
        vow.bail(gilk, self);
        vow.keep(ilks);
        (tokens, balances1, lastChangeBlock) = vault.getPoolTokens(pool_id_rico_risk);

        // correct risk ramp usage should limit sale to one
        uint risk_sold = balances1[risk_index] - balances0[risk_index];
        assertTrue(risk_sold == 1);
    }
}

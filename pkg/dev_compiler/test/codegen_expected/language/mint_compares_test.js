dart_library.library('language/mint_compares_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mint_compares_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mint_compares_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  mint_compares_test.compareTest = function() {
    expect$.Expect.isFalse(4294967296 < 6);
    expect$.Expect.isFalse(4294967296 < 4294967296);
    expect$.Expect.isFalse(4294967296 <= 6);
    expect$.Expect.isTrue(4294967296 <= 4294967296);
    expect$.Expect.isFalse(4294967296 < 4294967295);
    expect$.Expect.isTrue(-4294967296 < 6);
    expect$.Expect.isTrue(-4294967296 < 4294967296);
    expect$.Expect.isTrue(-4294967296 <= 6);
    expect$.Expect.isTrue(-4294967296 <= 4294967296);
    expect$.Expect.isTrue(-4294967296 < 4294967295);
    expect$.Expect.isFalse(4294967296 < -6);
    expect$.Expect.isFalse(4294967296 <= -6);
    expect$.Expect.isFalse(4294967296 < -4294967295);
    expect$.Expect.isTrue(-4294967296 < -6);
    expect$.Expect.isTrue(-4294967296 <= -6);
    expect$.Expect.isTrue(-4294967296 < -4294967295);
    expect$.Expect.isTrue(4294967296 > 6);
    expect$.Expect.isFalse(4294967296 > 4294967296);
    expect$.Expect.isTrue(4294967296 >= 6);
    expect$.Expect.isTrue(4294967296 >= 4294967296);
    expect$.Expect.isTrue(4294967296 > 4294967295);
    expect$.Expect.isFalse(-4294967296 > 6);
    expect$.Expect.isFalse(-4294967296 > 4294967296);
    expect$.Expect.isFalse(-4294967296 >= 6);
    expect$.Expect.isFalse(-4294967296 >= 4294967296);
    expect$.Expect.isFalse(-4294967296 > 4294967295);
    expect$.Expect.isTrue(4294967296 > -6);
    expect$.Expect.isTrue(4294967296 >= -6);
    expect$.Expect.isTrue(4294967296 > -4294967295);
    expect$.Expect.isFalse(-4294967296 > -6);
    expect$.Expect.isFalse(-4294967296 >= -6);
    expect$.Expect.isFalse(-4294967296 > -4294967295);
    expect$.Expect.isTrue(4294967296 < 184467440737095516150);
    expect$.Expect.isTrue(-4294967296 < 184467440737095516150);
    expect$.Expect.isFalse(4294967296 < -184467440737095516150);
    expect$.Expect.isFalse(-4294967296 < -184467440737095516150);
  };
  dart.fn(mint_compares_test.compareTest, VoidTodynamic());
  mint_compares_test.compareTest2 = function(lt, lte, gt, gte) {
    expect$.Expect.isFalse(dart.dcall(lt, 4294967296, 6));
    expect$.Expect.isFalse(dart.dcall(lte, 4294967296, 6));
    expect$.Expect.isTrue(dart.dcall(gt, 4294967296, 6));
    expect$.Expect.isTrue(dart.dcall(gte, 4294967296, 6));
    expect$.Expect.isTrue(dart.dcall(lte, -1, -1));
    expect$.Expect.isTrue(dart.dcall(gte, -1, -1));
    expect$.Expect.isTrue(dart.dcall(lte, -2, -1));
    expect$.Expect.isFalse(dart.dcall(gte, -2, -1));
    expect$.Expect.isTrue(dart.dcall(lte, -4294967296, -1));
    expect$.Expect.isFalse(dart.dcall(gte, -4294967296, -1));
    expect$.Expect.isTrue(dart.dcall(lt, -2, -1));
    expect$.Expect.isFalse(dart.dcall(gt, -2, -1));
    expect$.Expect.isTrue(dart.dcall(lt, -4294967296, -1));
    expect$.Expect.isFalse(dart.dcall(gt, -4294967296, -1));
    expect$.Expect.isFalse(dart.dcall(lt, -1, -4294967296));
    expect$.Expect.isTrue(dart.dcall(gt, -1, -4294967296));
    expect$.Expect.isFalse(dart.dcall(lt, 2, -2));
    expect$.Expect.isTrue(dart.dcall(gt, 2, -2));
    expect$.Expect.isFalse(dart.dcall(lt, 4294967296, -1));
    expect$.Expect.isTrue(dart.dcall(gt, 4294967296, -1));
  };
  dart.fn(mint_compares_test.compareTest2, dynamicAnddynamicAnddynamic__Todynamic());
  mint_compares_test.lt1 = function(a, b) {
    return core.bool._check(dart.dsend(a, '<', b));
  };
  dart.fn(mint_compares_test.lt1, dynamicAnddynamicTobool());
  mint_compares_test.lte1 = function(a, b) {
    return core.bool._check(dart.dsend(a, '<=', b));
  };
  dart.fn(mint_compares_test.lte1, dynamicAnddynamicTobool());
  mint_compares_test.gt1 = function(a, b) {
    return core.bool._check(dart.dsend(a, '>', b));
  };
  dart.fn(mint_compares_test.gt1, dynamicAnddynamicTobool());
  mint_compares_test.gte1 = function(a, b) {
    return core.bool._check(dart.dsend(a, '>=', b));
  };
  dart.fn(mint_compares_test.gte1, dynamicAnddynamicTobool());
  mint_compares_test.lt2 = function(a, b) {
    return dart.test(dart.dsend(a, '<', b)) ? true : false;
  };
  dart.fn(mint_compares_test.lt2, dynamicAnddynamicTobool());
  mint_compares_test.lte2 = function(a, b) {
    return dart.test(dart.dsend(a, '<=', b)) ? true : false;
  };
  dart.fn(mint_compares_test.lte2, dynamicAnddynamicTobool());
  mint_compares_test.gt2 = function(a, b) {
    return dart.test(dart.dsend(a, '>', b)) ? true : false;
  };
  dart.fn(mint_compares_test.gt2, dynamicAnddynamicTobool());
  mint_compares_test.gte2 = function(a, b) {
    return dart.test(dart.dsend(a, '>=', b)) ? true : false;
  };
  dart.fn(mint_compares_test.gte2, dynamicAnddynamicTobool());
  mint_compares_test.main = function() {
    for (let i = 0; i < 20; i++) {
      mint_compares_test.compareTest();
      mint_compares_test.compareTest2(mint_compares_test.lt1, mint_compares_test.lte1, mint_compares_test.gt1, mint_compares_test.gte1);
      mint_compares_test.compareTest2(mint_compares_test.lt2, mint_compares_test.lte2, mint_compares_test.gt2, mint_compares_test.gte2);
    }
  };
  dart.fn(mint_compares_test.main, VoidTodynamic());
  // Exports:
  exports.mint_compares_test = mint_compares_test;
});

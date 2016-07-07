dart_library.library('language/branch_canonicalization_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__branch_canonicalization_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const branch_canonicalization_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  branch_canonicalization_test.sideEffect = true;
  branch_canonicalization_test.barDouble = function(a, b) {
    branch_canonicalization_test.sideEffect = false;
    let result = dart.equals(a, b);
    branch_canonicalization_test.sideEffect = !dart.test(branch_canonicalization_test.sideEffect);
    return result;
  };
  dart.fn(branch_canonicalization_test.barDouble, dynamicAnddynamicTodynamic());
  branch_canonicalization_test.fooDouble = function(a, b) {
    return dart.test(branch_canonicalization_test.barDouble(a, b)) ? 1 : 0;
  };
  dart.fn(branch_canonicalization_test.fooDouble, dynamicAnddynamicTodynamic());
  branch_canonicalization_test.barMint = function(a, b) {
    branch_canonicalization_test.sideEffect = false;
    let result = dart.equals(a, b);
    branch_canonicalization_test.sideEffect = !dart.test(branch_canonicalization_test.sideEffect);
    return result;
  };
  dart.fn(branch_canonicalization_test.barMint, dynamicAnddynamicTodynamic());
  branch_canonicalization_test.fooMint = function(a, b) {
    return dart.test(branch_canonicalization_test.barMint(a, b)) ? 1 : 0;
  };
  dart.fn(branch_canonicalization_test.fooMint, dynamicAnddynamicTodynamic());
  branch_canonicalization_test.A = class A extends core.Object {
    ['=='](other) {
      return core.identical(this, other);
    }
  };
  branch_canonicalization_test.B = class B extends branch_canonicalization_test.A {};
  branch_canonicalization_test.C = class C extends branch_canonicalization_test.A {};
  branch_canonicalization_test.barPoly = function(a, b) {
    branch_canonicalization_test.sideEffect = false;
    let result = dart.equals(a, b);
    branch_canonicalization_test.sideEffect = !dart.test(branch_canonicalization_test.sideEffect);
    return result;
  };
  dart.fn(branch_canonicalization_test.barPoly, dynamicAnddynamicTodynamic());
  branch_canonicalization_test.fooPoly = function(a, b) {
    return dart.test(branch_canonicalization_test.barPoly(a, b)) ? 1 : 0;
  };
  dart.fn(branch_canonicalization_test.fooPoly, dynamicAnddynamicTodynamic());
  branch_canonicalization_test.main = function() {
    let a = 1.0;
    let b = (1)[dartx['<<']](62);
    let x = new branch_canonicalization_test.A(), y = new branch_canonicalization_test.B(), z = new branch_canonicalization_test.C();
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(1, branch_canonicalization_test.fooDouble(a, a));
      expect$.Expect.isTrue(branch_canonicalization_test.sideEffect);
      expect$.Expect.equals(0, branch_canonicalization_test.fooMint(b, 0));
      expect$.Expect.isTrue(branch_canonicalization_test.sideEffect);
      expect$.Expect.equals(1, branch_canonicalization_test.fooPoly(x, x));
      expect$.Expect.equals(0, branch_canonicalization_test.fooPoly(y, x));
    }
    expect$.Expect.equals(1, branch_canonicalization_test.fooDouble(z, z));
    expect$.Expect.isTrue(branch_canonicalization_test.sideEffect);
    expect$.Expect.equals(1, branch_canonicalization_test.fooMint(z, z));
    expect$.Expect.isTrue(branch_canonicalization_test.sideEffect);
    expect$.Expect.equals(1, branch_canonicalization_test.fooPoly(z, z));
    expect$.Expect.isTrue(branch_canonicalization_test.sideEffect);
  };
  dart.fn(branch_canonicalization_test.main, VoidTodynamic());
  // Exports:
  exports.branch_canonicalization_test = branch_canonicalization_test;
});

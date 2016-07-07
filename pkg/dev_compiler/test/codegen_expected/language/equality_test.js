dart_library.library('language/equality_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__equality_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const equality_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  const _result = Symbol('_result');
  equality_test.A = class A extends core.Object {
    new(result) {
      this[_result] = result;
    }
    ['=='](x) {
      return this[_result];
    }
  };
  dart.setSignature(equality_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(equality_test.A, [core.bool])})
  });
  equality_test.opaque = function(x) {
    return [x, 1, 'y'][dartx.get](0);
  };
  dart.fn(equality_test.opaque, dynamicTodynamic());
  equality_test.Death = class Death extends core.Object {
    ['=='](x) {
      dart.throw('Dead!');
    }
  };
  equality_test.death = function() {
    return equality_test.opaque(new equality_test.Death());
  };
  dart.fn(equality_test.death, VoidTodynamic());
  equality_test.nullFn = function() {
    return equality_test.opaque(null);
  };
  dart.fn(equality_test.nullFn, VoidTodynamic());
  equality_test.tests = function() {
    let alwaysTrue = new equality_test.A(true);
    let alwaysFalse = new equality_test.A(false);
    expect$.Expect.isFalse(dart.equals(alwaysFalse, alwaysFalse));
    expect$.Expect.isTrue(!dart.equals(alwaysFalse, alwaysFalse));
    expect$.Expect.isTrue(dart.equals(alwaysTrue, alwaysTrue));
    expect$.Expect.isTrue(dart.equals(alwaysTrue, 5));
    expect$.Expect.isFalse(alwaysTrue == null);
    expect$.Expect.isFalse(null == alwaysTrue);
    expect$.Expect.isTrue(alwaysTrue != null);
    expect$.Expect.isTrue(null != alwaysTrue);
    expect$.Expect.isTrue(null == null);
    expect$.Expect.isFalse(null != null);
    expect$.Expect.throws(dart.fn(() => dart.equals(equality_test.death(), 5), VoidTobool()));
    expect$.Expect.isFalse(dart.equals(equality_test.death(), equality_test.nullFn()));
    expect$.Expect.isFalse(dart.equals(equality_test.nullFn(), equality_test.death()));
    expect$.Expect.isTrue(dart.equals(equality_test.nullFn(), equality_test.nullFn()));
    expect$.Expect.isTrue(!dart.equals(equality_test.death(), equality_test.nullFn()));
    expect$.Expect.isTrue(!dart.equals(equality_test.nullFn(), equality_test.death()));
    expect$.Expect.isFalse(!dart.equals(equality_test.nullFn(), equality_test.nullFn()));
    if (dart.equals(equality_test.death(), equality_test.nullFn())) {
      dart.throw("failed");
    }
    if (!dart.equals(equality_test.death(), equality_test.nullFn())) {
    } else {
      dart.throw("failed");
    }
  };
  dart.fn(equality_test.tests, VoidTodynamic());
  equality_test.boolEqualityPositiveA = function(a) {
    return dart.equals(a, true);
  };
  dart.fn(equality_test.boolEqualityPositiveA, dynamicTodynamic());
  equality_test.boolEqualityNegativeA = function(a) {
    return !dart.equals(a, true);
  };
  dart.fn(equality_test.boolEqualityNegativeA, dynamicTodynamic());
  equality_test.boolEqualityPositiveB = function(a) {
    return dart.equals(true, a);
  };
  dart.fn(equality_test.boolEqualityPositiveB, dynamicTodynamic());
  equality_test.boolEqualityNegativeB = function(a) {
    return !dart.equals(true, a);
  };
  dart.fn(equality_test.boolEqualityNegativeB, dynamicTodynamic());
  equality_test.main = function() {
    for (let i = 0; i < 20; i++) {
      equality_test.tests();
      expect$.Expect.isTrue(equality_test.boolEqualityPositiveA(true));
      expect$.Expect.isFalse(equality_test.boolEqualityPositiveA(false));
      expect$.Expect.isFalse(equality_test.boolEqualityNegativeA(true));
      expect$.Expect.isTrue(equality_test.boolEqualityNegativeA(false));
      expect$.Expect.isTrue(equality_test.boolEqualityPositiveB(true));
      expect$.Expect.isFalse(equality_test.boolEqualityPositiveB(false));
      expect$.Expect.isFalse(equality_test.boolEqualityNegativeB(true));
      expect$.Expect.isTrue(equality_test.boolEqualityNegativeB(false));
    }
    expect$.Expect.isFalse(equality_test.boolEqualityPositiveA(1));
    expect$.Expect.isTrue(equality_test.boolEqualityNegativeA("hi"));
    expect$.Expect.isFalse(equality_test.boolEqualityPositiveB(2.0));
    expect$.Expect.isTrue(equality_test.boolEqualityNegativeB([]));
  };
  dart.fn(equality_test.main, VoidTodynamic());
  // Exports:
  exports.equality_test = equality_test;
});

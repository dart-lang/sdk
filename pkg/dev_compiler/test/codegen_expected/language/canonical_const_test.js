dart_library.library('language/canonical_const_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__canonical_const_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const canonical_const_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  let const$8;
  let const$9;
  let const$10;
  let const$11;
  let const$12;
  let const$13;
  let const$14;
  let const$15;
  let const$16;
  let const$17;
  let const$18;
  let const$19;
  let const$20;
  canonical_const_test.CanonicalConstTest = class CanonicalConstTest extends core.Object {
    static testMain() {
      expect$.Expect.identical(null, null);
      expect$.Expect.isFalse(core.identical(null, 0));
      expect$.Expect.identical(1, 1);
      expect$.Expect.isFalse(core.identical(1, 2));
      expect$.Expect.identical(true, true);
      expect$.Expect.identical("so", "so");
      expect$.Expect.identical(const$ || (const$ = dart.const(new core.Object())), const$0 || (const$0 = dart.const(new core.Object())));
      expect$.Expect.isFalse(core.identical(const$1 || (const$1 = dart.const(new core.Object())), const$2 || (const$2 = dart.const(new canonical_const_test.C1()))));
      expect$.Expect.identical(const$3 || (const$3 = dart.const(new canonical_const_test.C1())), const$4 || (const$4 = dart.const(new canonical_const_test.C1())));
      expect$.Expect.identical(canonical_const_test.CanonicalConstTest.A, const$5 || (const$5 = dart.const(new canonical_const_test.C1())));
      expect$.Expect.isFalse(core.identical(const$6 || (const$6 = dart.const(new canonical_const_test.C1())), const$7 || (const$7 = dart.const(new canonical_const_test.C2()))));
      expect$.Expect.identical(canonical_const_test.CanonicalConstTest.B, const$8 || (const$8 = dart.const(new canonical_const_test.C2())));
      expect$.Expect.isFalse(core.identical(const$9 || (const$9 = dart.constList([2, 1], core.int)), const$10 || (const$10 = dart.constList([1, 2], core.int))));
      expect$.Expect.identical(const$11 || (const$11 = dart.constList([1, 2], core.int)), const$12 || (const$12 = dart.constList([1, 2], core.int)));
      expect$.Expect.identical(const$13 || (const$13 = dart.constList([1, 2], core.Object)), const$14 || (const$14 = dart.constList([1, 2], core.Object)));
      expect$.Expect.isFalse(core.identical(const$15 || (const$15 = dart.constList([1, 2], core.int)), const$16 || (const$16 = dart.constList([1.0, 2.0], core.double))));
      expect$.Expect.identical(const$17 || (const$17 = dart.const(dart.map({a: 1, b: 2}))), const$18 || (const$18 = dart.const(dart.map({a: 1, b: 2}))));
      expect$.Expect.isFalse(core.identical(const$19 || (const$19 = dart.const(dart.map({a: 1, b: 2}))), const$20 || (const$20 = dart.const(dart.map({a: 2, b: 2})))));
    }
  };
  dart.setSignature(canonical_const_test.CanonicalConstTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  dart.defineLazy(canonical_const_test.CanonicalConstTest, {
    get A() {
      return dart.const(new canonical_const_test.C1());
    },
    get B() {
      return dart.const(new canonical_const_test.C2());
    }
  });
  canonical_const_test.C1 = class C1 extends core.Object {
    new() {
    }
  };
  dart.setSignature(canonical_const_test.C1, {
    constructors: () => ({new: dart.definiteFunctionType(canonical_const_test.C1, [])})
  });
  canonical_const_test.C2 = class C2 extends canonical_const_test.C1 {
    new() {
      super.new();
    }
  };
  dart.setSignature(canonical_const_test.C2, {
    constructors: () => ({new: dart.definiteFunctionType(canonical_const_test.C2, [])})
  });
  canonical_const_test.main = function() {
    canonical_const_test.CanonicalConstTest.testMain();
  };
  dart.fn(canonical_const_test.main, VoidTodynamic());
  // Exports:
  exports.canonical_const_test = canonical_const_test;
});

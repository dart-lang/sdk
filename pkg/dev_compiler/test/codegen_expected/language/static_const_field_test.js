dart_library.library('language/static_const_field_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_const_field_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_const_field_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_const_field_test.Spain = class Spain extends core.Object {};
  static_const_field_test.Spain.AG = "Antoni Gaudi";
  static_const_field_test.Spain.SD = "Salvador Dali";
  static_const_field_test.Switzerland = class Switzerland extends core.Object {};
  static_const_field_test.Switzerland.AG = "Alberto Giacometti";
  static_const_field_test.Switzerland.LC = "Le Corbusier";
  static_const_field_test.A = class A extends core.Object {
    new() {
      this.n = 5;
    }
  };
  static_const_field_test.A[dart.implements] = () => [static_const_field_test.Switzerland];
  dart.setSignature(static_const_field_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(static_const_field_test.A, [])})
  });
  static_const_field_test.A.b = 3 + 5;
  static_const_field_test.A.s1 = "hula";
  static_const_field_test.A.s2 = "hula";
  static_const_field_test.A.s3 = "hop";
  static_const_field_test.A.d1 = 1.1;
  static_const_field_test.A.d2 = 0.55 + 0.55;
  static_const_field_test.A.artist2 = static_const_field_test.Switzerland.AG;
  static_const_field_test.A.architect1 = static_const_field_test.Spain.AG;
  static_const_field_test.A.array1 = dart.constList([1, 2], core.int);
  static_const_field_test.A.map1 = dart.const(dart.map({Monday: 1, Tuesday: 2}, core.String, core.int));
  dart.defineLazy(static_const_field_test.A, {
    get a() {
      return dart.const(new static_const_field_test.A());
    },
    get c() {
      return static_const_field_test.A.b + 7;
    },
    get d() {
      return dart.const(new static_const_field_test.A());
    }
  });
  static_const_field_test.StaticFinalFieldTest = class StaticFinalFieldTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(15, static_const_field_test.A.c);
      expect$.Expect.equals(8, static_const_field_test.A.b);
      expect$.Expect.equals(5, static_const_field_test.A.a.n);
      expect$.Expect.equals(true, core.identical(8, static_const_field_test.A.b));
      expect$.Expect.equals(true, core.identical(static_const_field_test.A.a, static_const_field_test.A.d));
      expect$.Expect.equals(true, core.identical(static_const_field_test.A.s1, static_const_field_test.A.s2));
      expect$.Expect.equals(false, core.identical(static_const_field_test.A.s1, static_const_field_test.A.s3));
      expect$.Expect.equals(false, core.identical(static_const_field_test.A.s1, static_const_field_test.A.b));
      expect$.Expect.equals(true, core.identical(static_const_field_test.A.d1, static_const_field_test.A.d2));
      expect$.Expect.equals(true, static_const_field_test.Spain.SD == "Salvador Dali");
      expect$.Expect.equals(true, static_const_field_test.A.artist2 == "Alberto Giacometti");
      expect$.Expect.equals(true, static_const_field_test.A.architect1 == "Antoni Gaudi");
      expect$.Expect.equals(2, static_const_field_test.A.map1[dartx.get]("Tuesday"));
    }
  };
  dart.setSignature(static_const_field_test.StaticFinalFieldTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  static_const_field_test.main = function() {
    static_const_field_test.StaticFinalFieldTest.testMain();
  };
  dart.fn(static_const_field_test.main, VoidTodynamic());
  // Exports:
  exports.static_const_field_test = static_const_field_test;
});

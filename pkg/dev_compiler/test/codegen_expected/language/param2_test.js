dart_library.library('language/param2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__param2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const param2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  param2_test.Param2Test = class Param2Test extends core.Object {
    static forEach(a, f) {
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, dart.dcall(f, a[dartx.get](i)));
      }
    }
    static apply(f, arg) {
      let res = f(arg);
      return core.int._check(res);
    }
    static exists(a, f) {
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        if (dart.test(dart.dcall(f, a[dartx.get](i)))) return true;
      }
      return false;
    }
    static testMain() {
      function square(x) {
        return dart.notNull(x) * dart.notNull(x);
      }
      dart.fn(square, intToint());
      expect$.Expect.equals(4, param2_test.Param2Test.apply(square, 2));
      expect$.Expect.equals(100, param2_test.Param2Test.apply(square, 10));
      let v = JSArrayOfint().of([1, 2, 3, 4, 5, 6]);
      param2_test.Param2Test.forEach(v, square);
      expect$.Expect.equals(1, v[dartx.get](0));
      expect$.Expect.equals(4, v[dartx.get](1));
      expect$.Expect.equals(9, v[dartx.get](2));
      expect$.Expect.equals(16, v[dartx.get](3));
      expect$.Expect.equals(25, v[dartx.get](4));
      expect$.Expect.equals(36, v[dartx.get](5));
      function isOdd(element) {
        return dart.equals(dart.dsend(element, '%', 2), 1);
      }
      dart.fn(isOdd, dynamicTobool());
      expect$.Expect.equals(true, param2_test.Param2Test.exists(JSArrayOfint().of([3, 5, 7, 11, 13]), isOdd));
      expect$.Expect.equals(false, param2_test.Param2Test.exists(JSArrayOfint().of([2, 4, 10]), isOdd));
      expect$.Expect.equals(false, param2_test.Param2Test.exists(JSArrayOfint().of([]), isOdd));
      v = JSArrayOfint().of([4, 5, 7]);
      expect$.Expect.equals(true, param2_test.Param2Test.exists(v, dart.fn(e => dart.equals(dart.dsend(e, '%', 2), 1), dynamicTobool())));
      expect$.Expect.equals(false, param2_test.Param2Test.exists(v, dart.fn(e => dart.equals(e, 6), dynamicTobool())));
      let isZero = dart.fn(e => dart.equals(e, 0), dynamicTobool());
      expect$.Expect.equals(false, param2_test.Param2Test.exists(v, isZero));
    }
  };
  dart.setSignature(param2_test.Param2Test, {
    statics: () => ({
      forEach: dart.definiteFunctionType(dart.dynamic, [core.List$(core.int), dart.functionType(core.int, [dart.dynamic])]),
      apply: dart.definiteFunctionType(core.int, [dart.functionType(dart.dynamic, [core.int]), core.int]),
      exists: dart.definiteFunctionType(dart.dynamic, [core.List$(core.int), dart.functionType(dart.dynamic, [dart.dynamic])]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['forEach', 'apply', 'exists', 'testMain']
  });
  param2_test.main = function() {
    param2_test.Param2Test.testMain();
  };
  dart.fn(param2_test.main, VoidTodynamic());
  // Exports:
  exports.param2_test = param2_test;
});

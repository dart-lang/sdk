dart_library.library('corelib/regress_11099_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_11099_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_11099_test = Object.create(null);
  let JSArrayOfMyTest = () => (JSArrayOfMyTest = dart.constFn(_interceptors.JSArray$(regress_11099_test.MyTest)))();
  let ComparableOfMyTest = () => (ComparableOfMyTest = dart.constFn(core.Comparable$(regress_11099_test.MyTest)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_11099_test.main = function() {
    let l = JSArrayOfMyTest().of([new regress_11099_test.MyTest(1), new regress_11099_test.MyTest(5), new regress_11099_test.MyTest(3)]);
    l[dartx.sort]();
    if (dart.toString(l) != "[d{1}, d{3}, d{5}]") dart.throw('Wrong result!');
  };
  dart.fn(regress_11099_test.main, VoidTovoid());
  regress_11099_test.MyTest = class MyTest extends core.Object {
    new(a) {
      this.a = a;
    }
    compareTo(b) {
      return dart.notNull(this.a) - dart.notNull(b.a);
    }
    toString() {
      return dart.str`d{${this.a}}`;
    }
  };
  regress_11099_test.MyTest[dart.implements] = () => [ComparableOfMyTest()];
  dart.setSignature(regress_11099_test.MyTest, {
    constructors: () => ({new: dart.definiteFunctionType(regress_11099_test.MyTest, [core.int])}),
    methods: () => ({compareTo: dart.definiteFunctionType(core.int, [regress_11099_test.MyTest])})
  });
  dart.defineExtensionMembers(regress_11099_test.MyTest, ['compareTo']);
  // Exports:
  exports.regress_11099_test = regress_11099_test;
});

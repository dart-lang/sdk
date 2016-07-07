dart_library.library('language/issue9687_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue9687_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue9687_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(issue9687_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue9687_test.A = class A extends core.Object {
    new() {
      this.finalField = 42;
      this.otherFinalField = 54;
    }
    expectFinalField(arg1, arg2) {
      expect$.Expect.equals(arg1, arg2);
      expect$.Expect.equals(this.finalField, arg1);
    }
    expectOtherFinalField(_, arg1, arg2) {
      expect$.Expect.equals(arg1, arg2);
      expect$.Expect.equals(this.otherFinalField, arg1);
    }
  };
  dart.setSignature(issue9687_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(issue9687_test.A, [])}),
    methods: () => ({
      expectFinalField: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]),
      expectOtherFinalField: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])
    })
  });
  dart.defineLazy(issue9687_test, {
    get array() {
      return JSArrayOfA().of([new issue9687_test.A()]);
    },
    set array(_) {}
  });
  issue9687_test.main = function() {
    let untypedReceiver = issue9687_test.array[dartx.get](0);
    let typedReceiver = new issue9687_test.A();
    let a = untypedReceiver.expectFinalField(typedReceiver.finalField, typedReceiver.finalField);
    let b = core.int._check(a);
    untypedReceiver.expectOtherFinalField(b, typedReceiver.otherFinalField, typedReceiver.otherFinalField);
  };
  dart.fn(issue9687_test.main, VoidTodynamic());
  // Exports:
  exports.issue9687_test = issue9687_test;
});

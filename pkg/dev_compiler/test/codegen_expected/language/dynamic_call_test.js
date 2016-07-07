dart_library.library('language/dynamic_call_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dynamic_call_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dynamic_call_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dynamic_call_test.Helper = class Helper extends core.Object {
    new() {
    }
    foo(i) {
      return i;
    }
  };
  dart.setSignature(dynamic_call_test.Helper, {
    constructors: () => ({new: dart.definiteFunctionType(dynamic_call_test.Helper, [])}),
    methods: () => ({foo: dart.definiteFunctionType(core.int, [core.int])})
  });
  dynamic_call_test.DynamicCallTest = class DynamicCallTest extends core.Object {
    static testMain() {
      let obj = new dynamic_call_test.Helper();
      expect$.Expect.equals(1, obj.foo(1));
    }
  };
  dart.setSignature(dynamic_call_test.DynamicCallTest, {
    statics: () => ({testMain: dart.definiteFunctionType(core.int, [])}),
    names: ['testMain']
  });
  dynamic_call_test.main = function() {
    dynamic_call_test.DynamicCallTest.testMain();
  };
  dart.fn(dynamic_call_test.main, VoidTodynamic());
  // Exports:
  exports.dynamic_call_test = dynamic_call_test;
});

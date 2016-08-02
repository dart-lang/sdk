dart_library.library('language/function_propagation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_propagation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_propagation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_propagation_test.A = dart.callableClass(function A(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A extends core.Object {
    call(str) {
      return 499;
    }
  });
  dart.setSignature(function_propagation_test.A, {
    methods: () => ({call: dart.definiteFunctionType(core.int, [core.String])})
  });
  function_propagation_test.F = dart.typedef('F', () => dart.functionType(core.int, [core.String]));
  function_propagation_test.main = function() {
    let a = new function_propagation_test.A();
    if (core.Function.is(a)) {
      expect$.Expect.isTrue(function_propagation_test.A.is(a));
    } else {
      expect$.Expect.fail("a should be a Function");
    }
    let a2 = new function_propagation_test.A();
    if (function_propagation_test.F.is(a2)) {
      expect$.Expect.isTrue(function_propagation_test.A.is(a2));
    } else {
      expect$.Expect.fail("a2 should be an F");
    }
    let a3 = new function_propagation_test.A();
    expect$.Expect.isTrue(function_propagation_test.A.is(a3));
    let a4 = new function_propagation_test.A();
    expect$.Expect.isTrue(function_propagation_test.A.is(a4));
  };
  dart.fn(function_propagation_test.main, VoidTodynamic());
  // Exports:
  exports.function_propagation_test = function_propagation_test;
});

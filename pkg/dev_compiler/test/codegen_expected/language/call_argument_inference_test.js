dart_library.library('language/call_argument_inference_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_argument_inference_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_argument_inference_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_argument_inference_test.A = dart.callableClass(function A(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A extends core.Object {
    call(a) {
      return typeof a == 'number';
    }
  });
  dart.setSignature(call_argument_inference_test.A, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  call_argument_inference_test.main = function() {
    expect$.Expect.isTrue(new call_argument_inference_test.A().call(42));
    expect$.Expect.isFalse(dart.dcall(new call_argument_inference_test.A(), 'foo'));
  };
  dart.fn(call_argument_inference_test.main, VoidTodynamic());
  // Exports:
  exports.call_argument_inference_test = call_argument_inference_test;
});

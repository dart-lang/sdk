dart_library.library('language/call_this_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_this_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_this_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_this_test.A = dart.callableClass(function A(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A extends core.Object {
    call() {
      return 42;
    }
    test1() {
      return this();
    }
    test2() {
      return this();
    }
  });
  dart.setSignature(call_this_test.A, {
    methods: () => ({
      call: dart.definiteFunctionType(dart.dynamic, []),
      test1: dart.definiteFunctionType(dart.dynamic, []),
      test2: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  call_this_test.main = function() {
    expect$.Expect.equals(42, new call_this_test.A().test1());
    expect$.Expect.equals(42, new call_this_test.A().test2());
  };
  dart.fn(call_this_test.main, VoidTodynamic());
  // Exports:
  exports.call_this_test = call_this_test;
});

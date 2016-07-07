dart_library.library('language/call_function_apply_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_function_apply_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_function_apply_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_function_apply_test.A = dart.callableClass(function A(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A extends core.Object {
    call(opts) {
      let a = opts && 'a' in opts ? opts.a : 42;
      return 499 + dart.notNull(core.num._check(a));
    }
  });
  dart.setSignature(call_function_apply_test.A, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic})})
  });
  let const$;
  call_function_apply_test.main = function() {
    expect$.Expect.equals(497, core.Function.apply(new call_function_apply_test.A(), [], dart.map([const$ || (const$ = dart.const(core.Symbol.new('a'))), -2])));
  };
  dart.fn(call_function_apply_test.main, VoidTodynamic());
  // Exports:
  exports.call_function_apply_test = call_function_apply_test;
});

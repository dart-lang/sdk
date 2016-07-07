dart_library.library('language/const_global_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_global_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_global_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_global_test.a = 1;
  let const$;
  let const$0;
  let const$1;
  const_global_test.main = function() {
    expect$.Expect.equals(1, const_global_test.a);
    expect$.Expect.equals(1, (const$ || (const$ = dart.const(new const_global_test.A(const_global_test.a)))).a);
    expect$.Expect.equals(1, (const$1 || (const$1 = dart.constList([const$0 || (const$0 = dart.const(new const_global_test.A(const_global_test.a)))], const_global_test.A)))[dartx.get](0).a);
  };
  dart.fn(const_global_test.main, VoidTodynamic());
  const_global_test.A = class A extends core.Object {
    new(a) {
      this.a = a;
    }
  };
  dart.setSignature(const_global_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(const_global_test.A, [dart.dynamic])})
  });
  // Exports:
  exports.const_global_test = const_global_test;
});

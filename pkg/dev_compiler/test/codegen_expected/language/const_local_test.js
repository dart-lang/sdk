dart_library.library('language/const_local_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_local_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_local_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  let const$1;
  const_local_test.main = function() {
    let a = 1;
    expect$.Expect.equals(1, a);
    expect$.Expect.equals(1, (const$ || (const$ = dart.const(new const_local_test.A(a)))).a);
    expect$.Expect.equals(1, (const$1 || (const$1 = dart.constList([const$0 || (const$0 = dart.const(new const_local_test.A(a)))], const_local_test.A)))[dartx.get](0).a);
  };
  dart.fn(const_local_test.main, VoidTodynamic());
  const_local_test.A = class A extends core.Object {
    new(a) {
      this.a = a;
    }
  };
  dart.setSignature(const_local_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(const_local_test.A, [dart.dynamic])})
  });
  // Exports:
  exports.const_local_test = const_local_test;
});

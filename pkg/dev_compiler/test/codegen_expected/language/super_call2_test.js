dart_library.library('language/super_call2_test', null, /* Imports */[
  'dart_sdk'
], function load__super_call2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const super_call2_test = Object.create(null);
  let C = () => (C = dart.constFn(super_call2_test.C$()))();
  let D = () => (D = dart.constFn(super_call2_test.D$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_call2_test.C$ = dart.generic(T => {
    class C extends core.Object {
      foo(a) {
        T._check(a);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [T])})
    });
    return C;
  });
  super_call2_test.C = C();
  super_call2_test.D$ = dart.generic(T => {
    class D extends super_call2_test.C$(T) {
      foo(a) {
        T._check(a);
        super.foo(a);
      }
    }
    dart.setSignature(D, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [T])})
    });
    return D;
  });
  super_call2_test.D = D();
  super_call2_test.main = function() {
    let d = new super_call2_test.D();
    d.foo(null);
  };
  dart.fn(super_call2_test.main, VoidTodynamic());
  // Exports:
  exports.super_call2_test = super_call2_test;
});

dart_library.library('language/regress_18865_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_18865_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_18865_test = Object.create(null);
  let B = () => (B = dart.constFn(regress_18865_test.B$()))();
  let A = () => (A = dart.constFn(regress_18865_test.A$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_18865_test.B$ = dart.generic(T => {
    class B extends core.Object {}
    dart.addTypeTests(B);
    return B;
  });
  regress_18865_test.B = B();
  regress_18865_test.A$ = dart.generic(T => {
    class A extends regress_18865_test.B {
      static foo() {
        return new regress_18865_test.A();
      }
    }
    dart.setSignature(A, {
      statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
      names: ['foo']
    });
    return A;
  });
  regress_18865_test.A = A();
  regress_18865_test.main = function() {
    regress_18865_test.A.foo();
  };
  dart.fn(regress_18865_test.main, VoidTodynamic());
  // Exports:
  exports.regress_18865_test = regress_18865_test;
});

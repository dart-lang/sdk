dart_library.library('language/generic_instanceof5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_instanceof5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_instanceof5_test = Object.create(null);
  let B = () => (B = dart.constFn(generic_instanceof5_test.B$()))();
  let C = () => (C = dart.constFn(generic_instanceof5_test.C$()))();
  let D = () => (D = dart.constFn(generic_instanceof5_test.D$()))();
  let COfbool$int = () => (COfbool$int = dart.constFn(generic_instanceof5_test.C$(core.bool, core.int)))();
  let BOfint$bool = () => (BOfint$bool = dart.constFn(generic_instanceof5_test.B$(core.int, core.bool)))();
  let DOfBOfint$bool = () => (DOfBOfint$bool = dart.constFn(generic_instanceof5_test.D$(BOfint$bool())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_instanceof5_test.A = class A extends core.Object {};
  generic_instanceof5_test.B$ = dart.generic((T, S) => {
    class B extends core.Object {}
    dart.addTypeTests(B);
    return B;
  });
  generic_instanceof5_test.B = B();
  generic_instanceof5_test.C$ = dart.generic((U, V) => {
    class C extends dart.mixin(generic_instanceof5_test.A, generic_instanceof5_test.B$(V, U)) {}
    dart.addTypeTests(C);
    return C;
  });
  generic_instanceof5_test.C = C();
  generic_instanceof5_test.D$ = dart.generic(T => {
    class D extends core.Object {
      foo(x) {
        if (new core.DateTime.now().millisecondsSinceEpoch == 42) this.foo(x);
        return T.is(x);
        return true;
      }
    }
    dart.addTypeTests(D);
    dart.setSignature(D, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return D;
  });
  generic_instanceof5_test.D = D();
  generic_instanceof5_test.main = function() {
    expect$.Expect.isTrue(new (DOfBOfint$bool())().foo(new (COfbool$int())()));
  };
  dart.fn(generic_instanceof5_test.main, VoidTodynamic());
  // Exports:
  exports.generic_instanceof5_test = generic_instanceof5_test;
});

dart_library.library('language/mixin_type_parameter6_test', null, /* Imports */[
  'dart_sdk'
], function load__mixin_type_parameter6_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_type_parameter6_test = Object.create(null);
  let A = () => (A = dart.constFn(mixin_type_parameter6_test.A$()))();
  let B = () => (B = dart.constFn(mixin_type_parameter6_test.B$()))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_type_parameter6_test.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  mixin_type_parameter6_test.A = A();
  mixin_type_parameter6_test.B$ = dart.generic(S => {
    class B extends core.Object {
      foo(s) {
        S._check(s);
        return null;
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      methods: () => ({foo: dart.definiteFunctionType(core.int, [S])})
    });
    return B;
  });
  mixin_type_parameter6_test.B = B();
  mixin_type_parameter6_test.C = class C extends dart.mixin(mixin_type_parameter6_test.A$(core.int), mixin_type_parameter6_test.B$(core.String)) {};
  dart.addSimpleTypeTests(mixin_type_parameter6_test.C);
  mixin_type_parameter6_test.main = function() {
    let list = JSArrayOfString().of(['foo']);
    let c = new mixin_type_parameter6_test.C();
    list[dartx.map](core.int)(dart.bind(c, 'foo'));
  };
  dart.fn(mixin_type_parameter6_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_type_parameter6_test = mixin_type_parameter6_test;
});

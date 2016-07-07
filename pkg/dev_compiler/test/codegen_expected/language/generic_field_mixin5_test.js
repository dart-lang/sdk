dart_library.library('language/generic_field_mixin5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_field_mixin5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_field_mixin5_test = Object.create(null);
  let M = () => (M = dart.constFn(generic_field_mixin5_test.M$()))();
  let A = () => (A = dart.constFn(generic_field_mixin5_test.A$()))();
  let C1 = () => (C1 = dart.constFn(generic_field_mixin5_test.C1$()))();
  let C1Ofint = () => (C1Ofint = dart.constFn(generic_field_mixin5_test.C1$(core.int)))();
  let C1OfString = () => (C1OfString = dart.constFn(generic_field_mixin5_test.C1$(core.String)))();
  let VoidToType = () => (VoidToType = dart.constFn(dart.definiteFunctionType(core.Type, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_field_mixin5_test.M$ = dart.generic(T => {
    class M extends core.Object {
      new() {
        this.field = dart.fn(() => dart.wrapType(T), VoidToType())();
      }
    }
    dart.addTypeTests(M);
    return M;
  });
  generic_field_mixin5_test.M = M();
  generic_field_mixin5_test.A$ = dart.generic(U => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  generic_field_mixin5_test.A = A();
  generic_field_mixin5_test.C1$ = dart.generic(V => {
    class C1 extends dart.mixin(core.Object, generic_field_mixin5_test.M$(V)) {}
    return C1;
  });
  generic_field_mixin5_test.C1 = C1();
  generic_field_mixin5_test.C2 = class C2 extends dart.mixin(core.Object, generic_field_mixin5_test.M$(core.int)) {};
  generic_field_mixin5_test.C3 = class C3 extends dart.mixin(core.Object, generic_field_mixin5_test.M$(core.String)) {};
  generic_field_mixin5_test.main = function() {
    expect$.Expect.equals(dart.wrapType(core.int), new (C1Ofint())().field);
    expect$.Expect.equals(dart.wrapType(core.String), new (C1OfString())().field);
    expect$.Expect.equals(dart.wrapType(core.int), new generic_field_mixin5_test.C2().field);
    expect$.Expect.equals(dart.wrapType(core.String), new generic_field_mixin5_test.C3().field);
  };
  dart.fn(generic_field_mixin5_test.main, VoidTodynamic());
  // Exports:
  exports.generic_field_mixin5_test = generic_field_mixin5_test;
});

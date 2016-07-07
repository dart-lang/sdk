dart_library.library('language/runtime_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__runtime_type_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const runtime_type_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  runtime_type_test.A = class A extends core.Object {};
  runtime_type_test.B = class B extends core.Object {};
  runtime_type_test.main = function() {
    let a = new runtime_type_test.A();
    let b = new runtime_type_test.B();
    let f = dart.fn(() => null, VoidTodynamic());
    let funcType = dart.runtimeType(f);
    let classA = dart.wrapType(runtime_type_test.A);
    let classB = dart.wrapType(runtime_type_test.B);
    expect$.Expect.isTrue(core.Type.is(a.runtimeType));
    expect$.Expect.equals(dart.wrapType(runtime_type_test.A), a.runtimeType);
    expect$.Expect.notEquals(dart.wrapType(runtime_type_test.B), a.runtimeType);
    expect$.Expect.notEquals(dart.wrapType(runtime_type_test.A), b.runtimeType);
    expect$.Expect.isTrue(core.Type.is(dart.runtimeType(f)));
    expect$.Expect.isFalse(dart.equals(dart.runtimeType(f), a.runtimeType));
    expect$.Expect.isTrue(core.Type.is(classA.runtimeType));
    expect$.Expect.isTrue(dart.equals(classA.runtimeType, classB.runtimeType));
    expect$.Expect.isFalse(dart.equals(classA.runtimeType, a.runtimeType));
    expect$.Expect.isFalse(dart.equals(classA.runtimeType, dart.runtimeType(f)));
    expect$.Expect.isTrue(dart.equals(dart.runtimeType(funcType), classA.runtimeType));
    expect$.Expect.isTrue(core.Type.is(dart.runtimeType(null)));
    expect$.Expect.equals(dart.wrapType(core.Null), dart.runtimeType(null));
  };
  dart.fn(runtime_type_test.main, VoidTodynamic());
  // Exports:
  exports.runtime_type_test = runtime_type_test;
});

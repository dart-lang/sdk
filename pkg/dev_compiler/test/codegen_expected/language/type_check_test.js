dart_library.library('language/type_check_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_check_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_check_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(type_check_test.A)))();
  let VoidToB = () => (VoidToB = dart.constFn(dart.definiteFunctionType(type_check_test.B, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_check_test.A = class A extends core.Object {};
  type_check_test.B = class B extends type_check_test.A {};
  type_check_test.main = function() {
    let a = JSArrayOfA().of([new type_check_test.A(), new type_check_test.B()]);
    let b = a[dartx.get](0);
    b = b;
    expect$.Expect.throws(dart.fn(() => type_check_test.B.as(b), VoidToB()), dart.fn(e => core.CastError.is(e), dynamicTobool()));
  };
  dart.fn(type_check_test.main, VoidTodynamic());
  // Exports:
  exports.type_check_test = type_check_test;
});

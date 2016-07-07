dart_library.library('language/is_interfaces_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__is_interfaces_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const is_interfaces_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(is_interfaces_test.A)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  is_interfaces_test.A = class A extends core.Object {};
  is_interfaces_test.B = class B extends is_interfaces_test.A {};
  is_interfaces_test.C = class C extends core.Object {};
  is_interfaces_test.C[dart.implements] = () => [is_interfaces_test.B];
  is_interfaces_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(is_interfaces_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(is_interfaces_test.inscrutable, intToint());
  is_interfaces_test.main = function() {
    let things = JSArrayOfA().of([new is_interfaces_test.A(), new is_interfaces_test.B(), new is_interfaces_test.C()]);
    let a = things[dartx.get](is_interfaces_test.inscrutable(0));
    expect$.Expect.isTrue(is_interfaces_test.A.is(a));
    expect$.Expect.isFalse(is_interfaces_test.B.is(a));
    expect$.Expect.isFalse(is_interfaces_test.C.is(a));
    let b = things[dartx.get](is_interfaces_test.inscrutable(1));
    expect$.Expect.isTrue(is_interfaces_test.A.is(b));
    expect$.Expect.isTrue(is_interfaces_test.B.is(b));
    expect$.Expect.isFalse(is_interfaces_test.C.is(b));
    let c = things[dartx.get](is_interfaces_test.inscrutable(2));
    expect$.Expect.isTrue(is_interfaces_test.A.is(c));
    expect$.Expect.isTrue(is_interfaces_test.B.is(c));
    expect$.Expect.isTrue(is_interfaces_test.C.is(c));
  };
  dart.fn(is_interfaces_test.main, VoidTodynamic());
  // Exports:
  exports.is_interfaces_test = is_interfaces_test;
});

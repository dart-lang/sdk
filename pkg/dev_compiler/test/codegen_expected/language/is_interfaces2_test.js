dart_library.library('language/is_interfaces2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__is_interfaces2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const is_interfaces2_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(is_interfaces2_test.A)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  is_interfaces2_test.A = class A extends core.Object {};
  is_interfaces2_test.B = class B extends is_interfaces2_test.A {};
  is_interfaces2_test.C = class C extends is_interfaces2_test.B {};
  is_interfaces2_test.D = class D extends core.Object {};
  is_interfaces2_test.D[dart.implements] = () => [is_interfaces2_test.C];
  is_interfaces2_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(is_interfaces2_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(is_interfaces2_test.inscrutable, intToint());
  is_interfaces2_test.main = function() {
    let things = JSArrayOfA().of([new is_interfaces2_test.A(), new is_interfaces2_test.B(), new is_interfaces2_test.C(), new is_interfaces2_test.D()]);
    let a = things[dartx.get](is_interfaces2_test.inscrutable(0));
    expect$.Expect.isTrue(is_interfaces2_test.A.is(a));
    expect$.Expect.isFalse(is_interfaces2_test.B.is(a));
    expect$.Expect.isFalse(is_interfaces2_test.C.is(a));
    expect$.Expect.isFalse(is_interfaces2_test.D.is(a));
    let b = things[dartx.get](is_interfaces2_test.inscrutable(1));
    expect$.Expect.isTrue(is_interfaces2_test.A.is(b));
    expect$.Expect.isTrue(is_interfaces2_test.B.is(b));
    expect$.Expect.isFalse(is_interfaces2_test.C.is(b));
    expect$.Expect.isFalse(is_interfaces2_test.D.is(b));
    let c = things[dartx.get](is_interfaces2_test.inscrutable(2));
    expect$.Expect.isTrue(is_interfaces2_test.A.is(c));
    expect$.Expect.isTrue(is_interfaces2_test.B.is(c));
    expect$.Expect.isTrue(is_interfaces2_test.C.is(c));
    expect$.Expect.isFalse(is_interfaces2_test.D.is(c));
    let d = things[dartx.get](is_interfaces2_test.inscrutable(3));
    expect$.Expect.isTrue(is_interfaces2_test.A.is(d));
    expect$.Expect.isTrue(is_interfaces2_test.B.is(d));
    expect$.Expect.isTrue(is_interfaces2_test.C.is(d));
    expect$.Expect.isTrue(is_interfaces2_test.D.is(d));
  };
  dart.fn(is_interfaces2_test.main, VoidTodynamic());
  // Exports:
  exports.is_interfaces2_test = is_interfaces2_test;
});

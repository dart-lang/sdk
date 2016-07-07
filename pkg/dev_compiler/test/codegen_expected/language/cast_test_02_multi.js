dart_library.library('language/cast_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cast_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cast_test_02_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidToObject = () => (VoidToObject = dart.constFn(dart.definiteFunctionType(core.Object, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cast_test_02_multi.C = class C extends core.Object {
    new() {
      this.foo = 42;
    }
  };
  cast_test_02_multi.D = class D extends cast_test_02_multi.C {
    new() {
      this.bar = 37;
      super.new();
    }
  };
  cast_test_02_multi.createC = function() {
    return new cast_test_02_multi.C();
  };
  dart.fn(cast_test_02_multi.createC, VoidToObject());
  cast_test_02_multi.createD = function() {
    return new cast_test_02_multi.D();
  };
  dart.fn(cast_test_02_multi.createD, VoidToObject());
  cast_test_02_multi.getNull = function() {
    return null;
  };
  dart.fn(cast_test_02_multi.getNull, VoidToObject());
  cast_test_02_multi.createList = function() {
    return JSArrayOfint().of([2]);
  };
  dart.fn(cast_test_02_multi.createList, VoidToObject());
  cast_test_02_multi.createInt = function() {
    return 87;
  };
  dart.fn(cast_test_02_multi.createInt, VoidToObject());
  cast_test_02_multi.createString = function() {
    return "a string";
  };
  dart.fn(cast_test_02_multi.createString, VoidToObject());
  cast_test_02_multi.main = function() {
    let oc = cast_test_02_multi.createC();
    let od = cast_test_02_multi.createD();
    let on = cast_test_02_multi.getNull();
    let ol = cast_test_02_multi.createList();
    let oi = cast_test_02_multi.createInt();
    let os = cast_test_02_multi.createString();
    expect$.Expect.equals(42, cast_test_02_multi.C.as(oc).foo);
    expect$.Expect.equals(42, cast_test_02_multi.C.as(od).foo);
    expect$.Expect.equals(42, cast_test_02_multi.D.as(od).foo);
    expect$.Expect.equals(37, cast_test_02_multi.D.as(od).bar);
    expect$.Expect.equals(37, cast_test_02_multi.D.as(cast_test_02_multi.C.as(od)).bar);
    dart.toString(cast_test_02_multi.D.as(on));
    cast_test_02_multi.D.as(on).foo;
    dart.toString(on);
    dart.toString(oc);
    dart.toString(od);
    dart.toString(on);
    dart.dload(oc, 'foo');
    dart.dload(od, 'foo');
    dart.dload(od, 'bar');
    let c = cast_test_02_multi.C.as(oc);
    c = cast_test_02_multi.C.as(od);
    c = cast_test_02_multi.C._check(oc);
    let d = cast_test_02_multi.D.as(od);
    d = cast_test_02_multi.D._check(od);
    core.List.as(ol)[dartx.get](0);
    ListOfint().as(ol)[dartx.get](0);
    dart.dindex(ol, 0);
    let x = ListOfint().as(ol)[dartx.get](0);
    ListOfint().as(ol)[dartx.set](0, core.int.as(oi));
    core.String.as(os)[dartx.length];
    dart.dload(os, 'length');
    dart.notNull(core.int.as(oi)) + 2;
  };
  dart.fn(cast_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.cast_test_02_multi = cast_test_02_multi;
});

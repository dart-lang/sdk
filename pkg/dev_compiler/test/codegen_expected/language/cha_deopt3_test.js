dart_library.library('language/cha_deopt3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cha_deopt3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cha_deopt3_test = Object.create(null);
  const cha_deopt3_lib = Object.create(null);
  const cha_deopt3_deferred_lib = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cha_deopt3_test.loaded = false;
  cha_deopt3_test.main = function() {
    for (let i = 0; i < 2000; i++)
      cha_deopt3_test.bla();
    expect$.Expect.equals(1, cha_deopt3_test.bla());
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      cha_deopt3_test.loaded = true;
      expect$.Expect.equals(1, cha_deopt3_test.bla());
    }, dynamicTodynamic()));
  };
  dart.fn(cha_deopt3_test.main, VoidTodynamic());
  cha_deopt3_test.make_array = function() {
    try {
      if (dart.test(cha_deopt3_test.loaded)) {
        return [new cha_deopt3_lib.A(), new cha_deopt3_lib.B(), new cha_deopt3_lib.C(), new cha_deopt3_lib.D(), new cha_deopt3_lib.E(), cha_deopt3_deferred_lib.make_u()];
      } else {
        return JSArrayOfObject().of([new cha_deopt3_lib.A(), new cha_deopt3_lib.B(), new cha_deopt3_lib.C(), new cha_deopt3_lib.D(), new cha_deopt3_lib.E(), new cha_deopt3_lib.T()]);
      }
    } catch (e) {
    }

  };
  dart.fn(cha_deopt3_test.make_array, VoidTodynamic());
  cha_deopt3_test.bla = function() {
    let count = 0;
    for (let x of core.Iterable._check(cha_deopt3_test.make_array())) {
      if (cha_deopt3_lib.T.is(x)) count++;
    }
    return count;
  };
  dart.fn(cha_deopt3_test.bla, VoidTodynamic());
  cha_deopt3_lib.A = class A extends core.Object {};
  cha_deopt3_lib.B = class B extends core.Object {};
  cha_deopt3_lib.C = class C extends core.Object {};
  cha_deopt3_lib.D = class D extends core.Object {};
  cha_deopt3_lib.E = class E extends core.Object {};
  cha_deopt3_lib.T = class T extends core.Object {};
  cha_deopt3_deferred_lib.U = class U extends core.Object {};
  cha_deopt3_deferred_lib.U[dart.implements] = () => [cha_deopt3_lib.T];
  cha_deopt3_deferred_lib.make_u = function() {
    return new cha_deopt3_deferred_lib.U();
  };
  dart.fn(cha_deopt3_deferred_lib.make_u, VoidTodynamic());
  // Exports:
  exports.cha_deopt3_test = cha_deopt3_test;
  exports.cha_deopt3_lib = cha_deopt3_lib;
  exports.cha_deopt3_deferred_lib = cha_deopt3_deferred_lib;
});

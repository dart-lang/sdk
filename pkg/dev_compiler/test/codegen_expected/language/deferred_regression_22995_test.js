dart_library.library('language/deferred_regression_22995_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_regression_22995_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_regression_22995_test = Object.create(null);
  const deferred_regression_22995_lib = Object.create(null);
  let Tg = () => (Tg = dart.constFn(deferred_regression_22995_test.Tg$()))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_regression_22995_test.A = class A extends core.Object {};
  deferred_regression_22995_test.B = class B extends core.Object {};
  deferred_regression_22995_test.C = class C extends core.Object {};
  deferred_regression_22995_test.Ti = dart.typedef('Ti', () => dart.functionType(dart.dynamic, [core.int]));
  deferred_regression_22995_test.TB = dart.typedef('TB', () => dart.functionType(dart.dynamic, [deferred_regression_22995_test.B]));
  deferred_regression_22995_test.TTi = dart.typedef('TTi', () => dart.functionType(dart.dynamic, [deferred_regression_22995_test.Ti]));
  deferred_regression_22995_test.Tg$ = dart.generic(T => {
    const Tg = dart.typedef('Tg', () => dart.functionType(dart.dynamic, [T]));
    return Tg;
  });
  deferred_regression_22995_test.Tg = Tg();
  deferred_regression_22995_test.T = class T extends core.Object {
    fA(a) {
      return null;
    }
    fTB(a) {
      return null;
    }
    fTgC(a) {
      return null;
    }
  };
  dart.setSignature(deferred_regression_22995_test.T, {
    methods: () => ({
      fA: dart.definiteFunctionType(dart.dynamic, [deferred_regression_22995_test.A]),
      fTB: dart.definiteFunctionType(dart.dynamic, [deferred_regression_22995_test.TB]),
      fTgC: dart.definiteFunctionType(dart.dynamic, [deferred_regression_22995_test.Tg$(deferred_regression_22995_test.C)])
    })
  });
  deferred_regression_22995_test.main = function() {
    expect$.Expect.isFalse(deferred_regression_22995_test.Ti.is(dart.bind(new deferred_regression_22995_test.T(), 'fA')));
    expect$.Expect.isFalse(deferred_regression_22995_test.TTi.is(dart.bind(new deferred_regression_22995_test.T(), 'fTB')));
    expect$.Expect.isFalse(deferred_regression_22995_test.TTi.is(dart.bind(new deferred_regression_22995_test.T(), 'fTgC')));
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      deferred_regression_22995_lib.foofoo();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_regression_22995_test.main, VoidTodynamic());
  deferred_regression_22995_lib.foofoo = function() {
    new deferred_regression_22995_test.A();
    new deferred_regression_22995_test.B();
    new deferred_regression_22995_test.C();
  };
  dart.fn(deferred_regression_22995_lib.foofoo, VoidTodynamic());
  // Exports:
  exports.deferred_regression_22995_test = deferred_regression_22995_test;
  exports.deferred_regression_22995_lib = deferred_regression_22995_lib;
});

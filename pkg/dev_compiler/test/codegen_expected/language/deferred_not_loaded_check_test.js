dart_library.library('language/deferred_not_loaded_check_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_not_loaded_check_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_not_loaded_check_test = Object.create(null);
  const deferred_not_loaded_check_lib = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  deferred_not_loaded_check_test.c = null;
  deferred_not_loaded_check_test.expectNoSideEffect = function(test) {
    deferred_not_loaded_check_test.c = 0;
    dart.dcall(test);
    expect$.Expect.isTrue(dart.equals(deferred_not_loaded_check_test.c, 0));
  };
  dart.fn(deferred_not_loaded_check_test.expectNoSideEffect, dynamicTodynamic());
  deferred_not_loaded_check_test.expectThrowsNotLoaded = function(test) {
    expect$.Expect.throws(VoidTovoid()._check(test), dart.fn(e => core.Error.is(e), dynamicTobool()));
  };
  dart.fn(deferred_not_loaded_check_test.expectThrowsNotLoaded, dynamicTodynamic());
  deferred_not_loaded_check_test.sideEffect = function() {
    deferred_not_loaded_check_test.c = 1;
    return 10;
  };
  dart.fn(deferred_not_loaded_check_test.sideEffect, VoidToint());
  deferred_not_loaded_check_test.main = function() {
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        deferred_not_loaded_check_lib.foo(deferred_not_loaded_check_test.sideEffect());
      }, VoidTodynamic()));
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        deferred_not_loaded_check_lib.C.foo(deferred_not_loaded_check_test.sideEffect());
      }, VoidTodynamic()));
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        new deferred_not_loaded_check_lib.C(deferred_not_loaded_check_test.sideEffect());
      }, VoidTodynamic()));
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
      deferred_not_loaded_check_lib.a;
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        deferred_not_loaded_check_lib.a = deferred_not_loaded_check_test.sideEffect();
      }, VoidTodynamic()));
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
      deferred_not_loaded_check_lib.getter;
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        deferred_not_loaded_check_lib.setter = deferred_not_loaded_check_test.sideEffect();
      }, VoidTodynamic()));
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        deferred_not_loaded_check_lib.list[dartx.set](deferred_not_loaded_check_test.sideEffect(), deferred_not_loaded_check_test.sideEffect());
      }, VoidTodynamic()));
    }, VoidTodynamic()));
    deferred_not_loaded_check_test.expectNoSideEffect(dart.fn(() => {
      deferred_not_loaded_check_test.expectThrowsNotLoaded(dart.fn(() => {
        deferred_not_loaded_check_lib.closure(deferred_not_loaded_check_test.sideEffect());
      }, VoidTodynamic()));
    }, VoidTodynamic()));
  };
  dart.fn(deferred_not_loaded_check_test.main, VoidTovoid$());
  deferred_not_loaded_check_lib.foo = function(arg) {
  };
  dart.fn(deferred_not_loaded_check_lib.foo, intTodynamic());
  deferred_not_loaded_check_lib.C = class C extends core.Object {
    new(arg) {
    }
    static foo(arg) {}
  };
  dart.setSignature(deferred_not_loaded_check_lib.C, {
    constructors: () => ({new: dart.definiteFunctionType(deferred_not_loaded_check_lib.C, [core.int])}),
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [core.int])}),
    names: ['foo']
  });
  deferred_not_loaded_check_lib.a = null;
  dart.copyProperties(deferred_not_loaded_check_lib, {
    get getter() {
      return 42;
    }
  });
  dart.copyProperties(deferred_not_loaded_check_lib, {
    set setter(arg) {
      deferred_not_loaded_check_lib.a = 10;
    }
  });
  dart.defineLazy(deferred_not_loaded_check_lib, {
    get list() {
      return core.List.new();
    },
    set list(_) {}
  });
  dart.defineLazy(deferred_not_loaded_check_lib, {
    get closure() {
      return dart.fn(arg => 3, intToint());
    },
    set closure(_) {}
  });
  // Exports:
  exports.deferred_not_loaded_check_test = deferred_not_loaded_check_test;
  exports.deferred_not_loaded_check_lib = deferred_not_loaded_check_lib;
});

dart_library.library('language/deferred_redirecting_factory_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__deferred_redirecting_factory_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const deferred_redirecting_factory_test = Object.create(null);
  const deferred_redirecting_factory_lib1 = Object.create(null);
  const deferred_redirecting_factory_lib2 = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  deferred_redirecting_factory_test.C = class C extends core.Object {
    get foo() {
      return "main";
    }
    new() {
    }
    static a() {
      return new deferred_redirecting_factory_lib1.C();
    }
    static b() {
      return deferred_redirecting_factory_lib1.C.a();
    }
  };
  dart.setSignature(deferred_redirecting_factory_test.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(deferred_redirecting_factory_test.C, []),
      a: dart.definiteFunctionType(deferred_redirecting_factory_test.C, []),
      b: dart.definiteFunctionType(deferred_redirecting_factory_test.C, [])
    })
  });
  deferred_redirecting_factory_test.test1 = function() {
    return dart.async(function*() {
      expect$.Expect.throws(dart.fn(() => {
        deferred_redirecting_factory_test.C.a();
      }, VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => {
        deferred_redirecting_factory_test.C.b();
      }, VoidTovoid()));
    }, dart.dynamic);
  };
  dart.fn(deferred_redirecting_factory_test.test1, VoidTodynamic());
  deferred_redirecting_factory_test.test2 = function() {
    return dart.async(function*() {
      yield loadLibrary();
      expect$.Expect.equals("lib1", deferred_redirecting_factory_test.C.a().foo);
      expect$.Expect.throws(dart.fn(() => {
        deferred_redirecting_factory_test.C.b();
      }, VoidTovoid()));
    }, dart.dynamic);
  };
  dart.fn(deferred_redirecting_factory_test.test2, VoidTodynamic());
  deferred_redirecting_factory_test.test3 = function() {
    return dart.async(function*() {
      yield loadLibrary();
      yield deferred_redirecting_factory_lib1.loadLib2();
      expect$.Expect.equals("lib1", deferred_redirecting_factory_test.C.a().foo);
      expect$.Expect.equals("lib2", deferred_redirecting_factory_test.C.b().foo);
    }, dart.dynamic);
  };
  dart.fn(deferred_redirecting_factory_test.test3, VoidTodynamic());
  deferred_redirecting_factory_test.test = function() {
    return dart.async(function*() {
      yield deferred_redirecting_factory_test.test1();
      yield deferred_redirecting_factory_test.test2();
      yield deferred_redirecting_factory_test.test3();
    }, dart.dynamic);
  };
  dart.fn(deferred_redirecting_factory_test.test, VoidTodynamic());
  deferred_redirecting_factory_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(deferred_redirecting_factory_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(deferred_redirecting_factory_test.main, VoidTovoid());
  deferred_redirecting_factory_lib1.loadLib2 = function() {
    return loadLibrary();
  };
  dart.fn(deferred_redirecting_factory_lib1.loadLib2, VoidTodynamic());
  deferred_redirecting_factory_lib1.C = class C extends deferred_redirecting_factory_test.C {
    get foo() {
      return "lib1";
    }
    new() {
      super.new();
    }
    static a() {
      return new deferred_redirecting_factory_lib2.C();
    }
  };
  dart.setSignature(deferred_redirecting_factory_lib1.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(deferred_redirecting_factory_lib1.C, []),
      a: dart.definiteFunctionType(deferred_redirecting_factory_lib1.C, [])
    })
  });
  deferred_redirecting_factory_lib2.C = class C extends deferred_redirecting_factory_lib1.C {
    new() {
      super.new();
    }
    get foo() {
      return "lib2";
    }
  };
  // Exports:
  exports.deferred_redirecting_factory_test = deferred_redirecting_factory_test;
  exports.deferred_redirecting_factory_lib1 = deferred_redirecting_factory_lib1;
  exports.deferred_redirecting_factory_lib2 = deferred_redirecting_factory_lib2;
});

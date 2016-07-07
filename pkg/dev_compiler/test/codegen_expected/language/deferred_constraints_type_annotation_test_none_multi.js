dart_library.library('language/deferred_constraints_type_annotation_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'async_helper'
], function load__deferred_constraints_type_annotation_test_none_multi(exports, dart_sdk, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const deferred_constraints_type_annotation_test_none_multi = Object.create(null);
  const deferred_constraints_lib = Object.create(null);
  let G2 = () => (G2 = dart.constFn(deferred_constraints_type_annotation_test_none_multi.G2$()))();
  let G = () => (G = dart.constFn(deferred_constraints_lib.G$()))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_constraints_type_annotation_test_none_multi.F = class F extends core.Object {};
  deferred_constraints_type_annotation_test_none_multi.G2$ = dart.generic(T => {
    class G2 extends core.Object {}
    dart.addTypeTests(G2);
    return G2;
  });
  deferred_constraints_type_annotation_test_none_multi.G2 = G2();
  deferred_constraints_type_annotation_test_none_multi.main = function() {
    async_helper$.asyncStart();
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      let instance = deferred_constraints_lib.constantInstance;
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_constraints_type_annotation_test_none_multi.main, VoidTodynamic());
  deferred_constraints_lib.C = class C extends core.Object {
    static staticMethod() {
      return 42;
    }
  };
  dart.setSignature(deferred_constraints_lib.C, {
    statics: () => ({staticMethod: dart.definiteFunctionType(core.int, [])}),
    names: ['staticMethod']
  });
  deferred_constraints_lib.G$ = dart.generic(T => {
    class G extends core.Object {}
    dart.addTypeTests(G);
    return G;
  });
  deferred_constraints_lib.G = G();
  deferred_constraints_lib.Const = class Const extends core.Object {
    new() {
    }
    otherConstructor() {
    }
  };
  dart.defineNamedConstructor(deferred_constraints_lib.Const, 'otherConstructor');
  dart.setSignature(deferred_constraints_lib.Const, {
    constructors: () => ({
      new: dart.definiteFunctionType(deferred_constraints_lib.Const, []),
      otherConstructor: dart.definiteFunctionType(deferred_constraints_lib.Const, [])
    })
  });
  dart.defineLazy(deferred_constraints_lib.Const, {
    get instance() {
      return dart.const(new deferred_constraints_lib.Const());
    }
  });
  deferred_constraints_lib.constantInstance = dart.const(new deferred_constraints_lib.Const());
  // Exports:
  exports.deferred_constraints_type_annotation_test_none_multi = deferred_constraints_type_annotation_test_none_multi;
  exports.deferred_constraints_lib = deferred_constraints_lib;
});

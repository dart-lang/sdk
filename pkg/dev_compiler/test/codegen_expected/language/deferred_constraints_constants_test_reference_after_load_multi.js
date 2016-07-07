dart_library.library('language/deferred_constraints_constants_test_reference_after_load_multi', null, /* Imports */[
  'dart_sdk',
  'async_helper'
], function load__deferred_constraints_constants_test_reference_after_load_multi(exports, dart_sdk, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const deferred_constraints_constants_test_reference_after_load_multi = Object.create(null);
  const deferred_constraints_constants_lib = Object.create(null);
  let G = () => (G = dart.constFn(deferred_constraints_constants_lib.G$()))();
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: dart.dynamic})))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  deferred_constraints_constants_test_reference_after_load_multi.myConst1 = 499;
  deferred_constraints_constants_test_reference_after_load_multi.myConst2 = 499;
  deferred_constraints_constants_test_reference_after_load_multi.f1 = function(opts) {
    let a = opts && 'a' in opts ? opts.a : 499;
  };
  dart.fn(deferred_constraints_constants_test_reference_after_load_multi.f1, __Tovoid());
  deferred_constraints_constants_test_reference_after_load_multi.f2 = function(opts) {
    let a = opts && 'a' in opts ? opts.a : 499;
  };
  dart.fn(deferred_constraints_constants_test_reference_after_load_multi.f2, __Tovoid());
  deferred_constraints_constants_test_reference_after_load_multi.H1 = class H1 extends core.Object {};
  deferred_constraints_constants_test_reference_after_load_multi.H2 = class H2 extends core.Object {};
  deferred_constraints_constants_test_reference_after_load_multi.H3 = class H3 extends core.Object {};
  deferred_constraints_constants_test_reference_after_load_multi.main = function() {
    let a1 = deferred_constraints_constants_test_reference_after_load_multi.myConst1;
    let a2 = deferred_constraints_constants_test_reference_after_load_multi.myConst2;
    async_helper$.asyncStart();
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      let instance = deferred_constraints_constants_lib.constantInstance;
      deferred_constraints_constants_test_reference_after_load_multi.f1();
      deferred_constraints_constants_test_reference_after_load_multi.f2();
      let constInstance = deferred_constraints_constants_lib.constantInstance;
      let h1 = new deferred_constraints_constants_test_reference_after_load_multi.H1();
      let h2 = new deferred_constraints_constants_test_reference_after_load_multi.H2();
      let h3 = new deferred_constraints_constants_test_reference_after_load_multi.H3();
      mirrors.reflectClass(dart.wrapType(deferred_constraints_constants_test_reference_after_load_multi.H1)).metadata;
      mirrors.reflectClass(dart.wrapType(deferred_constraints_constants_test_reference_after_load_multi.H2)).metadata;
      mirrors.reflectClass(dart.wrapType(deferred_constraints_constants_test_reference_after_load_multi.H3)).metadata;
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_constraints_constants_test_reference_after_load_multi.main, VoidTovoid());
  deferred_constraints_constants_lib.C = class C extends core.Object {
    static staticMethod() {
      return 42;
    }
  };
  dart.setSignature(deferred_constraints_constants_lib.C, {
    statics: () => ({staticMethod: dart.definiteFunctionType(core.int, [])}),
    names: ['staticMethod']
  });
  deferred_constraints_constants_lib.G$ = dart.generic(T => {
    class G extends core.Object {}
    dart.addTypeTests(G);
    return G;
  });
  deferred_constraints_constants_lib.G = G();
  deferred_constraints_constants_lib.Const = class Const extends core.Object {
    new() {
    }
    namedConstructor() {
    }
  };
  dart.defineNamedConstructor(deferred_constraints_constants_lib.Const, 'namedConstructor');
  dart.setSignature(deferred_constraints_constants_lib.Const, {
    constructors: () => ({
      new: dart.definiteFunctionType(deferred_constraints_constants_lib.Const, []),
      namedConstructor: dart.definiteFunctionType(deferred_constraints_constants_lib.Const, [])
    })
  });
  dart.defineLazy(deferred_constraints_constants_lib.Const, {
    get instance() {
      return dart.const(new deferred_constraints_constants_lib.Const());
    }
  });
  deferred_constraints_constants_lib.constantInstance = dart.const(new deferred_constraints_constants_lib.Const());
  // Exports:
  exports.deferred_constraints_constants_test_reference_after_load_multi = deferred_constraints_constants_test_reference_after_load_multi;
  exports.deferred_constraints_constants_lib = deferred_constraints_constants_lib;
});

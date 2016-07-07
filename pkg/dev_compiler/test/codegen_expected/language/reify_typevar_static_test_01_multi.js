dart_library.library('language/reify_typevar_static_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reify_typevar_static_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reify_typevar_static_test_01_multi = Object.create(null);
  let C = () => (C = dart.constFn(reify_typevar_static_test_01_multi.C$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reify_typevar_static_test_01_multi.C$ = dart.generic(T => {
    let COfT = () => (COfT = dart.constFn(reify_typevar_static_test_01_multi.C$(T)))();
    class C extends core.Object {
      new(x) {
        if (x === void 0) x = null;
        this.x = x;
      }
      static staticFunction(b) {
        return null;
      }
      static factoryConstructor(b) {
        return new (COfT())(dart.test(b) ? dart.wrapType(T) : null);
      }
      redirectingConstructor(b) {
        C.prototype.new.call(this, null);
      }
      ordinaryConstructor(b) {
        this.x = null;
      }
    }
    dart.addTypeTests(C);
    dart.defineNamedConstructor(C, 'redirectingConstructor');
    dart.defineNamedConstructor(C, 'ordinaryConstructor');
    dart.setSignature(C, {
      constructors: () => ({
        new: dart.definiteFunctionType(reify_typevar_static_test_01_multi.C$(T), [], [dart.dynamic]),
        factoryConstructor: dart.definiteFunctionType(reify_typevar_static_test_01_multi.C$(T), [core.bool]),
        redirectingConstructor: dart.definiteFunctionType(reify_typevar_static_test_01_multi.C$(T), [core.bool]),
        ordinaryConstructor: dart.definiteFunctionType(reify_typevar_static_test_01_multi.C$(T), [core.bool])
      }),
      statics: () => ({staticFunction: dart.definiteFunctionType(dart.dynamic, [core.bool])}),
      names: ['staticFunction']
    });
    return C;
  });
  reify_typevar_static_test_01_multi.C = C();
  reify_typevar_static_test_01_multi.main = function() {
    expect$.Expect.equals(null, reify_typevar_static_test_01_multi.C.staticFunction(false));
    expect$.Expect.equals(null, reify_typevar_static_test_01_multi.C.factoryConstructor(false).x);
    expect$.Expect.equals(null, new reify_typevar_static_test_01_multi.C.redirectingConstructor(false).x);
    expect$.Expect.equals(null, new reify_typevar_static_test_01_multi.C.ordinaryConstructor(false).x);
  };
  dart.fn(reify_typevar_static_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.reify_typevar_static_test_01_multi = reify_typevar_static_test_01_multi;
});

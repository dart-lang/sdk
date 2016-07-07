dart_library.library('language/deferred_load_constants_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__deferred_load_constants_test_none_multi(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const deferred_load_constants_test_none_multi = Object.create(null);
  const deferred_load_constants = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.functionType(core.int, [core.int])))();
  let VoidToC = () => (VoidToC = dart.constFn(dart.definiteFunctionType(deferred_load_constants.C, [])))();
  let VoidToType = () => (VoidToType = dart.constFn(dart.definiteFunctionType(core.Type, [])))();
  let VoidToFn = () => (VoidToFn = dart.constFn(dart.definiteFunctionType(intToint(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intToint$ = () => (intToint$ = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  deferred_load_constants_test_none_multi.main = function() {
    async_helper$.asyncStart();
    expect$.Expect.throws(dart.fn(() => deferred_load_constants.c, VoidToC()));
    expect$.Expect.throws(dart.fn(() => dart.wrapType(deferred_load_constants.C), VoidToType()));
    expect$.Expect.throws(dart.fn(() => dart.wrapType(deferred_load_constants.funtype), VoidToType()));
    expect$.Expect.throws(dart.fn(() => deferred_load_constants.toplevel, VoidToFn()));
    loadLibrary().whenComplete(dart.fn(() => {
      expect$.Expect.identical(deferred_load_constants.c, deferred_load_constants.c);
      expect$.Expect.identical(dart.wrapType(deferred_load_constants.C), dart.wrapType(deferred_load_constants.C));
      expect$.Expect.identical(dart.wrapType(deferred_load_constants.funtype), dart.wrapType(deferred_load_constants.funtype));
      expect$.Expect.identical(deferred_load_constants.toplevel, deferred_load_constants.toplevel);
      expect$.Expect.identical(deferred_load_constants.C.staticfun, deferred_load_constants.C.staticfun);
      async_helper$.asyncEnd();
    }, VoidTodynamic()));
  };
  dart.fn(deferred_load_constants_test_none_multi.main, VoidTodynamic());
  deferred_load_constants.C = class C extends core.Object {
    new() {
    }
    static staticfun(x) {
      return x;
    }
  };
  dart.setSignature(deferred_load_constants.C, {
    constructors: () => ({new: dart.definiteFunctionType(deferred_load_constants.C, [])}),
    statics: () => ({staticfun: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['staticfun']
  });
  deferred_load_constants.c = dart.const(new deferred_load_constants.C());
  deferred_load_constants.funtype = dart.typedef('funtype', () => dart.functionType(core.int, [core.int]));
  deferred_load_constants.toplevel = function(x) {
    return x;
  };
  dart.fn(deferred_load_constants.toplevel, intToint$());
  // Exports:
  exports.deferred_load_constants_test_none_multi = deferred_load_constants_test_none_multi;
  exports.deferred_load_constants = deferred_load_constants;
});

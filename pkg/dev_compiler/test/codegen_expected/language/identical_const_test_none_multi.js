dart_library.library('language/identical_const_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__identical_const_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const identical_const_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  identical_const_test_none_multi.f = function() {
  };
  dart.fn(identical_const_test_none_multi.f, VoidTodynamic());
  identical_const_test_none_multi.g = 1;
  identical_const_test_none_multi.identical_ff = core.identical(identical_const_test_none_multi.f, identical_const_test_none_multi.f);
  identical_const_test_none_multi.identical_fg = core.identical(identical_const_test_none_multi.f, identical_const_test_none_multi.g);
  identical_const_test_none_multi.identical_gf = core.identical(identical_const_test_none_multi.g, identical_const_test_none_multi.f);
  identical_const_test_none_multi.identical_gg = core.identical(identical_const_test_none_multi.g, identical_const_test_none_multi.g);
  identical_const_test_none_multi.a = dart.const(dart.map([true, 0]));
  identical_const_test_none_multi.b = dart.const(dart.map([false, 0]));
  identical_const_test_none_multi.use = function(x) {
    return x;
  };
  dart.fn(identical_const_test_none_multi.use, dynamicTodynamic());
  identical_const_test_none_multi.main = function() {
    identical_const_test_none_multi.use(identical_const_test_none_multi.a);
    identical_const_test_none_multi.use(identical_const_test_none_multi.b);
  };
  dart.fn(identical_const_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.identical_const_test_none_multi = identical_const_test_none_multi;
});

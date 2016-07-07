dart_library.library('language/deferred_load_library_wrong_args_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__deferred_load_library_wrong_args_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const deferred_load_library_wrong_args_test_01_multi = Object.create(null);
  const deferred_load_library_wrong_args_lib = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_load_library_wrong_args_test_01_multi.main = function() {
    loadLibrary(10);
  };
  dart.fn(deferred_load_library_wrong_args_test_01_multi.main, VoidTovoid());
  deferred_load_library_wrong_args_lib.foo = function() {
    return 42;
  };
  dart.fn(deferred_load_library_wrong_args_lib.foo, VoidTodynamic());
  // Exports:
  exports.deferred_load_library_wrong_args_test_01_multi = deferred_load_library_wrong_args_test_01_multi;
  exports.deferred_load_library_wrong_args_lib = deferred_load_library_wrong_args_lib;
});

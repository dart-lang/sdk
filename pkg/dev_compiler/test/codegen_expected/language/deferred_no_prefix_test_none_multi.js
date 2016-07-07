dart_library.library('language/deferred_no_prefix_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__deferred_no_prefix_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const deferred_no_prefix_test_none_multi = Object.create(null);
  const deferred_constraints_lib2 = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_no_prefix_test_none_multi.main = function() {
  };
  dart.fn(deferred_no_prefix_test_none_multi.main, VoidTovoid());
  deferred_constraints_lib2.foo = function() {
    return 42;
  };
  dart.fn(deferred_constraints_lib2.foo, VoidTodynamic());
  deferred_constraints_lib2.C = class C extends core.Object {};
  // Exports:
  exports.deferred_no_prefix_test_none_multi = deferred_no_prefix_test_none_multi;
  exports.deferred_constraints_lib2 = deferred_constraints_lib2;
});

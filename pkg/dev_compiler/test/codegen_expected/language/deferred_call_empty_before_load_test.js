dart_library.library('language/deferred_call_empty_before_load_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_call_empty_before_load_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_call_empty_before_load_test = Object.create(null);
  const deferred_call_empty_before_load_lib = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_call_empty_before_load_test.main = function() {
    expect$.Expect.throws(dart.fn(() => deferred_call_empty_before_load_lib.thefun(), VoidTovoid()));
  };
  dart.fn(deferred_call_empty_before_load_test.main, VoidTodynamic());
  deferred_call_empty_before_load_lib.thefun = function() {
  };
  dart.fn(deferred_call_empty_before_load_lib.thefun, VoidTodynamic());
  // Exports:
  exports.deferred_call_empty_before_load_test = deferred_call_empty_before_load_test;
  exports.deferred_call_empty_before_load_lib = deferred_call_empty_before_load_lib;
});

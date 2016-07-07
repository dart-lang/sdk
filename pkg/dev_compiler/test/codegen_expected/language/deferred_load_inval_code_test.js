dart_library.library('language/deferred_load_inval_code_test', null, /* Imports */[
  'dart_sdk'
], function load__deferred_load_inval_code_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const deferred_load_inval_code_test = Object.create(null);
  const deferred_load_inval_code_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  deferred_load_inval_code_test.loaded = false;
  deferred_load_inval_code_test.x = 0;
  deferred_load_inval_code_test.bla = function() {
    if (dart.test(deferred_load_inval_code_test.loaded)) {
      deferred_load_inval_code_lib.foo();
    } else {
      for (let i = 0; i < 100; i++) {
        deferred_load_inval_code_test.x = dart.notNull(deferred_load_inval_code_test.x) + 1;
      }
    }
  };
  dart.fn(deferred_load_inval_code_test.bla, VoidTodynamic());
  deferred_load_inval_code_test.warmup = function() {
    for (let i = 1; i < 1000; i++) {
      deferred_load_inval_code_test.bla();
    }
  };
  dart.fn(deferred_load_inval_code_test.warmup, VoidTodynamic());
  deferred_load_inval_code_test.main = function() {
    deferred_load_inval_code_test.warmup();
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      deferred_load_inval_code_test.loaded = true;
      deferred_load_inval_code_test.bla();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_load_inval_code_test.main, VoidTodynamic());
  deferred_load_inval_code_lib.foo = function() {
    return "foo from library";
  };
  dart.fn(deferred_load_inval_code_lib.foo, VoidTodynamic());
  // Exports:
  exports.deferred_load_inval_code_test = deferred_load_inval_code_test;
  exports.deferred_load_inval_code_lib = deferred_load_inval_code_lib;
});

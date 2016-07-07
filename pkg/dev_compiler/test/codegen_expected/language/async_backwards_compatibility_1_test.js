dart_library.library('language/async_backwards_compatibility_1_test', null, /* Imports */[
  'dart_sdk'
], function load__async_backwards_compatibility_1_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_backwards_compatibility_1_test = Object.create(null);
  const async_helper_lib = Object.create(null);
  let VoidToasync = () => (VoidToasync = dart.constFn(dart.definiteFunctionType(async_helper_lib.async, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_backwards_compatibility_1_test.A = class A extends core.Object {
    get async() {
      return null;
    }
  };
  async_backwards_compatibility_1_test.topLevel = function() {
    return null;
  };
  dart.lazyFn(async_backwards_compatibility_1_test.topLevel, () => VoidToasync());
  async_backwards_compatibility_1_test.main = function() {
    let a = new async_backwards_compatibility_1_test.A();
    let b = a.async;
    let c = async_backwards_compatibility_1_test.topLevel();
  };
  dart.fn(async_backwards_compatibility_1_test.main, VoidTodynamic());
  async_helper_lib.async = class async extends core.Object {};
  // Exports:
  exports.async_backwards_compatibility_1_test = async_backwards_compatibility_1_test;
  exports.async_helper_lib = async_helper_lib;
});

dart_library.library('language/async_backwards_compatibility_2_test', null, /* Imports */[
  'dart_sdk'
], function load__async_backwards_compatibility_2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_backwards_compatibility_2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(async_backwards_compatibility_2_test, {
    get async() {
      return 1;
    }
  });
  async_backwards_compatibility_2_test.A = class A extends core.Object {
    async() {
      return null;
    }
  };
  dart.setSignature(async_backwards_compatibility_2_test.A, {
    methods: () => ({async: dart.definiteFunctionType(dart.dynamic, [])})
  });
  async_backwards_compatibility_2_test.main = function() {
    let a = async_backwards_compatibility_2_test.async;
    let b = new async_backwards_compatibility_2_test.A();
    let c = b.async();
  };
  dart.fn(async_backwards_compatibility_2_test.main, VoidTodynamic());
  // Exports:
  exports.async_backwards_compatibility_2_test = async_backwards_compatibility_2_test;
});

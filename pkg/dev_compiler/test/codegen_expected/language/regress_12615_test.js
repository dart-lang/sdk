dart_library.library('language/regress_12615_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_12615_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_12615_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_12615_test.main = function() {
    function test() {
      function f() {
        try {
        } catch (e) {
        }

      }
      dart.fn(f, VoidTodynamic());
      try {
      } catch (e) {
      }

    }
    dart.fn(test, VoidTovoid());
    test();
  };
  dart.fn(regress_12615_test.main, VoidTodynamic());
  // Exports:
  exports.regress_12615_test = regress_12615_test;
});

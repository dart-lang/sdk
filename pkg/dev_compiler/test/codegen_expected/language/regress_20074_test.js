dart_library.library('language/regress_20074_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_20074_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_20074_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_20074_test.doit = function() {
    function error(error) {
      core.print(error);
    }
    dart.fn(error, dynamicTodynamic());
    error('foobar');
  };
  dart.fn(regress_20074_test.doit, VoidTodynamic());
  regress_20074_test.main = function() {
    regress_20074_test.doit();
  };
  dart.fn(regress_20074_test.main, VoidTodynamic());
  // Exports:
  exports.regress_20074_test = regress_20074_test;
});

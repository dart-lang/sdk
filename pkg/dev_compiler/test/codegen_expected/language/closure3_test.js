dart_library.library('language/closure3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  closure3_test.test = function(x, y) {
    dart.fn(() => {
      dart.dsend(x, '-', y);
    }, VoidTodynamic())();
  };
  dart.fn(closure3_test.test, dynamicAnddynamicTodynamic());
  closure3_test.main = function() {
    expect$.Expect.throws(dart.fn(() => {
      closure3_test.test(null, 2);
    }, VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(closure3_test.main, VoidTodynamic());
  // Exports:
  exports.closure3_test = closure3_test;
});

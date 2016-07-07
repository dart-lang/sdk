dart_library.library('language/closure_self_reference_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_self_reference_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_self_reference_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_self_reference_test.main = function() {
    let counter = 0;
    function inner(value) {
      if (dart.equals(value, 0)) return 0;
      try {
        return inner(dart.dsend(value, '-', 1));
      } finally {
        counter++;
      }
    }
    dart.fn(inner, dynamicTodynamic());
    expect$.Expect.equals(0, inner(199));
    expect$.Expect.equals(199, counter);
  };
  dart.fn(closure_self_reference_test.main, VoidTodynamic());
  // Exports:
  exports.closure_self_reference_test = closure_self_reference_test;
});

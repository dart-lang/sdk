dart_library.library('language/inline_closure_with_constant_arguments_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inline_closure_with_constant_arguments_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inline_closure_with_constant_arguments_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let boolTodynamic = () => (boolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inline_closure_with_constant_arguments_test.primeForSmis = function(b) {
    function smi_op(a, b) {
      return dart.dsend(a, '+', b);
    }
    dart.fn(smi_op, dynamicAnddynamicTodynamic());
    if (dart.test(b)) {
      return smi_op(1, 2);
    } else {
      return smi_op(true, false);
    }
  };
  dart.fn(inline_closure_with_constant_arguments_test.primeForSmis, boolTodynamic());
  inline_closure_with_constant_arguments_test.main = function() {
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(3, inline_closure_with_constant_arguments_test.primeForSmis(true));
    }
  };
  dart.fn(inline_closure_with_constant_arguments_test.main, VoidTodynamic());
  // Exports:
  exports.inline_closure_with_constant_arguments_test = inline_closure_with_constant_arguments_test;
});

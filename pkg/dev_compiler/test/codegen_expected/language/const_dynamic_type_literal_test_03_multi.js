dart_library.library('language/const_dynamic_type_literal_test_03_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_dynamic_type_literal_test_03_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_dynamic_type_literal_test_03_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const_dynamic_type_literal_test_03_multi.d = dart.wrapType(dart.dynamic);
  const_dynamic_type_literal_test_03_multi.i = dart.wrapType(core.int);
  let const$;
  const_dynamic_type_literal_test_03_multi.main = function() {
    expect$.Expect.equals(2, (const$ || (const$ = dart.const(dart.map([const_dynamic_type_literal_test_03_multi.d, 1, const_dynamic_type_literal_test_03_multi.i, 2]))))[dartx.length]);
  };
  dart.fn(const_dynamic_type_literal_test_03_multi.main, VoidTovoid());
  // Exports:
  exports.const_dynamic_type_literal_test_03_multi = const_dynamic_type_literal_test_03_multi;
});

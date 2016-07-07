dart_library.library('language/const_dynamic_type_literal_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_dynamic_type_literal_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_dynamic_type_literal_test_01_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const_dynamic_type_literal_test_01_multi.d = dart.wrapType(dart.dynamic);
  const_dynamic_type_literal_test_01_multi.i = dart.wrapType(core.int);
  const_dynamic_type_literal_test_01_multi.main = function() {
    expect$.Expect.isTrue(core.identical(const_dynamic_type_literal_test_01_multi.d, dart.wrapType(dart.dynamic)));
  };
  dart.fn(const_dynamic_type_literal_test_01_multi.main, VoidTovoid());
  // Exports:
  exports.const_dynamic_type_literal_test_01_multi = const_dynamic_type_literal_test_01_multi;
});

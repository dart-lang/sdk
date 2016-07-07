dart_library.library('language/dynamic_prefix_core_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dynamic_prefix_core_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dynamic_prefix_core_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dynamic_prefix_core_test_none_multi.main = function() {
    expect$.Expect.isTrue(core.Type.is(dart.wrapType(dart.dynamic)));
  };
  dart.fn(dynamic_prefix_core_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.dynamic_prefix_core_test_none_multi = dynamic_prefix_core_test_none_multi;
});

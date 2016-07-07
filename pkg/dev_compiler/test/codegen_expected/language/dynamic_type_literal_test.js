dart_library.library('language/dynamic_type_literal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dynamic_type_literal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dynamic_type_literal_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dynamic_type_literal_test.main = function() {
    expect$.Expect.isTrue(core.Type.is(dart.wrapType(dart.dynamic)));
    expect$.Expect.isFalse(dart.equals(dart.wrapType(dart.dynamic), dart.wrapType(core.Type)));
  };
  dart.fn(dynamic_type_literal_test.main, VoidTovoid());
  // Exports:
  exports.dynamic_type_literal_test = dynamic_type_literal_test;
});

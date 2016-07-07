dart_library.library('language/call_type_literal_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__call_type_literal_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const call_type_literal_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  call_type_literal_test_none_multi.C = class C extends core.Object {
    a() {}
  };
  dart.setSignature(call_type_literal_test_none_multi.C, {
    methods: () => ({a: dart.definiteFunctionType(dart.void, [])})
  });
  call_type_literal_test_none_multi.main = function() {
  };
  dart.fn(call_type_literal_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.call_type_literal_test_none_multi = call_type_literal_test_none_multi;
});

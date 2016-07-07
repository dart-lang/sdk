dart_library.library('language/unsupported_operators_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__unsupported_operators_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unsupported_operators_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  unsupported_operators_test_none_multi.C = class C extends core.Object {
    m() {
      core.print(null);
      core.print(null);
    }
  };
  dart.setSignature(unsupported_operators_test_none_multi.C, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
  });
  unsupported_operators_test_none_multi.main = function() {
    new unsupported_operators_test_none_multi.C().m();
    new unsupported_operators_test_none_multi.C().m();
    core.print(null);
    core.print(null);
  };
  dart.fn(unsupported_operators_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.unsupported_operators_test_none_multi = unsupported_operators_test_none_multi;
});

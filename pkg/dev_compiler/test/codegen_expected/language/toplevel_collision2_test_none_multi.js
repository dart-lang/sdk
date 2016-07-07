dart_library.library('language/toplevel_collision2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__toplevel_collision2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const toplevel_collision2_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dart.copyProperties(toplevel_collision2_test_none_multi, {
    get x() {
      return 200;
    },
    set x(i) {
      core.print(i);
    }
  });
  toplevel_collision2_test_none_multi.main = function() {
  };
  dart.fn(toplevel_collision2_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.toplevel_collision2_test_none_multi = toplevel_collision2_test_none_multi;
});

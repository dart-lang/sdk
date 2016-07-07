dart_library.library('language/setter_no_getter_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__setter_no_getter_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const setter_no_getter_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(setter_no_getter_test_none_multi, {
    get topLevel() {
      return 42;
    },
    set topLevel(value) {}
  });
  setter_no_getter_test_none_multi.main = function() {
  };
  dart.fn(setter_no_getter_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_no_getter_test_none_multi = setter_no_getter_test_none_multi;
});

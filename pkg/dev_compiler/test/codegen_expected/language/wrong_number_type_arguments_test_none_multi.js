dart_library.library('language/wrong_number_type_arguments_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__wrong_number_type_arguments_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const wrong_number_type_arguments_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  wrong_number_type_arguments_test_none_multi.foo = null;
  wrong_number_type_arguments_test_none_multi.baz = null;
  wrong_number_type_arguments_test_none_multi.main = function() {
    wrong_number_type_arguments_test_none_multi.foo = null;
    let bar = core.Map.new();
  };
  dart.fn(wrong_number_type_arguments_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.wrong_number_type_arguments_test_none_multi = wrong_number_type_arguments_test_none_multi;
});

dart_library.library('language/function_type_alias7_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__function_type_alias7_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const function_type_alias7_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias7_test_none_multi.funcType = dart.typedef('funcType', () => dart.functionType(dart.void, [], [core.int]));
  function_type_alias7_test_none_multi.A = class A extends core.Object {};
  function_type_alias7_test_none_multi.main = function() {
    new function_type_alias7_test_none_multi.A();
  };
  dart.fn(function_type_alias7_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.function_type_alias7_test_none_multi = function_type_alias7_test_none_multi;
});

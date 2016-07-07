dart_library.library('language/function_type_alias9_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__function_type_alias9_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const function_type_alias9_test_none_multi = Object.create(null);
  let GToF = () => (GToF = dart.constFn(dart.definiteFunctionType(function_type_alias9_test_none_multi.F, [function_type_alias9_test_none_multi.G])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias9_test_none_multi.F = dart.typedef('F', () => dart.functionType(dart.void, [core.List]));
  function_type_alias9_test_none_multi.G = dart.typedef('G', () => dart.functionType(dart.void, [core.List$(function_type_alias9_test_none_multi.F)]));
  function_type_alias9_test_none_multi.main = function() {
    function foo(g) {
      return function_type_alias9_test_none_multi.F._check(g);
    }
    dart.fn(foo, GToF());
    foo(null);
  };
  dart.fn(function_type_alias9_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.function_type_alias9_test_none_multi = function_type_alias9_test_none_multi;
});

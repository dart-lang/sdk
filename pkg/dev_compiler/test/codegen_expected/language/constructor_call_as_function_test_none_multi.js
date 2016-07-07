dart_library.library('language/constructor_call_as_function_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor_call_as_function_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor_call_as_function_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_call_as_function_test_none_multi.Point = class Point extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
  };
  dart.setSignature(constructor_call_as_function_test_none_multi.Point, {
    constructors: () => ({new: dart.definiteFunctionType(constructor_call_as_function_test_none_multi.Point, [core.int, core.int])})
  });
  constructor_call_as_function_test_none_multi.main = function() {
  };
  dart.fn(constructor_call_as_function_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_call_as_function_test_none_multi = constructor_call_as_function_test_none_multi;
});

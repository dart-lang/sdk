dart_library.library('lib/typed_data/native_interceptor_no_own_method_to_intercept_test', null, /* Imports */[
  'dart_sdk'
], function load__native_interceptor_no_own_method_to_intercept_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const native_interceptor_no_own_method_to_intercept_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  native_interceptor_no_own_method_to_intercept_test.use = function(s) {
    return s;
  };
  dart.fn(native_interceptor_no_own_method_to_intercept_test.use, dynamicTodynamic());
  native_interceptor_no_own_method_to_intercept_test.main = function() {
    native_interceptor_no_own_method_to_intercept_test.use(dart.toString(typed_data.ByteData.new(1)));
  };
  dart.fn(native_interceptor_no_own_method_to_intercept_test.main, VoidTodynamic());
  // Exports:
  exports.native_interceptor_no_own_method_to_intercept_test = native_interceptor_no_own_method_to_intercept_test;
});

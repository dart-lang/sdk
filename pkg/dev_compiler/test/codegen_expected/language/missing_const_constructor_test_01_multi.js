dart_library.library('language/missing_const_constructor_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__missing_const_constructor_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const missing_const_constructor_test_01_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  missing_const_constructor_test_01_multi.GoodClass = class GoodClass extends core.Object {
    new() {
    }
  };
  dart.setSignature(missing_const_constructor_test_01_multi.GoodClass, {
    constructors: () => ({new: dart.definiteFunctionType(missing_const_constructor_test_01_multi.GoodClass, [])})
  });
  missing_const_constructor_test_01_multi.GOOD_CLASS = dart.const(new missing_const_constructor_test_01_multi.GoodClass());
  missing_const_constructor_test_01_multi.main = function() {
    try {
      core.print(missing_const_constructor_test_01_multi.GOOD_CLASS);
    } catch (e) {
    }

  };
  dart.fn(missing_const_constructor_test_01_multi.main, VoidTovoid());
  // Exports:
  exports.missing_const_constructor_test_01_multi = missing_const_constructor_test_01_multi;
});

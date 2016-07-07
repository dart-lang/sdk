dart_library.library('language/missing_const_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__missing_const_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const missing_const_constructor_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  missing_const_constructor_test_none_multi.GoodClass = class GoodClass extends core.Object {
    new() {
    }
  };
  dart.setSignature(missing_const_constructor_test_none_multi.GoodClass, {
    constructors: () => ({new: dart.definiteFunctionType(missing_const_constructor_test_none_multi.GoodClass, [])})
  });
  missing_const_constructor_test_none_multi.GOOD_CLASS = null;
  missing_const_constructor_test_none_multi.main = function() {
    try {
      core.print(missing_const_constructor_test_none_multi.GOOD_CLASS);
    } catch (e) {
    }

  };
  dart.fn(missing_const_constructor_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.missing_const_constructor_test_none_multi = missing_const_constructor_test_none_multi;
});

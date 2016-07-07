dart_library.library('language/duplicate_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__duplicate_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const duplicate_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  duplicate_constructor_test_none_multi.Foo = class Foo extends core.Object {
    new() {
    }
  };
  dart.setSignature(duplicate_constructor_test_none_multi.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(duplicate_constructor_test_none_multi.Foo, [])})
  });
  duplicate_constructor_test_none_multi.main = function() {
    new duplicate_constructor_test_none_multi.Foo();
  };
  dart.fn(duplicate_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.duplicate_constructor_test_none_multi = duplicate_constructor_test_none_multi;
});

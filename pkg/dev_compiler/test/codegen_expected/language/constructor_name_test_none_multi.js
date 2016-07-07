dart_library.library('language/constructor_name_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor_name_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor_name_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  constructor_name_test_none_multi.Foo = class Foo extends core.Object {};
  constructor_name_test_none_multi.main = function() {
    new constructor_name_test_none_multi.Foo();
  };
  dart.fn(constructor_name_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.constructor_name_test_none_multi = constructor_name_test_none_multi;
});

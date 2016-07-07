dart_library.library('language/static_field3_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__static_field3_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const static_field3_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_field3_test_none_multi.Foo = class Foo extends core.Object {
    new() {
      this.x = null;
    }
    m() {}
  };
  dart.setSignature(static_field3_test_none_multi.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(static_field3_test_none_multi.Foo, [])}),
    methods: () => ({m: dart.definiteFunctionType(dart.void, [])})
  });
  static_field3_test_none_multi.main = function() {
    if (false) {
    }
  };
  dart.fn(static_field3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.static_field3_test_none_multi = static_field3_test_none_multi;
});

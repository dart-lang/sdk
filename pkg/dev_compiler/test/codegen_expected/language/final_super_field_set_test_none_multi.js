dart_library.library('language/final_super_field_set_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__final_super_field_set_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const final_super_field_set_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  final_super_field_set_test_none_multi.SuperClass = class SuperClass extends core.Object {
    new() {
      this.field = 0;
    }
    noSuchMethod(_) {
      return 42;
    }
  };
  final_super_field_set_test_none_multi.Class = class Class extends final_super_field_set_test_none_multi.SuperClass {
    new() {
      super.new();
    }
    m() {}
  };
  dart.setSignature(final_super_field_set_test_none_multi.Class, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
  });
  final_super_field_set_test_none_multi.main = function() {
  };
  dart.fn(final_super_field_set_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.final_super_field_set_test_none_multi = final_super_field_set_test_none_multi;
});

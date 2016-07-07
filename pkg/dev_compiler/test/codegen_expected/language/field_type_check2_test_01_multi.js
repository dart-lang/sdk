dart_library.library('language/field_type_check2_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__field_type_check2_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const field_type_check2_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_type_check2_test_01_multi.A = class A extends core.Object {
    new() {
      this.a = null;
    }
    bar(c) {
      dart.dput(c, 'a', 2);
    }
  };
  dart.setSignature(field_type_check2_test_01_multi.A, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  field_type_check2_test_01_multi.B = class B extends core.Object {
    new() {
      this.a = null;
    }
  };
  field_type_check2_test_01_multi.main = function() {
    new field_type_check2_test_01_multi.A().bar(new field_type_check2_test_01_multi.A());
    new field_type_check2_test_01_multi.A().bar(new field_type_check2_test_01_multi.B());
  };
  dart.fn(field_type_check2_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.field_type_check2_test_01_multi = field_type_check2_test_01_multi;
});

dart_library.library('language/field_method_test', null, /* Imports */[
  'dart_sdk'
], function load__field_method_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const field_method_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_method_test.A = class A extends core.Object {
    new() {
      this.foo = null;
      this.foo = dart.fn(() => {
      }, VoidTodynamic());
    }
    bar() {
      dart.dcall(this.foo);
    }
  };
  dart.setSignature(field_method_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(field_method_test.A, [])}),
    methods: () => ({bar: dart.definiteFunctionType(dart.void, [])})
  });
  field_method_test.FieldMethodTest = class FieldMethodTest extends core.Object {
    static testMain() {
      new field_method_test.A().bar();
    }
  };
  dart.setSignature(field_method_test.FieldMethodTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  field_method_test.main = function() {
    field_method_test.FieldMethodTest.testMain();
  };
  dart.fn(field_method_test.main, VoidTodynamic());
  // Exports:
  exports.field_method_test = field_method_test;
});

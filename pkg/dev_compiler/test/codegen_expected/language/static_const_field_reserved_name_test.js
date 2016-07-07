dart_library.library('language/static_const_field_reserved_name_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_const_field_reserved_name_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_const_field_reserved_name_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  static_const_field_reserved_name_test.Field = class Field extends core.Object {};
  dart.defineLazy(static_const_field_reserved_name_test.Field, {
    get name() {
      return 'Foo';
    }
  });
  static_const_field_reserved_name_test.StaticConstFieldReservedNameTest = class StaticConstFieldReservedNameTest extends core.Object {
    static testMain() {
      expect$.Expect.equals('Foo', static_const_field_reserved_name_test.Field.name);
    }
  };
  dart.setSignature(static_const_field_reserved_name_test.StaticConstFieldReservedNameTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  static_const_field_reserved_name_test.main = function() {
    static_const_field_reserved_name_test.StaticConstFieldReservedNameTest.testMain();
  };
  dart.fn(static_const_field_reserved_name_test.main, VoidTovoid());
  // Exports:
  exports.static_const_field_reserved_name_test = static_const_field_reserved_name_test;
});

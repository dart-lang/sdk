dart_library.library('language/and_operation_on_non_integer_operand_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__and_operation_on_non_integer_operand_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const and_operation_on_non_integer_operand_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  and_operation_on_non_integer_operand_test.NotAnInt = class NotAnInt extends core.Object {
    ['&'](b) {
      return this;
    }
  };
  dart.setSignature(and_operation_on_non_integer_operand_test.NotAnInt, {
    methods: () => ({'&': dart.definiteFunctionType(and_operation_on_non_integer_operand_test.NotAnInt, [dart.dynamic])})
  });
  and_operation_on_non_integer_operand_test.id = function(x) {
    return x;
  };
  dart.fn(and_operation_on_non_integer_operand_test.id, dynamicTodynamic());
  and_operation_on_non_integer_operand_test.main = function() {
    let a = and_operation_on_non_integer_operand_test.id(new and_operation_on_non_integer_operand_test.NotAnInt());
    expect$.Expect.equals(a, dart.dsend(dart.dsend(a, '&', 5), '&', 2));
  };
  dart.fn(and_operation_on_non_integer_operand_test.main, VoidTodynamic());
  // Exports:
  exports.and_operation_on_non_integer_operand_test = and_operation_on_non_integer_operand_test;
});

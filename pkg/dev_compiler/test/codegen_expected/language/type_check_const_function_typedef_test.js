dart_library.library('language/type_check_const_function_typedef_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_check_const_function_typedef_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_check_const_function_typedef_test = Object.create(null);
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_check_const_function_typedef_test.Int2String = dart.typedef('Int2String', () => dart.functionType(core.String, [core.int]));
  type_check_const_function_typedef_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
  };
  dart.setSignature(type_check_const_function_typedef_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(type_check_const_function_typedef_test.A, [type_check_const_function_typedef_test.Int2String])})
  });
  type_check_const_function_typedef_test.foo = function(x) {
    return "str";
  };
  dart.fn(type_check_const_function_typedef_test.foo, intToString());
  type_check_const_function_typedef_test.a = dart.const(new type_check_const_function_typedef_test.A(type_check_const_function_typedef_test.foo));
  type_check_const_function_typedef_test.main = function() {
    expect$.Expect.equals("str", type_check_const_function_typedef_test.a.f(499));
  };
  dart.fn(type_check_const_function_typedef_test.main, VoidTodynamic());
  // Exports:
  exports.type_check_const_function_typedef_test = type_check_const_function_typedef_test;
});

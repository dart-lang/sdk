dart_library.library('language/function_type_parameter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_parameter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_parameter_test = Object.create(null);
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_parameter_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
    nother(f) {
      this.f = f;
    }
    static SetFunc(fmt) {
      if (fmt === void 0) fmt = null;
      function_type_parameter_test.A.func = fmt;
    }
  };
  dart.defineNamedConstructor(function_type_parameter_test.A, 'nother');
  dart.setSignature(function_type_parameter_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(function_type_parameter_test.A, [dart.functionType(core.int, [])]),
      nother: dart.definiteFunctionType(function_type_parameter_test.A, [dart.functionType(core.int, [])])
    }),
    statics: () => ({SetFunc: dart.definiteFunctionType(dart.dynamic, [], [dart.functionType(core.String, [core.int])])}),
    names: ['SetFunc']
  });
  function_type_parameter_test.A.func = null;
  function_type_parameter_test.main = function() {
    expect$.Expect.equals(null, function_type_parameter_test.A.func);
    function_type_parameter_test.A.SetFunc(dart.fn(i => dart.str`${i}`, intToString()));
    expect$.Expect.equals(false, null == function_type_parameter_test.A.func);
    expect$.Expect.equals("1234", dart.dsend(function_type_parameter_test.A, 'func', 1230 + 4));
    function_type_parameter_test.A.SetFunc();
    expect$.Expect.equals(null, function_type_parameter_test.A.func);
    expect$.Expect.equals(42, dart.dsend(new function_type_parameter_test.A(dart.fn(() => 42, VoidToint())), 'f'));
    expect$.Expect.equals(42, dart.dsend(new function_type_parameter_test.A.nother(dart.fn(() => 42, VoidToint())), 'f'));
  };
  dart.fn(function_type_parameter_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_parameter_test = function_type_parameter_test;
});

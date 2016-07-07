dart_library.library('language/named_parameters_named_count_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_named_count_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_named_count_test = Object.create(null);
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_named_count_test.TestClass = class TestClass extends core.Object {
    new() {
    }
    method(count) {
      if (count === void 0) count = null;
      return count;
    }
    static staticMethod(count) {
      if (count === void 0) count = null;
      return count;
    }
  };
  dart.setSignature(named_parameters_named_count_test.TestClass, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_named_count_test.TestClass, [])}),
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])}),
    names: ['staticMethod']
  });
  named_parameters_named_count_test.globalMethod = function(count) {
    if (count === void 0) count = null;
    return count;
  };
  dart.fn(named_parameters_named_count_test.globalMethod, __Todynamic());
  named_parameters_named_count_test.main = function() {
    let obj = new named_parameters_named_count_test.TestClass();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method(0));
    expect$.Expect.equals("", obj.method(""));
    expect$.Expect.equals(null, named_parameters_named_count_test.TestClass.staticMethod());
    expect$.Expect.equals(true, named_parameters_named_count_test.TestClass.staticMethod(true));
    expect$.Expect.equals(false, named_parameters_named_count_test.TestClass.staticMethod(false));
    expect$.Expect.equals(null, named_parameters_named_count_test.globalMethod());
    expect$.Expect.equals(true, named_parameters_named_count_test.globalMethod(true));
    expect$.Expect.equals(false, named_parameters_named_count_test.globalMethod(false));
  };
  dart.fn(named_parameters_named_count_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_named_count_test = named_parameters_named_count_test;
});

dart_library.library('language/named_parameters_passing_zero_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_passing_zero_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_passing_zero_test = Object.create(null);
  let __Tonum = () => (__Tonum = dart.constFn(dart.definiteFunctionType(core.num, [], [core.num])))();
  let __Tonum$ = () => (__Tonum$ = dart.constFn(dart.definiteFunctionType(core.num, [], {value: core.num})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_passing_zero_test.TestClass = class TestClass extends core.Object {
    new() {
    }
    method(value) {
      if (value === void 0) value = 100;
      return value;
    }
    method2(opts) {
      let value = opts && 'value' in opts ? opts.value : 100;
      return value;
    }
    static staticMethod(value) {
      if (value === void 0) value = 200;
      return value;
    }
    static staticMethod2(opts) {
      let value = opts && 'value' in opts ? opts.value : 200;
      return value;
    }
  };
  dart.setSignature(named_parameters_passing_zero_test.TestClass, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_passing_zero_test.TestClass, [])}),
    methods: () => ({
      method: dart.definiteFunctionType(core.num, [], [core.num]),
      method2: dart.definiteFunctionType(core.num, [], {value: core.num})
    }),
    statics: () => ({
      staticMethod: dart.definiteFunctionType(core.num, [], [core.num]),
      staticMethod2: dart.definiteFunctionType(core.num, [], {value: core.num})
    }),
    names: ['staticMethod', 'staticMethod2']
  });
  named_parameters_passing_zero_test.globalMethod = function(value) {
    if (value === void 0) value = 300;
    return value;
  };
  dart.fn(named_parameters_passing_zero_test.globalMethod, __Tonum());
  named_parameters_passing_zero_test.globalMethod2 = function(opts) {
    let value = opts && 'value' in opts ? opts.value : 300;
    return value;
  };
  dart.fn(named_parameters_passing_zero_test.globalMethod2, __Tonum$());
  named_parameters_passing_zero_test.main = function() {
    let obj = new named_parameters_passing_zero_test.TestClass();
    expect$.Expect.equals(100, obj.method());
    expect$.Expect.equals(100, obj.method2());
    expect$.Expect.equals(7, obj.method(7));
    expect$.Expect.equals(7, obj.method2({value: 7}));
    expect$.Expect.equals(0, obj.method(0));
    expect$.Expect.equals(0, obj.method2({value: 0}));
    expect$.Expect.equals(200, named_parameters_passing_zero_test.TestClass.staticMethod());
    expect$.Expect.equals(200, named_parameters_passing_zero_test.TestClass.staticMethod2());
    expect$.Expect.equals(7, named_parameters_passing_zero_test.TestClass.staticMethod(7));
    expect$.Expect.equals(7, named_parameters_passing_zero_test.TestClass.staticMethod2({value: 7}));
    expect$.Expect.equals(0, named_parameters_passing_zero_test.TestClass.staticMethod(0));
    expect$.Expect.equals(0, named_parameters_passing_zero_test.TestClass.staticMethod2({value: 0}));
    expect$.Expect.equals(300, named_parameters_passing_zero_test.globalMethod());
    expect$.Expect.equals(300, named_parameters_passing_zero_test.globalMethod2());
    expect$.Expect.equals(7, named_parameters_passing_zero_test.globalMethod(7));
    expect$.Expect.equals(7, named_parameters_passing_zero_test.globalMethod2({value: 7}));
    expect$.Expect.equals(0, named_parameters_passing_zero_test.globalMethod(0));
    expect$.Expect.equals(0, named_parameters_passing_zero_test.globalMethod2({value: 0}));
  };
  dart.fn(named_parameters_passing_zero_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_passing_zero_test = named_parameters_passing_zero_test;
});

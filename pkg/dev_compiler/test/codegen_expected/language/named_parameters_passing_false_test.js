dart_library.library('language/named_parameters_passing_false_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_passing_false_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_passing_false_test = Object.create(null);
  let __Tobool = () => (__Tobool = dart.constFn(dart.definiteFunctionType(core.bool, [], [core.bool])))();
  let __Tobool$ = () => (__Tobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [], {value: core.bool})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_passing_false_test.TestClass = class TestClass extends core.Object {
    new() {
    }
    method(value) {
      if (value === void 0) value = null;
      return value;
    }
    method2(opts) {
      let value = opts && 'value' in opts ? opts.value : null;
      return value;
    }
    static staticMethod(value) {
      if (value === void 0) value = null;
      return value;
    }
    static staticMethod2(opts) {
      let value = opts && 'value' in opts ? opts.value : null;
      return value;
    }
  };
  dart.setSignature(named_parameters_passing_false_test.TestClass, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_passing_false_test.TestClass, [])}),
    methods: () => ({
      method: dart.definiteFunctionType(core.bool, [], [core.bool]),
      method2: dart.definiteFunctionType(core.bool, [], {value: core.bool})
    }),
    statics: () => ({
      staticMethod: dart.definiteFunctionType(core.bool, [], [core.bool]),
      staticMethod2: dart.definiteFunctionType(core.bool, [], {value: core.bool})
    }),
    names: ['staticMethod', 'staticMethod2']
  });
  named_parameters_passing_false_test.globalMethod = function(value) {
    if (value === void 0) value = null;
    return value;
  };
  dart.fn(named_parameters_passing_false_test.globalMethod, __Tobool());
  named_parameters_passing_false_test.globalMethod2 = function(opts) {
    let value = opts && 'value' in opts ? opts.value : null;
    return value;
  };
  dart.fn(named_parameters_passing_false_test.globalMethod2, __Tobool$());
  named_parameters_passing_false_test.main = function() {
    let obj = new named_parameters_passing_false_test.TestClass();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(null, obj.method2());
    expect$.Expect.equals(true, obj.method(true));
    expect$.Expect.equals(true, obj.method2({value: true}));
    expect$.Expect.equals(false, obj.method(false));
    expect$.Expect.equals(false, obj.method2({value: false}));
    expect$.Expect.equals(null, named_parameters_passing_false_test.TestClass.staticMethod());
    expect$.Expect.equals(null, named_parameters_passing_false_test.TestClass.staticMethod2());
    expect$.Expect.equals(true, named_parameters_passing_false_test.TestClass.staticMethod(true));
    expect$.Expect.equals(true, named_parameters_passing_false_test.TestClass.staticMethod2({value: true}));
    expect$.Expect.equals(false, named_parameters_passing_false_test.TestClass.staticMethod(false));
    expect$.Expect.equals(false, named_parameters_passing_false_test.TestClass.staticMethod2({value: false}));
    expect$.Expect.equals(null, named_parameters_passing_false_test.globalMethod());
    expect$.Expect.equals(null, named_parameters_passing_false_test.globalMethod2());
    expect$.Expect.equals(true, named_parameters_passing_false_test.globalMethod(true));
    expect$.Expect.equals(true, named_parameters_passing_false_test.globalMethod2({value: true}));
    expect$.Expect.equals(false, named_parameters_passing_false_test.globalMethod(false));
    expect$.Expect.equals(false, named_parameters_passing_false_test.globalMethod2({value: false}));
  };
  dart.fn(named_parameters_passing_false_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_passing_false_test = named_parameters_passing_false_test;
});

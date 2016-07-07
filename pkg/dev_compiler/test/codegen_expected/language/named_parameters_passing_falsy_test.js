dart_library.library('language/named_parameters_passing_falsy_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_passing_falsy_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_passing_falsy_test = Object.create(null);
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])))();
  let __Todynamic$ = () => (__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {value: dart.dynamic})))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_passing_falsy_test.TestClass = class TestClass extends core.Object {
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
  dart.setSignature(named_parameters_passing_falsy_test.TestClass, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_passing_falsy_test.TestClass, [])}),
    methods: () => ({
      method: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic]),
      method2: dart.definiteFunctionType(dart.dynamic, [], {value: dart.dynamic})
    }),
    statics: () => ({
      staticMethod: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic]),
      staticMethod2: dart.definiteFunctionType(dart.dynamic, [], {value: dart.dynamic})
    }),
    names: ['staticMethod', 'staticMethod2']
  });
  named_parameters_passing_falsy_test.globalMethod = function(value) {
    if (value === void 0) value = 300;
    return value;
  };
  dart.fn(named_parameters_passing_falsy_test.globalMethod, __Todynamic());
  named_parameters_passing_falsy_test.globalMethod2 = function(opts) {
    let value = opts && 'value' in opts ? opts.value : 300;
    return value;
  };
  dart.fn(named_parameters_passing_falsy_test.globalMethod2, __Todynamic$());
  named_parameters_passing_falsy_test.testValues = dart.constList([0, 0.0, '', false, null], core.Object);
  named_parameters_passing_falsy_test.testFunction = function(f, f2) {
    expect$.Expect.isTrue(dart.dsend(dart.dcall(f), '>=', 100));
    for (let v of named_parameters_passing_falsy_test.testValues) {
      expect$.Expect.equals(v, dart.dcall(f, v));
      expect$.Expect.equals(v, dart.dcall(f2, {value: v}));
    }
  };
  dart.fn(named_parameters_passing_falsy_test.testFunction, dynamicAnddynamicTodynamic());
  named_parameters_passing_falsy_test.main = function() {
    let obj = new named_parameters_passing_falsy_test.TestClass();
    expect$.Expect.equals(100, obj.method());
    expect$.Expect.equals(100, obj.method2());
    expect$.Expect.equals(200, named_parameters_passing_falsy_test.TestClass.staticMethod());
    expect$.Expect.equals(200, named_parameters_passing_falsy_test.TestClass.staticMethod2());
    expect$.Expect.equals(300, named_parameters_passing_falsy_test.globalMethod());
    expect$.Expect.equals(300, named_parameters_passing_falsy_test.globalMethod2());
    for (let v of named_parameters_passing_falsy_test.testValues) {
      expect$.Expect.equals(v, obj.method(v));
      expect$.Expect.equals(v, obj.method2({value: v}));
      expect$.Expect.equals(v, named_parameters_passing_falsy_test.TestClass.staticMethod(v));
      expect$.Expect.equals(v, named_parameters_passing_falsy_test.TestClass.staticMethod2({value: v}));
      expect$.Expect.equals(v, named_parameters_passing_falsy_test.globalMethod(v));
      expect$.Expect.equals(v, named_parameters_passing_falsy_test.globalMethod2({value: v}));
    }
    named_parameters_passing_falsy_test.testFunction(dart.bind(obj, 'method'), dart.bind(obj, 'method2'));
    named_parameters_passing_falsy_test.testFunction(named_parameters_passing_falsy_test.TestClass.staticMethod, named_parameters_passing_falsy_test.TestClass.staticMethod2);
    named_parameters_passing_falsy_test.testFunction(named_parameters_passing_falsy_test.globalMethod, named_parameters_passing_falsy_test.globalMethod2);
  };
  dart.fn(named_parameters_passing_falsy_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_passing_falsy_test = named_parameters_passing_falsy_test;
});

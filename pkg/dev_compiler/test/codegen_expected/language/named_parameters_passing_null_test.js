dart_library.library('language/named_parameters_passing_null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_passing_null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_passing_null_test = Object.create(null);
  let __Tonum = () => (__Tonum = dart.constFn(dart.definiteFunctionType(core.num, [], [dart.dynamic])))();
  let __Tonum$ = () => (__Tonum$ = dart.constFn(dart.definiteFunctionType(core.num, [], {value: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_passing_null_test.TestClass = class TestClass extends core.Object {
    new() {
    }
    method(value) {
      if (value === void 0) value = 100;
      return core.num._check(value);
    }
    method2(opts) {
      let value = opts && 'value' in opts ? opts.value : 100;
      return core.num._check(value);
    }
    static staticMethod(value) {
      if (value === void 0) value = 200;
      return core.num._check(value);
    }
    static staticMethod2(opts) {
      let value = opts && 'value' in opts ? opts.value : 200;
      return core.num._check(value);
    }
  };
  dart.setSignature(named_parameters_passing_null_test.TestClass, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_passing_null_test.TestClass, [])}),
    methods: () => ({
      method: dart.definiteFunctionType(core.num, [], [dart.dynamic]),
      method2: dart.definiteFunctionType(core.num, [], {value: dart.dynamic})
    }),
    statics: () => ({
      staticMethod: dart.definiteFunctionType(core.num, [], [dart.dynamic]),
      staticMethod2: dart.definiteFunctionType(core.num, [], {value: dart.dynamic})
    }),
    names: ['staticMethod', 'staticMethod2']
  });
  named_parameters_passing_null_test.globalMethod = function(value) {
    if (value === void 0) value = 300;
    return core.num._check(value);
  };
  dart.fn(named_parameters_passing_null_test.globalMethod, __Tonum());
  named_parameters_passing_null_test.globalMethod2 = function(opts) {
    let value = opts && 'value' in opts ? opts.value : 300;
    return core.num._check(value);
  };
  dart.fn(named_parameters_passing_null_test.globalMethod2, __Tonum$());
  named_parameters_passing_null_test.main = function() {
    let obj = new named_parameters_passing_null_test.TestClass();
    expect$.Expect.equals(100, obj.method());
    expect$.Expect.equals(100, obj.method2());
    expect$.Expect.equals(50, obj.method(50));
    expect$.Expect.equals(50, obj.method2({value: 50}));
    expect$.Expect.equals(null, obj.method(null));
    expect$.Expect.equals(null, obj.method2({value: null}));
    expect$.Expect.equals(200, named_parameters_passing_null_test.TestClass.staticMethod());
    expect$.Expect.equals(200, named_parameters_passing_null_test.TestClass.staticMethod2());
    expect$.Expect.equals(50, named_parameters_passing_null_test.TestClass.staticMethod(50));
    expect$.Expect.equals(50, named_parameters_passing_null_test.TestClass.staticMethod2({value: 50}));
    expect$.Expect.equals(null, named_parameters_passing_null_test.TestClass.staticMethod(null));
    expect$.Expect.equals(null, named_parameters_passing_null_test.TestClass.staticMethod2({value: null}));
    expect$.Expect.equals(300, named_parameters_passing_null_test.globalMethod());
    expect$.Expect.equals(300, named_parameters_passing_null_test.globalMethod2());
    expect$.Expect.equals(50, named_parameters_passing_null_test.globalMethod(50));
    expect$.Expect.equals(50, named_parameters_passing_null_test.globalMethod2({value: 50}));
    expect$.Expect.equals(null, named_parameters_passing_null_test.globalMethod(null));
    expect$.Expect.equals(null, named_parameters_passing_null_test.globalMethod2({value: null}));
  };
  dart.fn(named_parameters_passing_null_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_passing_null_test = named_parameters_passing_null_test;
});

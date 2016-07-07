dart_library.library('language/cascade_in_expression_function_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade_in_expression_function_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade_in_expression_function_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade_in_expression_function_test.makeMap = function() {
    return (() => {
      let _ = core.Map.new();
      _[dartx.set](3, 4);
      _[dartx.set](0, 11);
      return _;
    })();
  };
  dart.fn(cascade_in_expression_function_test.makeMap, VoidTodynamic());
  cascade_in_expression_function_test.MyClass = class MyClass extends core.Object {
    foo() {
      return (() => {
        this.bar(3);
        this.baz(4);
        return this;
      })();
    }
    bar(x) {
      return x;
    }
    baz(y) {
      return dart.dsend(y, '*', 2);
    }
  };
  dart.setSignature(cascade_in_expression_function_test.MyClass, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      baz: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  cascade_in_expression_function_test.main = function() {
    let o = new cascade_in_expression_function_test.MyClass();
    expect$.Expect.equals(o.foo(), o);
    let g = cascade_in_expression_function_test.makeMap();
    expect$.Expect.equals(dart.dindex(g, 3), 4);
    expect$.Expect.equals(dart.dindex(g, 0), 11);
  };
  dart.fn(cascade_in_expression_function_test.main, VoidTodynamic());
  // Exports:
  exports.cascade_in_expression_function_test = cascade_in_expression_function_test;
});

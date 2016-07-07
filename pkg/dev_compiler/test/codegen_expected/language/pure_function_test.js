dart_library.library('language/pure_function_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__pure_function_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const pure_function_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  pure_function_test.A = class A extends core.Object {
    new(x, y) {
      this.y = y;
      this.x = null;
      this.x = x;
    }
    toString() {
      return "a";
    }
  };
  dart.setSignature(pure_function_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(pure_function_test.A, [dart.dynamic, dart.dynamic])})
  });
  pure_function_test.foo = function(trace) {
    return dart.dsend(trace, 'add', "foo");
  };
  dart.fn(pure_function_test.foo, dynamicTodynamic());
  pure_function_test.bar = function(trace) {
    return dart.dsend(trace, 'add', "bar");
  };
  dart.fn(pure_function_test.bar, dynamicTodynamic());
  pure_function_test.main = function() {
    let trace = [];
    let t1 = pure_function_test.foo(trace);
    let t2 = pure_function_test.bar(trace);
    let a = new pure_function_test.A(t1, t2);
    trace[dartx.add](a.toString());
    expect$.Expect.listEquals(JSArrayOfString().of(["foo", "bar", "a"]), trace);
  };
  dart.fn(pure_function_test.main, VoidTodynamic());
  // Exports:
  exports.pure_function_test = pure_function_test;
});

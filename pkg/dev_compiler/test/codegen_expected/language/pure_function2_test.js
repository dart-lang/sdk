dart_library.library('language/pure_function2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__pure_function2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const pure_function2_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  pure_function2_test.confuse = function(x) {
    if (new core.DateTime.now().millisecondsSinceEpoch == 42) return pure_function2_test.confuse(x);
    return x;
  };
  dart.fn(pure_function2_test.confuse, dynamicTodynamic());
  pure_function2_test.foo = function(trace) {
    dart.dsend(trace, 'add', "foo");
    return "foo";
  };
  dart.fn(pure_function2_test.foo, dynamicTodynamic());
  pure_function2_test.bar = function(trace) {
    dart.dsend(trace, 'add', "bar");
    return "bar";
  };
  dart.fn(pure_function2_test.bar, dynamicTodynamic());
  pure_function2_test.main = function() {
    let f = pure_function2_test.confuse(pure_function2_test.foo);
    let b = pure_function2_test.confuse(pure_function2_test.bar);
    let trace = [];
    let t1 = dart.dcall(f, trace);
    let t2 = dart.dcall(b, trace);
    let t3 = core.identical(t2, "foo");
    let t4 = trace[dartx.add](t1);
    trace[dartx.add](t3);
    trace[dartx.add](t3);
    expect$.Expect.listEquals(JSArrayOfObject().of(["foo", "bar", "foo", false, false]), trace);
  };
  dart.fn(pure_function2_test.main, VoidTodynamic());
  // Exports:
  exports.pure_function2_test = pure_function2_test;
});

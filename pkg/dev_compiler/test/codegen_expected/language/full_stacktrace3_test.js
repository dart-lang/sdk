dart_library.library('language/full_stacktrace3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__full_stacktrace3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const full_stacktrace3_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  full_stacktrace3_test.func1 = function() {
    dart.throw(core.Exception.new("Test full stacktrace"));
  };
  dart.fn(full_stacktrace3_test.func1, VoidTovoid());
  full_stacktrace3_test.func2 = function() {
    full_stacktrace3_test.func1();
  };
  dart.fn(full_stacktrace3_test.func2, VoidTovoid());
  full_stacktrace3_test.func3 = function() {
    try {
      full_stacktrace3_test.func2();
    } catch (e) {
      if (core.Object.is(e)) {
        let s = dart.stackTrace(e);
        let fullTrace = s.toString();
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func1"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func2"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func3"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func4"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func5"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func6"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func7"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("main"));
        dart.throw(core.Exception.new("This is not a rethrow"));
      } else
        throw e;
    }

  };
  dart.fn(full_stacktrace3_test.func3, VoidTovoid());
  full_stacktrace3_test.func4 = function() {
    full_stacktrace3_test.func3();
    return 1;
  };
  dart.fn(full_stacktrace3_test.func4, VoidToint());
  full_stacktrace3_test.func5 = function() {
    try {
      full_stacktrace3_test.func4();
    } catch (e) {
      if (core.Object.is(e)) {
        let s = dart.stackTrace(e);
        let fullTrace = s.toString();
        expect$.Expect.isFalse(fullTrace[dartx.contains]("func1"));
        expect$.Expect.isFalse(fullTrace[dartx.contains]("func2"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func3"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func4"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func5"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func6"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("func7"));
        expect$.Expect.isTrue(fullTrace[dartx.contains]("main"));
      } else
        throw e;
    }

    return 1;
  };
  dart.fn(full_stacktrace3_test.func5, VoidToint());
  full_stacktrace3_test.func6 = function() {
    full_stacktrace3_test.func5();
    return 1;
  };
  dart.fn(full_stacktrace3_test.func6, VoidToint());
  full_stacktrace3_test.func7 = function() {
    full_stacktrace3_test.func6();
    return 1;
  };
  dart.fn(full_stacktrace3_test.func7, VoidToint());
  full_stacktrace3_test.main = function() {
    let i = full_stacktrace3_test.func7();
    expect$.Expect.equals(1, i);
  };
  dart.fn(full_stacktrace3_test.main, VoidTodynamic());
  // Exports:
  exports.full_stacktrace3_test = full_stacktrace3_test;
});

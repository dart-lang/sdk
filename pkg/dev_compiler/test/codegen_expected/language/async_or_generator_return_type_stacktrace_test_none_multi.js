dart_library.library('language/async_or_generator_return_type_stacktrace_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__async_or_generator_return_type_stacktrace_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_or_generator_return_type_stacktrace_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_or_generator_return_type_stacktrace_test_none_multi.main = function() {
    try {
    } catch (e) {
      let st = dart.stackTrace(e);
      expect$.Expect.isTrue(core.TypeError.is(e), "wrong exception type");
      expect$.Expect.isTrue(st.toString()[dartx.contains]("badReturnTypeAsync"), "missing frame");
    }

    try {
    } catch (e) {
      let st = dart.stackTrace(e);
      expect$.Expect.isTrue(core.TypeError.is(e), "wrong exception type");
      expect$.Expect.isTrue(st.toString()[dartx.contains]("badReturnTypeAsyncStar"), "missing frame");
    }

    try {
    } catch (e) {
      let st = dart.stackTrace(e);
      expect$.Expect.isTrue(core.TypeError.is(e), "wrong exception type");
      expect$.Expect.isTrue(st.toString()[dartx.contains]("badReturnTypeSyncStar"), "missing frame");
    }

  };
  dart.fn(async_or_generator_return_type_stacktrace_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.async_or_generator_return_type_stacktrace_test_none_multi = async_or_generator_return_type_stacktrace_test_none_multi;
});

dart_library.library('language/stacktrace_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stacktrace_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stacktrace_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  stacktrace_test.main = function() {
    let ex = core.Exception.new("fail");
    try {
      dart.throw(ex);
    } catch (e) {
      if (core.Exception.is(e)) {
        let st = dart.stackTrace(e);
        expect$.Expect.equals(ex, e);
        expect$.Expect.isTrue(st.toString()[dartx.endsWith]("\n"));
      } else
        throw e;
    }

  };
  dart.fn(stacktrace_test.main, VoidTovoid());
  // Exports:
  exports.stacktrace_test = stacktrace_test;
});

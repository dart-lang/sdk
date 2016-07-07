dart_library.library('corelib/stacktrace_current_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stacktrace_current_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stacktrace_current_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StackTraceToString = () => (StackTraceToString = dart.constFn(dart.definiteFunctionType(core.String, [core.StackTrace])))();
  stacktrace_current_test.main = function() {
    let st0 = null;
    let st1 = null;
    try {
      dart.throw(0);
    } catch (_) {
      let s = dart.stackTrace(_);
      st0 = s;
    }

    st1 = core.StackTrace.current;
    let st0s = stacktrace_current_test.findMain(core.StackTrace._check(st0));
    let st1s = stacktrace_current_test.findMain(core.StackTrace._check(st1));
    let digits = core.RegExp.new("\\d+");
    expect$.Expect.equals(st0s[dartx.replaceAll](digits, "0"), st1s[dartx.replaceAll](digits, "0"));
  };
  dart.fn(stacktrace_current_test.main, VoidTovoid());
  stacktrace_current_test.findMain = function(stack) {
    let string = dart.str`${stack}`;
    let lines = convert.LineSplitter.split(string)[dartx.toList]();
    while (dart.test(lines[dartx.isNotEmpty]) && !dart.test(lines[dartx.first][dartx.contains]("main"))) {
      lines[dartx.removeAt](0);
    }
    return lines[dartx.join]("\n");
  };
  dart.fn(stacktrace_current_test.findMain, StackTraceToString());
  // Exports:
  exports.stacktrace_current_test = stacktrace_current_test;
});

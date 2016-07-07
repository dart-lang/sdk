dart_library.library('language/custom_await_stack_trace_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__custom_await_stack_trace_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const custom_await_stack_trace_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _trace = Symbol('_trace');
  custom_await_stack_trace_test.Blah = class Blah extends core.Object {
    new(trace) {
      this[_trace] = trace;
    }
    toString() {
      return "Blah " + dart.notNull(dart.toString(this[_trace]));
    }
  };
  custom_await_stack_trace_test.Blah[dart.implements] = () => [core.StackTrace];
  dart.setSignature(custom_await_stack_trace_test.Blah, {
    constructors: () => ({new: dart.definiteFunctionType(custom_await_stack_trace_test.Blah, [dart.dynamic])})
  });
  custom_await_stack_trace_test.foo = function() {
    let x = "\nBloop\nBleep\n";
    return async.Future.error(42, new custom_await_stack_trace_test.Blah(x));
  };
  dart.fn(custom_await_stack_trace_test.foo, VoidTodynamic());
  custom_await_stack_trace_test.main = function() {
    return dart.async(function*() {
      try {
        let x = (yield custom_await_stack_trace_test.foo());
        expect$.Expect.fail("Should not reach here.");
      } catch (e) {
        if (core.int.is(e)) {
          let s = dart.stackTrace(e);
          expect$.Expect.equals(42, e);
          expect$.Expect.equals("Blah \nBloop\nBleep\n", s.toString());
          return;
        } else
          throw e;
      }

      expect$.Expect.fail("Unreachable.");
    }, dart.dynamic);
  };
  dart.fn(custom_await_stack_trace_test.main, VoidTodynamic());
  // Exports:
  exports.custom_await_stack_trace_test = custom_await_stack_trace_test;
});

dart_library.library('corelib/stacktrace_fromstring_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__stacktrace_fromstring_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const stacktrace_fromstring_test = Object.create(null);
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  stacktrace_fromstring_test.main = function() {
    let stack = null;
    try {
      dart.throw(0);
    } catch (e) {
      let s = dart.stackTrace(e);
      stack = s;
    }

    let string = dart.str`${stack}`;
    let stringTrace = core.StackTrace.fromString(string);
    expect$.Expect.isTrue(core.StackTrace.is(stringTrace));
    expect$.Expect.equals(dart.toString(stack), stringTrace.toString());
    string = "some random string, nothing like a StackTrace";
    stringTrace = core.StackTrace.fromString(string);
    expect$.Expect.isTrue(core.StackTrace.is(stringTrace));
    expect$.Expect.equals(string, stringTrace.toString());
    async_helper$.asyncStart();
    let c = async.Completer.new();
    c.completeError(0, stringTrace);
    c.future.then(dart.dynamic)(dart.fn(v => {
      dart.throw(dart.str`Unexpected value: ${v}`);
    }, dynamicTodynamic()), {onError: dart.fn((e, s) => {
        expect$.Expect.equals(string, dart.toString(s));
      }, dynamicAnddynamicTodynamic())}).then(dart.dynamic)(dart.fn(_ => {
      let c = async.StreamController.new();
      c.stream.listen(dart.fn(v => {
        dart.throw(dart.str`Unexpected value: ${v}`);
      }, dynamicTovoid()), {onError: dart.fn((e, s) => {
          expect$.Expect.equals(string, dart.toString(s));
          async_helper$.asyncEnd();
        }, dynamicAnddynamicTodynamic())});
      c.addError(0, stringTrace);
      c.close();
    }, dynamicTodynamic()));
  };
  dart.fn(stacktrace_fromstring_test.main, VoidTovoid());
  // Exports:
  exports.stacktrace_fromstring_test = stacktrace_fromstring_test;
});

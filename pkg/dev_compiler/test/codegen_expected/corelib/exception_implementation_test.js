dart_library.library('corelib/exception_implementation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__exception_implementation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const exception_implementation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  exception_implementation_test.main = function() {
    let msg = 1;
    try {
      dart.throw(core.Exception.new(msg));
      expect$.Expect.fail("Unreachable");
    } catch (e) {
      if (core.Exception.is(e)) {
        expect$.Expect.isTrue(core.Exception.is(e));
        expect$.Expect.equals(dart.str`Exception: ${msg}`, dart.toString(e));
      } else
        throw e;
    }

  };
  dart.fn(exception_implementation_test.main, VoidTodynamic());
  // Exports:
  exports.exception_implementation_test = exception_implementation_test;
});

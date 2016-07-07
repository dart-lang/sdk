dart_library.library('language/catch_liveness_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__catch_liveness_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const catch_liveness_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  catch_liveness_test.foo = function() {
    return 1;
  };
  dart.fn(catch_liveness_test.foo, VoidTodynamic());
  catch_liveness_test.throwException = function() {
    return dart.throw('x');
  };
  dart.fn(catch_liveness_test.throwException, VoidTodynamic());
  catch_liveness_test.main = function() {
    let x = 10;
    let e2 = null;
    try {
      let t = catch_liveness_test.foo();
      catch_liveness_test.throwException();
      core.print(t);
      x = 3;
    } catch (e) {
      expect$.Expect.equals(10, x);
      e2 = e;
    }

    expect$.Expect.equals(10, x);
    expect$.Expect.equals('x', e2);
  };
  dart.fn(catch_liveness_test.main, VoidTodynamic());
  // Exports:
  exports.catch_liveness_test = catch_liveness_test;
});

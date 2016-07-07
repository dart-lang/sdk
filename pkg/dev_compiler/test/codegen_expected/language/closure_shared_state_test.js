dart_library.library('language/closure_shared_state_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_shared_state_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_shared_state_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  closure_shared_state_test.f = null;
  closure_shared_state_test.g = null;
  closure_shared_state_test.setupPlain = function() {
    let j = 1000;
    closure_shared_state_test.f = dart.fn(x => {
      let q = j;
      j = x;
      return q;
    }, intToint());
    closure_shared_state_test.g = dart.fn(x => {
      let q = j;
      j = x;
      return q;
    }, intToint());
  };
  dart.fn(closure_shared_state_test.setupPlain, VoidTodynamic());
  closure_shared_state_test.setupLoop = function() {
    for (let i = 0; i < 2; i++) {
      let j = i * 1000;
      closure_shared_state_test.f = dart.fn(x => {
        let q = j;
        j = x;
        return q;
      }, intToint());
      closure_shared_state_test.g = dart.fn(x => {
        let q = j;
        j = x;
        return q;
      }, intToint());
    }
  };
  dart.fn(closure_shared_state_test.setupLoop, VoidTodynamic());
  closure_shared_state_test.setupNestedLoop = function() {
    for (let outer = 0; outer < 2; outer++) {
      let j = outer * 1000;
      for (let i = 0; i < 2; i++) {
        closure_shared_state_test.f = dart.fn(x => {
          let q = j;
          j = x;
          return q;
        }, intToint());
        closure_shared_state_test.g = dart.fn(x => {
          let q = j;
          j = x;
          return q;
        }, intToint());
      }
    }
  };
  dart.fn(closure_shared_state_test.setupNestedLoop, VoidTodynamic());
  closure_shared_state_test.test = function(setup) {
    dart.dcall(setup);
    expect$.Expect.equals(1000, dart.dcall(closure_shared_state_test.f, 100));
    expect$.Expect.equals(100, dart.dcall(closure_shared_state_test.f, 200));
    expect$.Expect.equals(200, dart.dcall(closure_shared_state_test.f, 300));
    expect$.Expect.equals(300, dart.dcall(closure_shared_state_test.g, 400));
    expect$.Expect.equals(400, dart.dcall(closure_shared_state_test.g, 500));
  };
  dart.fn(closure_shared_state_test.test, dynamicTodynamic());
  closure_shared_state_test.main = function() {
    closure_shared_state_test.test(closure_shared_state_test.setupPlain);
    closure_shared_state_test.test(closure_shared_state_test.setupLoop);
    closure_shared_state_test.test(closure_shared_state_test.setupNestedLoop);
  };
  dart.fn(closure_shared_state_test.main, VoidTodynamic());
  // Exports:
  exports.closure_shared_state_test = closure_shared_state_test;
});

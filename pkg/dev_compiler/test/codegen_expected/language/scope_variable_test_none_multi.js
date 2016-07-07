dart_library.library('language/scope_variable_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__scope_variable_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const scope_variable_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  scope_variable_test_none_multi.testSimpleScope = function() {
    {
      let a = "Test";
      let b = 1;
    }
    {
      let c = null;
      let d = null;
      expect$.Expect.isNull(c);
      expect$.Expect.isNull(d);
    }
  };
  dart.fn(scope_variable_test_none_multi.testSimpleScope, VoidTovoid());
  scope_variable_test_none_multi.testShadowingScope = function() {
    let a = "Test";
    {
      let a = null;
      expect$.Expect.isNull(a);
      a = "a";
      expect$.Expect.equals(a, "a");
    }
    expect$.Expect.equals(a, "Test");
  };
  dart.fn(scope_variable_test_none_multi.testShadowingScope, VoidTovoid());
  scope_variable_test_none_multi.testShadowingAfterUse = function() {
    let a = 1;
    {
      let b = 2;
      let c = a;
      let d = b + c;
      return d + a;
    }
  };
  dart.fn(scope_variable_test_none_multi.testShadowingAfterUse, VoidToint());
  scope_variable_test_none_multi.main = function() {
    scope_variable_test_none_multi.testSimpleScope();
    scope_variable_test_none_multi.testShadowingScope();
    scope_variable_test_none_multi.testShadowingAfterUse();
  };
  dart.fn(scope_variable_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.scope_variable_test_none_multi = scope_variable_test_none_multi;
});

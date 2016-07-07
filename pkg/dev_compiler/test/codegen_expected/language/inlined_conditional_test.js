dart_library.library('language/inlined_conditional_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inlined_conditional_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inlined_conditional_test = Object.create(null);
  let dynamicToFunction = () => (dynamicToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inlined_conditional_test.topLevel = null;
  inlined_conditional_test.foo = function(c) {
    return core.Function._check(core.Function.is(c) ? null : c);
  };
  dart.fn(inlined_conditional_test.foo, dynamicToFunction());
  inlined_conditional_test.bar = function() {
    let b = new core.Object();
    function f() {
      if (inlined_conditional_test.foo(inlined_conditional_test.topLevel) == null) {
        return b.toString();
      } else {
        return b.hashCode;
      }
    }
    dart.fn(f, VoidTodynamic());
    return f();
  };
  dart.fn(inlined_conditional_test.bar, VoidTodynamic());
  inlined_conditional_test.main = function() {
    inlined_conditional_test.topLevel = new core.Object();
    inlined_conditional_test.topLevel = inlined_conditional_test.main;
    let res = inlined_conditional_test.bar();
    expect$.Expect.isTrue(typeof res == 'string');
  };
  dart.fn(inlined_conditional_test.main, VoidTodynamic());
  // Exports:
  exports.inlined_conditional_test = inlined_conditional_test;
});

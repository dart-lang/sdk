dart_library.library('language/recursive_calls_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__recursive_calls_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const recursive_calls_test = Object.create(null);
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  recursive_calls_test.bar = function(x) {
    return recursive_calls_test.foo(dart.dsend(x, '+', 1));
  };
  dart.fn(recursive_calls_test.bar, dynamicToint());
  recursive_calls_test.foo = function(x) {
    return core.int._check(dart.test(dart.dsend(x, '>', 9)) ? x : recursive_calls_test.bar(x));
  };
  dart.fn(recursive_calls_test.foo, dynamicToint());
  recursive_calls_test.main = function() {
    expect$.Expect.equals(recursive_calls_test.foo(core.int.parse("1")), 10);
  };
  dart.fn(recursive_calls_test.main, VoidTodynamic());
  // Exports:
  exports.recursive_calls_test = recursive_calls_test;
});

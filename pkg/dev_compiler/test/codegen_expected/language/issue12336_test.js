dart_library.library('language/issue12336_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue12336_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue12336_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  issue12336_test.main = function() {
    let result = issue12336_test.foo(1, 2);
    expect$.Expect.equals(1, dart.dindex(result, 0));
    expect$.Expect.equals(2, dart.dindex(result, 1));
    result = issue12336_test.foo([], 2);
    expect$.Expect.equals(0, dart.dindex(result, 0));
    expect$.Expect.listEquals([], core.List._check(dart.dindex(result, 1)));
  };
  dart.fn(issue12336_test.main, VoidTodynamic());
  issue12336_test.foo = function(a, b) {
    dart.fn(() => 42, VoidToint());
    if (core.List.is(a)) {
      let saved = core.List.as(a);
      a = dart.dload(a, 'length');
      b = saved;
    }
    return [a, b];
  };
  dart.fn(issue12336_test.foo, dynamicAnddynamicTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.issue12336_test = issue12336_test;
  exports.compiler_annotations = compiler_annotations;
});

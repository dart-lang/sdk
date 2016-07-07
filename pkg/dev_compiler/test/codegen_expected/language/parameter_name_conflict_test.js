dart_library.library('language/parameter_name_conflict_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__parameter_name_conflict_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const parameter_name_conflict_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parameter_name_conflict_test.foo = function(t0) {
    let a = t0, b = parameter_name_conflict_test.baz(), c = parameter_name_conflict_test.bar();
    if (dart.equals(t0, 'foo')) {
      let tmp = c;
      c = b;
      b = tmp;
    }
    expect$.Expect.equals('foo', a);
    expect$.Expect.equals('foo', t0);
    expect$.Expect.equals('bar', b);
    expect$.Expect.equals('baz', c);
  };
  dart.fn(parameter_name_conflict_test.foo, dynamicTodynamic());
  parameter_name_conflict_test.bar = function() {
    return 'bar';
  };
  dart.fn(parameter_name_conflict_test.bar, VoidTodynamic());
  parameter_name_conflict_test.baz = function() {
    return 'baz';
  };
  dart.fn(parameter_name_conflict_test.baz, VoidTodynamic());
  parameter_name_conflict_test.main = function() {
    parameter_name_conflict_test.foo('foo');
  };
  dart.fn(parameter_name_conflict_test.main, VoidTodynamic());
  // Exports:
  exports.parameter_name_conflict_test = parameter_name_conflict_test;
});

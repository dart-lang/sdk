dart_library.library('language/dead_field_access_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dead_field_access_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dead_field_access_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dead_field_access_test.Foo = class Foo extends core.Object {
    new() {
      this.field = 10;
    }
  };
  dead_field_access_test.getField = function(x) {
    dart.dload(x, 'field');
    return 34;
  };
  dart.fn(dead_field_access_test.getField, dynamicTodynamic());
  dead_field_access_test.main = function() {
    expect$.Expect.equals(34, dead_field_access_test.getField(new dead_field_access_test.Foo()));
    expect$.Expect.throws(dart.fn(() => dead_field_access_test.getField(null), VoidTovoid()));
  };
  dart.fn(dead_field_access_test.main, VoidTodynamic());
  // Exports:
  exports.dead_field_access_test = dead_field_access_test;
});

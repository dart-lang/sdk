dart_library.library('language/static_field_override2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_field_override2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_field_override2_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  static_field_override2_test.Foo = class Foo extends core.Object {
    static get x() {
      return 42;
    }
    static set x(value) {}
  };
  static_field_override2_test.Bar = class Bar extends static_field_override2_test.Foo {};
  dart.defineLazy(static_field_override2_test.Bar, {
    get x() {
      return 12;
    },
    set x(_) {}
  });
  static_field_override2_test.main = function() {
    expect$.Expect.equals(12, static_field_override2_test.Bar.x);
  };
  dart.fn(static_field_override2_test.main, VoidTovoid());
  // Exports:
  exports.static_field_override2_test = static_field_override2_test;
});

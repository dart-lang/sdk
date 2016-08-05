dart_library.library('language/closure_in_field_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_in_field_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_in_field_initializer_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicTodynamic$ = () => (dynamicAnddynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_in_field_initializer_test.Foo = class Foo extends core.Object {
    new() {
      this.closures = dart.map({a: dart.fn((x, y) => dart.dsend(x, '+', y), dynamicAnddynamicTodynamic$())}, core.String, dynamicAnddynamicTodynamic());
    }
  };
  closure_in_field_initializer_test.main = function() {
    let closures = new closure_in_field_initializer_test.Foo().closures;
    expect$.Expect.equals(6, dart.dcall(closures[dartx.get]('a'), 4, 2));
  };
  dart.fn(closure_in_field_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.closure_in_field_initializer_test = closure_in_field_initializer_test;
});

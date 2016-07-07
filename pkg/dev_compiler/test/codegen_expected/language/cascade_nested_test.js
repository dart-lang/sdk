dart_library.library('language/cascade_nested_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade_nested_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade_nested_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade_nested_test.Foo = class Foo extends core.Object {
    new() {
      this.x = null;
    }
  };
  cascade_nested_test.Bar = class Bar extends core.Object {
    new() {
      this.foo = null;
      this.y = null;
    }
  };
  cascade_nested_test.main = function() {
    let bar = new cascade_nested_test.Bar();
    bar.foo = (() => {
      let _ = new cascade_nested_test.Foo();
      _.x = 42;
      return _;
    })();
    bar.y = 38;
    expect$.Expect.isTrue(cascade_nested_test.Bar.is(bar));
    expect$.Expect.isTrue(cascade_nested_test.Foo.is(bar.foo));
    expect$.Expect.equals(bar.foo.x, 42);
    expect$.Expect.equals(bar.y, 38);
  };
  dart.fn(cascade_nested_test.main, VoidTodynamic());
  // Exports:
  exports.cascade_nested_test = cascade_nested_test;
});

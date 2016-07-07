dart_library.library('language/rewrite_variable_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_variable_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_variable_initializer_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_variable_initializer_test.Foo = class Foo extends core.Object {
    new() {
      this.field = 0;
    }
  };
  rewrite_variable_initializer_test.bar = function(x, y) {
    return dart.dsend(dart.dsend(x, '*', 100), '+', y);
  };
  dart.fn(rewrite_variable_initializer_test.bar, dynamicAnddynamicTodynamic());
  rewrite_variable_initializer_test.foo = function(z) {
    let x = 0, y = x;
    if (dart.test(dart.dsend(z, '>', 0))) {
      x = 10;
    }
    if (dart.test(dart.dsend(z, '>', 10))) {
      y = 20;
    }
    return rewrite_variable_initializer_test.bar(x, y);
  };
  dart.fn(rewrite_variable_initializer_test.foo, dynamicTodynamic());
  rewrite_variable_initializer_test.baz = function(z) {
    let f = new rewrite_variable_initializer_test.Foo();
    f.field = 10;
    f.field = core.int._check(z);
    return f;
  };
  dart.fn(rewrite_variable_initializer_test.baz, dynamicTodynamic());
  rewrite_variable_initializer_test.main = function() {
    expect$.Expect.equals(0, rewrite_variable_initializer_test.foo(0));
    expect$.Expect.equals(1000, rewrite_variable_initializer_test.foo(5));
    expect$.Expect.equals(1020, rewrite_variable_initializer_test.foo(15));
    expect$.Expect.equals(20, dart.dload(rewrite_variable_initializer_test.baz(20), 'field'));
    expect$.Expect.equals(30, dart.dload(rewrite_variable_initializer_test.baz(30), 'field'));
  };
  dart.fn(rewrite_variable_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_variable_initializer_test = rewrite_variable_initializer_test;
});

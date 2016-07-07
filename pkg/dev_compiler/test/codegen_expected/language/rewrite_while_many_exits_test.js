dart_library.library('language/rewrite_while_many_exits_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_while_many_exits_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_while_many_exits_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  rewrite_while_many_exits_test.baz_clicks = 0;
  rewrite_while_many_exits_test.baz = function() {
    return rewrite_while_many_exits_test.baz_clicks = dart.notNull(rewrite_while_many_exits_test.baz_clicks) + 1;
  };
  dart.fn(rewrite_while_many_exits_test.baz, VoidTodynamic());
  rewrite_while_many_exits_test.global = 0;
  rewrite_while_many_exits_test.increment_global = function() {
    rewrite_while_many_exits_test.global = dart.notNull(rewrite_while_many_exits_test.global) + 1;
    return dart.notNull(rewrite_while_many_exits_test.global) <= 10;
  };
  dart.fn(rewrite_while_many_exits_test.increment_global, VoidTodynamic());
  rewrite_while_many_exits_test.foo = function(x, y) {
    let n = 0;
    while (true) {
      rewrite_while_many_exits_test.baz();
      if (n >= dart.notNull(core.num._check(x))) {
        return n;
      }
      rewrite_while_many_exits_test.baz();
      if (n >= dart.notNull(core.num._check(y))) {
        return n;
      }
      n = n + 1;
    }
  };
  dart.fn(rewrite_while_many_exits_test.foo, dynamicAnddynamicTodynamic());
  rewrite_while_many_exits_test.bar = function() {
    while (dart.test(rewrite_while_many_exits_test.increment_global())) {
      rewrite_while_many_exits_test.baz();
    }
    return rewrite_while_many_exits_test.baz();
  };
  dart.fn(rewrite_while_many_exits_test.bar, VoidTodynamic());
  rewrite_while_many_exits_test.main = function() {
    expect$.Expect.equals(10, rewrite_while_many_exits_test.foo(10, 20));
    expect$.Expect.equals(10, rewrite_while_many_exits_test.foo(20, 10));
    rewrite_while_many_exits_test.baz_clicks = 0;
    expect$.Expect.equals(11, rewrite_while_many_exits_test.bar());
  };
  dart.fn(rewrite_while_many_exits_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_while_many_exits_test = rewrite_while_many_exits_test;
});

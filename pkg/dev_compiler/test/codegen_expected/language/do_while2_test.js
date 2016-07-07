dart_library.library('language/do_while2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__do_while2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const do_while2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  do_while2_test.a = 42;
  do_while2_test.foo1 = function() {
    let i = 0;
    let saved = null;
    do {
      saved = i;
      i = do_while2_test.a;
    } while (dart.equals(i, saved));
    expect$.Expect.equals(0, saved);
    expect$.Expect.equals(42, i);
  };
  dart.fn(do_while2_test.foo1, VoidTodynamic());
  do_while2_test.foo2 = function() {
    let i = 0;
    let saved = null;
    do {
      saved = i;
      i = do_while2_test.a;
    } while (!dart.equals(i, saved));
    expect$.Expect.equals(42, saved);
    expect$.Expect.equals(42, i);
  };
  dart.fn(do_while2_test.foo2, VoidTodynamic());
  do_while2_test.foo3 = function() {
    let i = 0;
    let saved = null;
    do {
      saved = i;
      i = do_while2_test.a;
      if (dart.equals(i, saved)) continue;
    } while (!dart.equals(i, saved));
    expect$.Expect.equals(42, saved);
    expect$.Expect.equals(42, i);
  };
  dart.fn(do_while2_test.foo3, VoidTodynamic());
  do_while2_test.main = function() {
    do_while2_test.foo1();
    do_while2_test.foo2();
    do_while2_test.foo3();
  };
  dart.fn(do_while2_test.main, VoidTodynamic());
  // Exports:
  exports.do_while2_test = do_while2_test;
});

dart_library.library('language/lazy_static4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_static4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_static4_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(lazy_static4_test, {
    get x() {
      return lazy_static4_test.foo(499);
    }
  });
  dart.defineLazy(lazy_static4_test, {
    get y() {
      return dart.dsend(lazy_static4_test.foo(41), '+', 1);
    }
  });
  dart.defineLazy(lazy_static4_test, {
    get t() {
      return lazy_static4_test.bar(499);
    }
  });
  dart.defineLazy(lazy_static4_test, {
    get u() {
      return dart.dsend(lazy_static4_test.bar(41), '+', 1);
    }
  });
  dart.defineLazy(lazy_static4_test, {
    get v() {
      return lazy_static4_test.bar("some string");
    }
  });
  lazy_static4_test.foo = function(x) {
    return x;
  };
  dart.fn(lazy_static4_test.foo, dynamicTodynamic());
  lazy_static4_test.bar = function(x) {
    return x;
  };
  dart.fn(lazy_static4_test.bar, dynamicTodynamic());
  lazy_static4_test.main = function() {
    expect$.Expect.equals(499, lazy_static4_test.x);
    expect$.Expect.equals(42, lazy_static4_test.y);
    expect$.Expect.equals(499, lazy_static4_test.t);
    expect$.Expect.equals(42, lazy_static4_test.u);
    expect$.Expect.equals("some string", lazy_static4_test.v);
  };
  dart.fn(lazy_static4_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_static4_test = lazy_static4_test;
});

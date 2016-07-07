dart_library.library('language/lazy_static3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_static3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_static3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  dart.defineLazy(lazy_static3_test, {
    get x() {
      return lazy_static3_test.foo();
    }
  });
  dart.defineLazy(lazy_static3_test, {
    get x2() {
      return lazy_static3_test.foo2();
    },
    set x2(_) {}
  });
  dart.defineLazy(lazy_static3_test, {
    get x3() {
      return lazy_static3_test.foo3();
    },
    set x3(_) {}
  });
  dart.defineLazy(lazy_static3_test, {
    get x4() {
      return lazy_static3_test.foo4();
    },
    set x4(_) {}
  });
  dart.defineLazy(lazy_static3_test, {
    get x5() {
      return lazy_static3_test.foo5();
    },
    set x5(_) {}
  });
  dart.defineLazy(lazy_static3_test, {
    get x6() {
      return lazy_static3_test.foo6();
    }
  });
  dart.defineLazy(lazy_static3_test, {
    get x7() {
      return dart.dsend(lazy_static3_test.x7, '+', 1);
    },
    set x7(_) {}
  });
  lazy_static3_test.foo = function() {
    dart.throw("interrupt initialization");
  };
  dart.fn(lazy_static3_test.foo, VoidTodynamic());
  lazy_static3_test.foo2 = function() {
    lazy_static3_test.x2 = 499;
    dart.throw("interrupt initialization");
  };
  dart.fn(lazy_static3_test.foo2, VoidTodynamic());
  lazy_static3_test.foo3 = function() {
    return dart.dsend(lazy_static3_test.x3, '+', 1);
  };
  dart.fn(lazy_static3_test.foo3, VoidTodynamic());
  lazy_static3_test.foo4 = function() {
    lazy_static3_test.x4 = 498;
    lazy_static3_test.x4 = dart.dsend(lazy_static3_test.x4, '+', 1);
    return lazy_static3_test.x4;
  };
  dart.fn(lazy_static3_test.foo4, VoidTodynamic());
  lazy_static3_test.foo5 = function() {
    lazy_static3_test.x5 = 498;
    lazy_static3_test.x5 = dart.dsend(lazy_static3_test.x5, '+', 1);
  };
  dart.fn(lazy_static3_test.foo5, VoidTodynamic());
  lazy_static3_test.foo6 = function() {
    try {
      return dart.dsend(lazy_static3_test.x5, '+', 1);
    } catch (e) {
      return 499;
    }

  };
  dart.fn(lazy_static3_test.foo6, VoidTodynamic());
  lazy_static3_test.fib = function(x) {
    if (!(typeof x == 'number')) return 0;
    if (dart.test(dart.dsend(x, '<', 2))) return x;
    return dart.dsend(lazy_static3_test.fib(dart.dsend(x, '-', 1)), '+', lazy_static3_test.fib(dart.dsend(x, '-', 2)));
  };
  dart.fn(lazy_static3_test.fib, dynamicTodynamic());
  lazy_static3_test.main = function() {
    expect$.Expect.throws(dart.fn(() => lazy_static3_test.fib(lazy_static3_test.x), VoidTovoid()), dart.fn(e => dart.equals(e, "interrupt initialization"), dynamicTobool()));
    expect$.Expect.equals(null, lazy_static3_test.x);
    expect$.Expect.throws(dart.fn(() => lazy_static3_test.fib(lazy_static3_test.x2), VoidTovoid()), dart.fn(e => dart.equals(e, "interrupt initialization"), dynamicTobool()));
    expect$.Expect.equals(null, lazy_static3_test.x2);
    expect$.Expect.throws(dart.fn(() => lazy_static3_test.fib(lazy_static3_test.x3), VoidTovoid()), dart.fn(e => core.CyclicInitializationError.is(e), dynamicTobool()));
    expect$.Expect.equals(null, lazy_static3_test.x3);
    expect$.Expect.equals(499, lazy_static3_test.x4);
    expect$.Expect.equals(null, lazy_static3_test.x5);
    expect$.Expect.equals(499, lazy_static3_test.x6);
    expect$.Expect.throws(dart.fn(() => lazy_static3_test.fib(lazy_static3_test.x7), VoidTovoid()), dart.fn(e => core.CyclicInitializationError.is(e), dynamicTobool()));
  };
  dart.fn(lazy_static3_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_static3_test = lazy_static3_test;
});

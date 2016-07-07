dart_library.library('language/lazy_static_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lazy_static_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lazy_static_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  dart.defineLazy(lazy_static_test, {
    get x() {
      return lazy_static_test.foo();
    }
  });
  dart.defineLazy(lazy_static_test, {
    get y() {
      return dart.dcall(lazy_static_test.y2, lazy_static_test.y3);
    }
  });
  dart.defineLazy(lazy_static_test, {
    get y2() {
      return lazy_static_test.incrementCreator();
    }
  });
  dart.defineLazy(lazy_static_test, {
    get y3() {
      return lazy_static_test.fib(5);
    }
  });
  lazy_static_test.foo = function() {
    return 499;
  };
  dart.fn(lazy_static_test.foo, VoidTodynamic());
  lazy_static_test.incrementCreator = function() {
    return dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic());
  };
  dart.fn(lazy_static_test.incrementCreator, VoidTodynamic());
  lazy_static_test.fib = function(x) {
    if (dart.test(dart.dsend(x, '<', 2))) return x;
    return dart.dsend(lazy_static_test.fib(dart.dsend(x, '-', 1)), '+', lazy_static_test.fib(dart.dsend(x, '-', 2)));
  };
  dart.fn(lazy_static_test.fib, dynamicTodynamic());
  lazy_static_test.count = 0;
  lazy_static_test.sideEffect = function() {
    return (() => {
      let x = lazy_static_test.count;
      lazy_static_test.count = dart.notNull(x) + 1;
      return x;
    })();
  };
  dart.fn(lazy_static_test.sideEffect, VoidTodynamic());
  dart.defineLazy(lazy_static_test, {
    get t() {
      return lazy_static_test.sideEffect();
    }
  });
  dart.defineLazy(lazy_static_test, {
    get t2() {
      return lazy_static_test.sideEffect();
    },
    set t2(_) {}
  });
  lazy_static_test.A = class A extends core.Object {
    static toto() {
      return 666;
    }
    static decrementCreator() {
      return dart.fn(x => dart.dsend(x, '-', 1), dynamicTodynamic());
    }
    static fact(x) {
      if (dart.test(dart.dsend(x, '<=', 1))) return x;
      return dart.dsend(x, '*', lazy_static_test.A.fact(dart.dsend(x, '-', 1)));
    }
  };
  dart.setSignature(lazy_static_test.A, {
    statics: () => ({
      toto: dart.definiteFunctionType(dart.dynamic, []),
      decrementCreator: dart.definiteFunctionType(dart.dynamic, []),
      fact: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    }),
    names: ['toto', 'decrementCreator', 'fact']
  });
  dart.defineLazy(lazy_static_test.A, {
    get a() {
      return lazy_static_test.A.toto();
    },
    get b() {
      return dart.dcall(lazy_static_test.A.b2, lazy_static_test.A.b3);
    },
    get b2() {
      return lazy_static_test.A.decrementCreator();
    },
    get b3() {
      return lazy_static_test.A.fact(5);
    }
  });
  lazy_static_test.main = function() {
    expect$.Expect.equals(499, lazy_static_test.x);
    expect$.Expect.equals(6, lazy_static_test.y);
    expect$.Expect.equals(666, lazy_static_test.A.a);
    expect$.Expect.equals(119, lazy_static_test.A.b);
    expect$.Expect.equals(0, lazy_static_test.t);
    lazy_static_test.t2 = 499;
    expect$.Expect.equals(499, lazy_static_test.t2);
    expect$.Expect.equals(1, lazy_static_test.count);
  };
  dart.fn(lazy_static_test.main, VoidTodynamic());
  // Exports:
  exports.lazy_static_test = lazy_static_test;
});

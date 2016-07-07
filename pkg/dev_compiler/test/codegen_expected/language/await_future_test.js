dart_library.library('language/await_future_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__await_future_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const await_future_test = Object.create(null);
  let FutureOfint = () => (FutureOfint = dart.constFn(async.Future$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidToFutureOfint = () => (VoidToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [])))();
  let intAndintTodynamic = () => (intAndintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, core.int])))();
  let dynamicToFuture = () => (dynamicToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [dart.dynamic])))();
  await_future_test.bar = function(p) {
    return dart.async(function*(p) {
      return p;
    }, dart.dynamic, p);
  };
  dart.fn(await_future_test.bar, dynamicTodynamic());
  await_future_test.baz = function(p) {
    return async.Future.new(dart.fn(() => p, VoidTodynamic()));
  };
  dart.fn(await_future_test.baz, dynamicTodynamic());
  await_future_test.foo = function() {
    return dart.async(function*() {
      let b = 0;
      for (let i = 0; i < 10; i++) {
        b = dart.notNull(b) + dart.notNull(core.int._check(dart.dsend(yield await_future_test.bar(1), '+', yield await_future_test.baz(2))));
      }
      return b;
    }, dart.dynamic);
  };
  dart.fn(await_future_test.foo, VoidTodynamic());
  await_future_test.faa = function() {
    return dart.async(function*() {
      return dart.dload(yield await_future_test.bar('faa'), 'length');
    }, dart.dynamic);
  };
  dart.fn(await_future_test.faa, VoidTodynamic());
  await_future_test.quaz = function(p) {
    return dart.async(function*(p) {
      let x = 0;
      try {
        for (let j = 0; j < 10; j++) {
          x = dart.notNull(x) + dart.notNull(core.int._check(yield await_future_test.baz(j)));
        }
        return x;
      } finally {
        expect$.Expect.equals(x, 45);
        return p;
      }
    }, dart.dynamic, p);
  };
  dart.fn(await_future_test.quaz, dynamicTodynamic());
  await_future_test.quazz = function() {
    return dart.async(function*() {
      let x = 0;
      try {
        try {
          x = core.int._check(yield await_future_test.bar(1));
          dart.throw(x);
        } catch (e1) {
          let y = (yield await_future_test.baz(dart.dsend(e1, '+', 1)));
          dart.throw(y);
        }

      } catch (e2) {
        return e2;
      }

    }, dart.dynamic);
  };
  dart.fn(await_future_test.quazz, VoidTodynamic());
  await_future_test.nesting = function() {
    return dart.async(function*() {
      try {
        try {
          let x = 1;
          let y = dart.fn(() => dart.async(function*() {
            try {
              let z = dart.dsend(yield await_future_test.bar(3), '+', x);
              dart.throw(z);
            } catch (e1) {
              return e1;
            }

          }, dart.dynamic), VoidToFuture());
          let a = (yield y());
          dart.throw(a);
        } catch (e2) {
          dart.throw(dart.dsend(e2, '+', 1));
        }

      } catch (e3) {
        return e3;
      }

    }, dart.dynamic);
  };
  dart.fn(await_future_test.nesting, VoidTodynamic());
  await_future_test.awaitAsUnary = function(a, b) {
    return dart.async(function*(a, b) {
      return dart.dsend(yield a, '+', yield b);
    }, dart.dynamic, a, b);
  };
  dart.fn(await_future_test.awaitAsUnary, dynamicAnddynamicTodynamic());
  await_future_test.awaitIf = function(p) {
    return dart.async(function*(p) {
      if (dart.test(dart.dsend(p, '<', yield await_future_test.bar(5)))) {
        return "p<5";
      } else {
        return "p>=5";
      }
    }, dart.dynamic, p);
  };
  dart.fn(await_future_test.awaitIf, dynamicTodynamic());
  await_future_test.awaitNestedIf = function(p, q) {
    return dart.async(function*(p, q) {
      if (dart.equals(p, yield await_future_test.bar(5))) {
        if (dart.test(dart.dsend(q, '<', yield await_future_test.bar(7)))) {
          return "q<7";
        } else {
          return "q>=7";
        }
      } else {
        return "p!=5";
      }
      return "!";
    }, dart.dynamic, p, q);
  };
  dart.fn(await_future_test.awaitNestedIf, dynamicAnddynamicTodynamic());
  await_future_test.awaitElseIf = function(p) {
    return dart.async(function*(p) {
      if (dart.test(dart.dsend(p, '>', yield await_future_test.bar(5)))) {
        return "p>5";
      } else if (dart.test(dart.dsend(p, '<', yield await_future_test.bar(5)))) {
        return "p<5";
      } else {
        return "p==5";
      }
      return "!";
    }, dart.dynamic, p);
  };
  dart.fn(await_future_test.awaitElseIf, dynamicTodynamic());
  await_future_test.awaitReturn = function() {
    return dart.async(function*() {
      return yield await_future_test.bar(17);
    }, dart.dynamic);
  };
  dart.fn(await_future_test.awaitReturn, VoidTodynamic());
  await_future_test.awaitSwitch = function() {
    return dart.async(function*() {
      switch (yield await_future_test.bar(3)) {
        case 1:
        {
          return 1;
          break;
        }
        case 3:
        {
          return 3;
          break;
        }
        default:
        {
          return -1;
        }
      }
    }, dart.dynamic);
  };
  dart.fn(await_future_test.awaitSwitch, VoidTodynamic());
  await_future_test.awaitNestedWhile = function(i, j) {
    return dart.async(function*(i, j) {
      let savedJ = j;
      let decI = dart.fn(() => dart.async(function*() {
        let x = i;
        i = dart.notNull(x) - 1;
        return x;
      }, core.int), VoidToFutureOfint());
      let decJ = dart.fn(() => dart.async(function*() {
        let x = j;
        j = dart.notNull(x) - 1;
        return x;
      }, core.int), VoidToFutureOfint());
      let k = 0;
      while (dart.notNull(yield decI()) > 0) {
        j = savedJ;
        while (0 < dart.notNull(yield decJ())) {
          k++;
        }
      }
      return k;
    }, dart.dynamic, i, j);
  };
  dart.fn(await_future_test.awaitNestedWhile, intAndintTodynamic());
  await_future_test.awaitNestedDoWhile = function(i, j) {
    return dart.async(function*(i, j) {
      let savedJ = j;
      let decI = dart.fn(() => dart.async(function*() {
        let x = i;
        i = dart.notNull(x) - 1;
        return x;
      }, core.int), VoidToFutureOfint());
      let decJ = dart.fn(() => dart.async(function*() {
        let x = j;
        j = dart.notNull(x) - 1;
        return x;
      }, core.int), VoidToFutureOfint());
      let k = 0;
      do {
        do {
          k++;
        } while (0 < dart.notNull(yield decI()));
      } while (dart.notNull(yield decJ()) > 0);
      return k;
    }, dart.dynamic, i, j);
  };
  dart.fn(await_future_test.awaitNestedDoWhile, intAndintTodynamic());
  await_future_test.awaitFor = function() {
    return dart.async(function*() {
      let asyncInc = dart.fn(p => dart.async(function*(p) {
        return dart.dsend(p, '+', 1);
      }, dart.dynamic, p), dynamicToFuture());
      let k = 0;
      for (let j = core.int._check(yield await_future_test.bar(0)), i = core.int._check(yield await_future_test.bar(1)); dart.notNull(j) < dart.notNull(core.num._check(yield await_future_test.bar(5))); j = core.int._check(yield dart.dcall(asyncInc, j)), i = core.int._check(yield dart.dcall(asyncInc, i))) {
        k = dart.notNull(k) + dart.notNull(i);
        k = dart.notNull(k) + dart.notNull(j);
      }
      return k;
    }, dart.dynamic);
  };
  dart.fn(await_future_test.awaitFor, VoidTodynamic());
  await_future_test.awaitForIn = function() {
    return dart.async(function*() {
      let list = JSArrayOfString().of(['a', 'b', 'c']);
      let k = '';
      for (let c of core.Iterable._check(yield await_future_test.bar(list))) {
        k = dart.notNull(k) + dart.notNull(core.String._check(c));
      }
      return k;
    }, dart.dynamic);
  };
  dart.fn(await_future_test.awaitForIn, VoidTodynamic());
  await_future_test.test = function() {
    return dart.async(function*() {
      let result = null;
      for (let i = 0; i < 10; i++) {
        result = (yield await_future_test.foo());
        expect$.Expect.equals(30, result);
        result = (yield await_future_test.faa());
        expect$.Expect.equals(3, result);
        result = (yield await_future_test.quaz(17));
        expect$.Expect.equals(17, result);
        result = (yield await_future_test.quazz());
        expect$.Expect.equals(2, result);
        result = (yield await_future_test.nesting());
        expect$.Expect.equals(5, result);
        result = (yield await_future_test.awaitIf(3));
        expect$.Expect.equals("p<5", result);
        result = (yield await_future_test.awaitIf(5));
        expect$.Expect.equals("p>=5", result);
        result = (yield await_future_test.awaitNestedIf(5, 3));
        expect$.Expect.equals("q<7", result);
        result = (yield await_future_test.awaitNestedIf(5, 8));
        expect$.Expect.equals("q>=7", result);
        result = (yield await_future_test.awaitNestedIf(3, 8));
        expect$.Expect.equals("p!=5", result);
        result = (yield await_future_test.awaitReturn());
        expect$.Expect.equals(17, result);
        result = (yield await_future_test.awaitSwitch());
        expect$.Expect.equals(3, result);
        result = (yield await_future_test.awaitElseIf(6));
        expect$.Expect.equals("p>5", result);
        result = (yield await_future_test.awaitElseIf(4));
        expect$.Expect.equals("p<5", result);
        result = (yield await_future_test.awaitElseIf(5));
        expect$.Expect.equals("p==5", result);
        result = (yield await_future_test.awaitNestedWhile(5, 3));
        expect$.Expect.equals(15, result);
        result = (yield await_future_test.awaitNestedWhile(4, 6));
        expect$.Expect.equals(24, result);
        result = (yield await_future_test.awaitAsUnary(await_future_test.bar(1), await_future_test.bar(2)));
        expect$.Expect.equals(3, result);
        result = (yield await_future_test.awaitFor());
        expect$.Expect.equals(25, result);
        result = (yield await_future_test.awaitForIn());
        expect$.Expect.equals('abc', result);
      }
    }, dart.dynamic);
  };
  dart.fn(await_future_test.test, VoidTodynamic());
  await_future_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(await_future_test.test(), 'then', dart.fn(_ => {
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(await_future_test.main, VoidTodynamic());
  // Exports:
  exports.await_future_test = await_future_test;
});

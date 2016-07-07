dart_library.library('language/async_star_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__async_star_test_01_multi(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__numeric_matchers = unittest.src__matcher__numeric_matchers;
  const async_star_test_01_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let FutureOfObject = () => (FutureOfObject = dart.constFn(async.Future$(core.Object)))();
  let StreamOfObject = () => (StreamOfObject = dart.constFn(async.Stream$(core.Object)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToObject = () => (VoidToObject = dart.constFn(dart.definiteFunctionType(core.Object, [])))();
  let VoidToFutureOfObject = () => (VoidToFutureOfObject = dart.constFn(dart.definiteFunctionType(FutureOfObject(), [])))();
  let VoidToStreamOfObject = () => (VoidToStreamOfObject = dart.constFn(dart.definiteFunctionType(StreamOfObject(), [])))();
  let dynamicToFuture = () => (dynamicToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicAndEventSinkTovoid = () => (dynamicAndEventSinkTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, async.EventSink])))();
  let ObjectAndStackTraceAndEventSinkTovoid = () => (ObjectAndStackTraceAndEventSinkTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Object, core.StackTrace, async.EventSink])))();
  let EventSinkTovoid = () => (EventSinkTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [async.EventSink])))();
  async_star_test_01_multi.main = function() {
    unittest$.group("basic", dart.fn(() => {
      unittest$.test("empty", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dsend(f(), 'toList'), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals([]));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("single", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(42)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dsend(f(), 'toList'), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals(JSArrayOfint().of([42])));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("call delays", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            list[dartx.add](1);
            if (stream.add(2)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        let res = dart.dsend(f(), 'forEach', dart.fn(x => list[dartx.add](x), dynamicTovoid()));
        list[dartx.add](0);
        return dart.dsend(res, 'whenComplete', dart.fn(() => {
          src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([0, 1, 2])));
        }, VoidTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("throws", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(1)) return;
            yield;
            dart.throw(2);
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        let completer = async.Completer.new();
        let list = [];
        dart.dsend(f(), 'listen', dart.fn(x => list[dartx.add](x), dynamicTovoid()), {onError: dart.fn(v => list[dartx.add](dart.str`${v}`), dynamicTovoid()), onDone: dart.bind(completer, 'complete')});
        return completer.future.whenComplete(dart.fn(() => {
          src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfObject().of([1, "2"])));
        }, VoidTodynamic()));
      }, VoidToFuture()));
      unittest$.test("multiple", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 10; i++) {
              if (stream.add(i)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), core.List.generate(10, async_star_test_01_multi.id));
      }, VoidTodynamic()));
      unittest$.test("allows await", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = (yield async.Future.value(42));
            if (stream.add(x)) return;
            yield;
            x = (yield async.Future.value(42));
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("allows await in loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 10; i++) {
              if (stream.add(yield i)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), core.List.generate(10, async_star_test_01_multi.id));
      }, VoidTodynamic()));
      unittest$.test("allows yield*", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.addStream(async.Stream.fromIterable(JSArrayOfint().of([1, 2, 3])))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([1, 2, 3]));
      }, VoidTodynamic()));
      unittest$.test("allows yield* of async*", dart.fn(() => {
        function f(n) {
          return dart.asyncStar(function*(stream, n) {
            if (stream.add(n)) return;
            yield;
            if (dart.equals(n, 0)) return;
            if (stream.addStream(async.Stream._check(f(dart.dsend(n, '-', 1))))) return;
            yield;
            if (stream.add(n)) return;
            yield;
          }, dart.dynamic, n);
        }
        dart.fn(f, dynamicTodynamic());
        return async_star_test_01_multi.expectList(f(3), JSArrayOfint().of([3, 2, 1, 0, 1, 2, 3]));
      }, VoidTodynamic()));
      unittest$.test("Cannot yield* non-stream", dart.fn(() => {
        function f(s) {
          return dart.asyncStar(function*(stream, s) {
            if (stream.addStream(async.Stream._check(s))) return;
            yield;
          }, dart.dynamic, s);
        }
        dart.fn(f, dynamicTodynamic());
        return dart.dsend(dart.dload(dart.dsend(f(42), 'transform', async_star_test_01_multi.getErrors), 'single'), 'then', dart.fn(v => {
          src__matcher__expect.expect(core.Error.is(v), src__matcher__core_matchers.isTrue);
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("Cannot yield* non-stream", dart.fn(() => {
        function f(s) {
          return dart.asyncStar(function*(stream, s) {
            if (stream.addStream(async.Stream._check(s))) return;
            yield;
          }, dart.dynamic, s);
        }
        dart.fn(f, dynamicTodynamic());
        return dart.dsend(dart.dload(dart.dsend(f(new async_star_test_01_multi.NotAStream()), 'transform', async_star_test_01_multi.getErrors), 'single'), 'then', dart.fn(v => {
          src__matcher__expect.expect(core.Error.is(v), src__matcher__core_matchers.isTrue);
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group("yield statement context", dart.fn(() => {
      unittest$.test("plain", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(0)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0]));
      }, VoidTodynamic()));
      unittest$.test("if-then-else", dart.fn(() => {
        function f(b) {
          return dart.asyncStar(function*(stream, b) {
            if (dart.test(b)) {
              if (stream.add(0)) return;
              yield;
            } else {
              if (stream.add(1)) return;
              yield;
            }
          }, dart.dynamic, b);
        }
        dart.fn(f, dynamicTodynamic());
        return dart.dsend(async_star_test_01_multi.expectList(f(true), JSArrayOfint().of([0])), 'whenComplete', dart.fn(() => {
          async_star_test_01_multi.expectList(f(false), JSArrayOfint().of([1]));
        }, VoidTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("block", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(0)) return;
            yield;
            {
              if (stream.add(1)) return;
              yield;
            }
            if (stream.add(2)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("labeled", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            label1: {
              if (stream.add(0)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0]));
      }, VoidTodynamic()));
      unittest$.test("labeled 2", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            label1:
              label2: {
                if (stream.add(0)) return;
                yield;
              }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0]));
      }, VoidTodynamic()));
      unittest$.test("for-loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 3; i++) {
              if (stream.add(i)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("for-in-loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i of JSArrayOfint().of([0, 1, 2])) {
              if (stream.add(i)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("await for-in-loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let it = async.StreamIterator.new(async.Stream.fromIterable(JSArrayOfint().of([0, 1, 2])));
            try {
              while (yield it.moveNext()) {
                let i = it.current;
                if (stream.add(i)) return;
                yield;
              }
            } finally {
              yield it.cancel();
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("while-loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let i = 0;
            while (i < 3) {
              if (stream.add(i++)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("do-while-loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let i = 0;
            do {
              if (stream.add(i++)) return;
              yield;
            } while (i < 3);
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("try-catch-finally", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            try {
              if (stream.add(0)) return;
              yield;
            } catch (e) {
              if (stream.add(1)) return;
              yield;
            }
 finally {
              if (stream.add(2)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 2]));
      }, VoidTodynamic()));
      unittest$.test("try-catch-finally 2", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            try {
              if (stream.add(dart.throw(0))) return;
              yield;
            } catch (e) {
              if (stream.add(1)) return;
              yield;
            }
 finally {
              if (stream.add(2)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([1, 2]));
      }, VoidTodynamic()));
      unittest$.test("dead-code return", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            return;
            if (stream.add(1)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), []);
      }, VoidTodynamic()));
      unittest$.test("dead-code throw", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            try {
              dart.throw(0);
              if (stream.add(1)) return;
              yield;
            } catch (_) {
            }

          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), []);
      }, VoidTodynamic()));
      unittest$.test("dead-code break", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            while (true) {
              break;
              if (stream.add(1)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), []);
      }, VoidTodynamic()));
      unittest$.test("dead-code break 2", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            label: {
              break label;
              if (stream.add(1)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), []);
      }, VoidTodynamic()));
      unittest$.test("dead-code continue", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            do {
              continue;
              if (stream.add(1)) return;
              yield;
            } while (false);
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), []);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group("yield expressions", dart.fn(() => {
      unittest$.test("local variable", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 42;
            if (stream.add(x)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("constant variable", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 42;
            if (stream.add(x)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("function call", dart.fn(() => {
        function g() {
          return 42;
        }
        dart.fn(g, VoidTodynamic());
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(g())) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("unary operator", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = -42;
            if (stream.add(-x)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("binary operator", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 21;
            if (stream.add(x + x)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("ternary operator", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 21;
            if (stream.add(x == 21 ? x + x : x)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("suffix post-increment", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 42;
            if (stream.add(x++)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("suffix pre-increment", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 41;
            if (stream.add(++x)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("assignment", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 37;
            if (stream.add(x = 42)) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("assignment op", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = 41;
            if (stream.add((x = x + 1))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("await", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(yield async.Future.value(42))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("index operator", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            let x = JSArrayOfint().of([42]);
            if (stream.add(x[dartx.get](0))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([42]));
      }, VoidTodynamic()));
      unittest$.test("function expression block", dart.fn(() => {
        let o = new core.Object();
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(dart.fn(() => o, VoidToObject()))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dload(f(), 'first'), 'then', dart.fn(v => {
          src__matcher__expect.expect(dart.dcall(v), src__matcher__core_matchers.same(o));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("function expression arrow", dart.fn(() => {
        let o = new core.Object();
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(dart.fn(() => o, VoidToObject()))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dload(f(), 'first'), 'then', dart.fn(v => {
          src__matcher__expect.expect(dart.dcall(v), src__matcher__core_matchers.same(o));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("function expression block async", dart.fn(() => {
        let o = new core.Object();
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(dart.fn(() => dart.async(function*() {
              return o;
            }, core.Object), VoidToFutureOfObject()))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dsend(dart.dload(f(), 'first'), 'then', dart.fn(v => dart.dcall(v), dynamicTodynamic())), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.same(o));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("function expression arrow async", dart.fn(() => {
        let o = new core.Object();
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(dart.fn(() => dart.async(function*() {
              return o;
            }, core.Object), VoidToFutureOfObject()))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dsend(dart.dload(f(), 'first'), 'then', dart.fn(v => dart.dcall(v), dynamicTodynamic())), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.same(o));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("function expression block async*", dart.fn(() => {
        let o = new core.Object();
        function f() {
          return dart.asyncStar(function*(stream) {
            if (stream.add(dart.fn(() => dart.asyncStar(function*(stream) {
              if (stream.add(o)) return;
              yield;
            }, core.Object), VoidToStreamOfObject()))) return;
            yield;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dsend(dart.dload(f(), 'first'), 'then', dart.fn(v => dart.dload(dart.dcall(v), 'first'), dynamicTodynamic())), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.same(o));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group("loops", dart.fn(() => {
      unittest$.test("simple yield", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 3; i++) {
              if (stream.add(i)) return;
              yield;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
      unittest$.test("yield in double loop", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 3; i++) {
              for (let j = 0; j < 2; j++) {
                if (stream.add(i * 2 + j)) return;
                yield;
              }
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2, 3, 4, 5]));
      }, VoidTodynamic()));
      unittest$.test("yield in try body", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 3; i++) {
              try {
                if (stream.add(i)) return;
                yield;
              } finally {
                list[dartx.add](dart.str`${i}`);
              }
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2])), 'whenComplete', dart.fn(() => {
          src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfString().of(["0", "1", "2"])));
        }, VoidTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("yield in catch", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 3; i++) {
              try {
                dart.throw(i);
              } catch (e) {
                if (stream.add(e)) return;
                yield;
              }
 finally {
                list[dartx.add](dart.str`${i}`);
              }
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2])), 'whenComplete', dart.fn(() => {
          src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfString().of(["0", "1", "2"])));
        }, VoidTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("yield in finally", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 3; i++) {
              try {
                dart.throw(i);
              } finally {
                if (stream.add(i)) return;
                yield;
                list[dartx.add](dart.str`${i}`);
                continue;
              }
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(async_star_test_01_multi.expectList(f(), JSArrayOfint().of([0, 1, 2])), 'whenComplete', dart.fn(() => {
          src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfString().of(["0", "1", "2"])));
        }, VoidTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("keep yielding after cancel", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            for (let i = 0; i < 10; i++) {
              try {
                if (stream.add(i)) return;
                yield;
              } finally {
                continue;
              }
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 3), JSArrayOfint().of([0, 1, 2]));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group("canceling", dart.fn(() => {
      unittest$.test("cancels at yield", dart.fn(() => {
        let exits = async.Completer.new();
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            try {
              list[dartx.add](0);
              if (stream.add(list[dartx.add](1))) return;
              yield;
              list[dartx.add](2);
            } finally {
              exits.complete(3);
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        let subscription = dart.dsend(f(), 'listen', dart.fn(v => {
          src__matcher__expect.fail(dart.str`Received event ${v}`);
        }, dynamicTodynamic()), {onDone: dart.fn(() => {
            src__matcher__expect.fail("Received done");
          }, VoidTodynamic())});
        dart.dsend(subscription, 'cancel');
        return exits.future.then(dart.dynamic)(dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals(3));
          src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([0, 1])));
        }, dynamicTodynamic()));
      }, VoidToFuture()));
      unittest$.test("does cancel eventually", dart.fn(() => {
        let exits = async.Completer.new();
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            let i = 0;
            try {
              while (true) {
                if (stream.add(i++)) return;
                yield;
              }
            } finally {
              list[dartx.add]("a");
              exits.complete(i);
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(dart.dsend(async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 5), JSArrayOfint().of([0, 1, 2, 3, 4])), 'then', dart.fn(_ => exits.future, dynamicToFuture())), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__numeric_matchers.greaterThan(4));
          src__matcher__expect.expect(list, JSArrayOfString().of(["a"]));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.group("at index", dart.fn(() => {
        function f() {
          return dart.asyncStar(function*(stream) {
            try {
              if (stream.add(yield async.Future.microtask(dart.fn(() => 1, VoidToint())))) return;
              yield;
            } finally {
              try {
                if (stream.add(yield async.Future.microtask(dart.fn(() => 2, VoidToint())))) return;
                yield;
              } finally {
                if (stream.add(yield async.Future.microtask(dart.fn(() => 3, VoidToint())))) return;
                yield;
              }
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        unittest$.test("- all, sanity check", dart.fn(() => async_star_test_01_multi.expectList(f(), JSArrayOfint().of([1, 2, 3])), VoidTodynamic()));
        unittest$.test("after end", dart.fn(() => async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 4), JSArrayOfint().of([1, 2, 3])), VoidTodynamic()));
        unittest$.test("at end", dart.fn(() => async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 3), JSArrayOfint().of([1, 2, 3])), VoidTodynamic()));
        unittest$.test("before end", dart.fn(() => async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 2), JSArrayOfint().of([1, 2])), VoidTodynamic()));
        unittest$.test("early", dart.fn(() => async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 1), JSArrayOfint().of([1])), VoidTodynamic()));
        unittest$.test("at start", dart.fn(() => async_star_test_01_multi.expectList(dart.dsend(f(), 'take', 0), []), VoidTodynamic()));
      }, VoidTovoid()));
    }, VoidTovoid()));
    unittest$.group("pausing", dart.fn(() => {
      unittest$.test("pauses execution at yield for at least a microtask", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            list[dartx.add](1);
            if (stream.add(2)) return;
            yield;
            list[dartx.add](3);
            if (stream.add(4)) return;
            yield;
            list[dartx.add](5);
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        let done = async.Completer.new();
        let sub = dart.dsend(f(), 'listen', dart.fn(v => {
          if (dart.equals(v, 2)) {
            src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([1])));
          } else if (dart.equals(v, 4)) {
            src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([1, 3])));
          } else {
            src__matcher__expect.fail(dart.str`Unexpected value ${v}`);
          }
        }, dynamicTodynamic()), {onDone: dart.fn(() => {
            src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([1, 3, 5])));
            done.complete();
          }, VoidTodynamic())});
        return done.future;
      }, VoidToFuture()));
      unittest$.test("pause stops execution at yield", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            list[dartx.add](1);
            if (stream.add(2)) return;
            yield;
            list[dartx.add](3);
            if (stream.add(4)) return;
            yield;
            list[dartx.add](5);
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        let done = async.Completer.new();
        let sub = null;
        sub = dart.dsend(f(), 'listen', dart.fn(v => {
          if (dart.equals(v, 2)) {
            src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([1])));
            dart.dsend(sub, 'pause');
            async.Timer.new(async_star_test_01_multi.MS['*'](300), dart.fn(() => {
              src__matcher__expect.expect(list[dartx.length], src__matcher__numeric_matchers.lessThan(3));
              dart.dsend(sub, 'resume');
            }, VoidTovoid()));
          } else if (dart.equals(v, 4)) {
            src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([1, 3])));
          } else {
            src__matcher__expect.fail(dart.str`Unexpected value ${v}`);
          }
        }, dynamicTodynamic()), {onDone: dart.fn(() => {
            src__matcher__expect.expect(list, src__matcher__core_matchers.equals(JSArrayOfint().of([1, 3, 5])));
            done.complete();
          }, VoidTodynamic())});
        return done.future;
      }, VoidToFuture()));
      unittest$.test("pause stops execution at yield 2", dart.fn(() => {
        let list = [];
        function f() {
          return dart.asyncStar(function*(stream) {
            let i = 0;
            while (true) {
              if (stream.add(i)) return;
              yield;
              list[dartx.add](i);
              i++;
            }
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        let expected = 0;
        let done = async.Completer.new();
        let sub = null;
        sub = dart.dsend(f(), 'listen', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals(expected++));
          if (dart.equals(dart.dsend(v, '%', 5), 0)) {
            dart.dsend(sub, 'pause', async.Future.delayed(async_star_test_01_multi.MS['*'](300)));
          } else if (dart.equals(v, 17)) {
            dart.dsend(sub, 'cancel');
            done.complete();
          }
        }, dynamicTodynamic()), {onDone: dart.fn(() => {
            src__matcher__expect.fail("Unexpected done!");
          }, VoidTodynamic())});
        return done.future.whenComplete(dart.fn(() => {
          src__matcher__expect.expect(list[dartx.length] == 18 || list[dartx.length] == 19, src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
      }, VoidToFuture()));
    }, VoidTovoid()));
    unittest$.group("await for", dart.fn(() => {
      function mkStream(n) {
        return dart.asyncStar(function*(stream, n) {
          for (let i = 0; i < dart.notNull(n); i++) {
            if (stream.add(i)) return;
            yield;
          }
        }, dart.dynamic, n);
      }
      dart.fn(mkStream, intTodynamic());
      unittest$.test("simple stream", dart.fn(() => {
        function f(s) {
          return dart.async(function*(s) {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(s));
            try {
              while (yield it.moveNext()) {
                let v = it.current;
                r = dart.notNull(r) + dart.notNull(core.int._check(v));
              }
            } finally {
              yield it.cancel();
            }
            return r;
          }, dart.dynamic, s);
        }
        dart.fn(f, dynamicTodynamic());
        return dart.dsend(f(mkStream(5)), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals(10));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("simple stream, await", dart.fn(() => {
        function f(s) {
          return dart.async(function*(s) {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(s));
            try {
              while (yield it.moveNext()) {
                let v = it.current;
                r = dart.notNull(r) + dart.notNull(core.int._check(yield async.Future.microtask(dart.fn(() => v, VoidTodynamic()))));
              }
            } finally {
              yield it.cancel();
            }
            return r;
          }, dart.dynamic, s);
        }
        dart.fn(f, dynamicTodynamic());
        return dart.dsend(f(mkStream(5)), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals(10));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("simple stream reyield", dart.fn(() => {
        function f(s) {
          return dart.asyncStar(function*(stream, s) {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(s));
            try {
              while (yield it.moveNext()) {
                let v = it.current;
                if (stream.add((r = dart.notNull(r) + dart.notNull(core.int._check(v))))) return;
                yield;
              }
            } finally {
              yield it.cancel();
            }
          }, dart.dynamic, s);
        }
        dart.fn(f, dynamicTodynamic());
        return async_star_test_01_multi.expectList(f(mkStream(5)), JSArrayOfint().of([0, 1, 3, 6, 10]));
      }, VoidTodynamic()));
      unittest$.test("simple stream, await, reyield", dart.fn(() => {
        function f(s) {
          return dart.asyncStar(function*(stream, s) {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(s));
            try {
              while (yield it.moveNext()) {
                let v = it.current;
                if (stream.add((r = dart.notNull(r) + dart.notNull(core.int._check(yield async.Future.microtask(dart.fn(() => v, VoidTodynamic()))))))) return;
                yield;
              }
            } finally {
              yield it.cancel();
            }
          }, dart.dynamic, s);
        }
        dart.fn(f, dynamicTodynamic());
        return async_star_test_01_multi.expectList(f(mkStream(5)), JSArrayOfint().of([0, 1, 3, 6, 10]));
      }, VoidTodynamic()));
      unittest$.test("nested", dart.fn(() => {
        function f() {
          return dart.async(function*() {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(mkStream(5)));
            try {
              while (yield it.moveNext()) {
                let i = it.current;
                let it$ = async.StreamIterator.new(async.Stream._check(mkStream(3)));
                try {
                  while (yield it$.moveNext()) {
                    let j = it$.current;
                    r = dart.notNull(r) + dart.notNull(core.int._check(dart.dsend(i, '*', j)));
                  }
                } finally {
                  yield it$.cancel();
                }
              }
            } finally {
              yield it.cancel();
            }
            return r;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(f(), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals((1 + 2 + 3 + 4) * (1 + 2)));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("nested, await", dart.fn(() => {
        function f() {
          return dart.async(function*() {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(mkStream(5)));
            try {
              while (yield it.moveNext()) {
                let i = it.current;
                let it$ = async.StreamIterator.new(async.Stream._check(mkStream(3)));
                try {
                  while (yield it$.moveNext()) {
                    let j = it$.current;
                    r = dart.notNull(r) + dart.notNull(core.int._check(yield async.Future.microtask(dart.fn(() => dart.dsend(i, '*', j), VoidTodynamic()))));
                  }
                } finally {
                  yield it$.cancel();
                }
              }
            } finally {
              yield it.cancel();
            }
            return r;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(f(), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals((1 + 2 + 3 + 4) * (1 + 2)));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
      unittest$.test("nested, await * 2", dart.fn(() => {
        function f() {
          return dart.async(function*() {
            let r = 0;
            let it = async.StreamIterator.new(async.Stream._check(mkStream(5)));
            try {
              while (yield it.moveNext()) {
                let i = it.current;
                let ai = (yield async.Future.microtask(dart.fn(() => i, VoidTodynamic())));
                let it$ = async.StreamIterator.new(async.Stream._check(mkStream(3)));
                try {
                  while (yield it$.moveNext()) {
                    let j = it$.current;
                    r = dart.notNull(r) + dart.notNull(core.int._check(yield async.Future.microtask(dart.fn(() => dart.dsend(ai, '*', j), VoidTodynamic()))));
                  }
                } finally {
                  yield it$.cancel();
                }
              }
            } finally {
              yield it.cancel();
            }
            return r;
          }, dart.dynamic);
        }
        dart.fn(f, VoidTodynamic());
        return dart.dsend(f(), 'then', dart.fn(v => {
          src__matcher__expect.expect(v, src__matcher__core_matchers.equals((1 + 2 + 3 + 4) * (1 + 2)));
        }, dynamicTodynamic()));
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(async_star_test_01_multi.main, VoidTodynamic());
  async_star_test_01_multi.id = function(x) {
    try {
      if (x != null) dart.throw(x);
    } catch (e) {
      return e;
    }

    return null;
  };
  dart.fn(async_star_test_01_multi.id, dynamicTodynamic());
  async_star_test_01_multi.expectList = function(stream, list) {
    return dart.dsend(dart.dsend(stream, 'toList'), 'then', dart.fn(v => {
      src__matcher__expect.expect(v, src__matcher__core_matchers.equals(list));
    }, dynamicTodynamic()));
  };
  dart.fn(async_star_test_01_multi.expectList, dynamicAnddynamicTodynamic());
  async_star_test_01_multi.MS = dart.const(new core.Duration({milliseconds: 1}));
  dart.defineLazy(async_star_test_01_multi, {
    get getErrors() {
      return async.StreamTransformer.fromHandlers({handleData: dart.fn((data, sink) => {
          src__matcher__expect.fail("Unexpected value");
        }, dynamicAndEventSinkTovoid()), handleError: dart.fn((e, s, sink) => {
          sink.add(e);
        }, ObjectAndStackTraceAndEventSinkTovoid()), handleDone: dart.fn(sink => {
          sink.close();
        }, EventSinkTovoid())});
    },
    set getErrors(_) {}
  });
  async_star_test_01_multi.NotAStream = class NotAStream extends core.Object {
    listen(oData, opts) {
      let onError = opts && 'onError' in opts ? opts.onError : null;
      let onDone = opts && 'onDone' in opts ? opts.onDone : null;
      let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
      src__matcher__expect.fail("Not implementing Stream.");
    }
  };
  dart.setSignature(async_star_test_01_multi.NotAStream, {
    methods: () => ({listen: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {onError: dart.dynamic, onDone: dart.dynamic, cancelOnError: dart.dynamic})})
  });
  const _completer = Symbol('_completer');
  async_star_test_01_multi.Sync = class Sync extends core.Object {
    new() {
      this[_completer] = null;
    }
    wait(v) {
      if (v === void 0) v = null;
      if (this[_completer] != null) this[_completer].complete(v);
      this[_completer] = async.Completer.new();
      return this[_completer].future;
    }
    release(v) {
      if (v === void 0) v = null;
      if (this[_completer] != null) {
        this[_completer].complete(v);
        this[_completer] = null;
      }
    }
  };
  dart.setSignature(async_star_test_01_multi.Sync, {
    methods: () => ({
      wait: dart.definiteFunctionType(async.Future, [], [dart.dynamic]),
      release: dart.definiteFunctionType(dart.void, [], [dart.dynamic])
    })
  });
  // Exports:
  exports.async_star_test_01_multi = async_star_test_01_multi;
});

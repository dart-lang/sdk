dart_library.library('language/asyncstar_throw_in_catch_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__asyncstar_throw_in_catch_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const asyncstar_throw_in_catch_test = Object.create(null);
  let TracerTodynamic = () => (TracerTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [asyncstar_throw_in_catch_test.Tracer])))();
  let dynamicToFuture = () => (dynamicToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const _trace = Symbol('_trace');
  asyncstar_throw_in_catch_test.Tracer = class Tracer extends core.Object {
    new(expected, name) {
      if (name === void 0) name = null;
      this.expected = expected;
      this.name = name;
      this[_trace] = "";
      this.counter = 0;
    }
    trace(msg) {
      if (this.name != null) {
      }
      this[_trace] = dart.notNull(this[_trace]) + dart.notNull(core.String._check(msg));
      this.counter = dart.notNull(this.counter) + 1;
    }
    done() {
      expect$.Expect.equals(this.expected, this[_trace]);
    }
  };
  dart.setSignature(asyncstar_throw_in_catch_test.Tracer, {
    constructors: () => ({new: dart.definiteFunctionType(asyncstar_throw_in_catch_test.Tracer, [core.String], [core.String])}),
    methods: () => ({
      trace: dart.definiteFunctionType(dart.void, [dart.dynamic]),
      done: dart.definiteFunctionType(dart.void, [])
    })
  });
  asyncstar_throw_in_catch_test.foo1 = function(tracer) {
    return dart.asyncStar(function*(stream, tracer) {
      try {
        tracer.trace("a");
        yield async.Future.value(3);
        tracer.trace("b");
        dart.throw("Error");
      } catch (e) {
        expect$.Expect.equals("Error", e);
        tracer.trace("c");
        if (stream.add(1)) return;
        yield;
        tracer.trace("d");
        if (stream.add(2)) return;
        yield;
        tracer.trace("e");
        if (stream.add(3)) return;
        yield;
        tracer.trace("f");
      }
 finally {
        tracer.trace("f");
      }
      tracer.trace("g");
    }, dart.dynamic, tracer);
  };
  dart.fn(asyncstar_throw_in_catch_test.foo1, TracerTodynamic());
  asyncstar_throw_in_catch_test.foo2 = function(tracer) {
    return dart.asyncStar(function*(stream, tracer) {
      try {
        tracer.trace("a");
        dart.throw("Error");
      } catch (error) {
        expect$.Expect.equals("Error", error);
        tracer.trace("b");
        throw error;
      }
 finally {
        tracer.trace("c");
      }
    }, dart.dynamic, tracer);
  };
  dart.fn(asyncstar_throw_in_catch_test.foo2, TracerTodynamic());
  asyncstar_throw_in_catch_test.foo3 = function(tracer) {
    return dart.asyncStar(function*(stream, tracer) {
      try {
        tracer.trace("a");
        dart.throw("Error");
      } catch (error) {
        expect$.Expect.equals("Error", error);
        tracer.trace("b");
        throw error;
      }
 finally {
        tracer.trace("c");
        if (stream.add(1)) return;
        yield;
      }
    }, dart.dynamic, tracer);
  };
  dart.fn(asyncstar_throw_in_catch_test.foo3, TracerTodynamic());
  asyncstar_throw_in_catch_test.foo4 = function(tracer) {
    return dart.asyncStar(function*(stream, tracer) {
      try {
        tracer.trace("a");
        yield async.Future.value(3);
        tracer.trace("b");
        dart.throw("Error");
      } catch (e) {
        expect$.Expect.equals("Error", e);
        tracer.trace("c");
        if (stream.add(1)) return;
        yield;
        tracer.trace("d");
        if (stream.add(2)) return;
        yield;
        tracer.trace("e");
        yield async.Future.error("Error2");
      }
 finally {
        tracer.trace("f");
      }
      tracer.trace("g");
    }, dart.dynamic, tracer);
  };
  dart.fn(asyncstar_throw_in_catch_test.foo4, TracerTodynamic());
  asyncstar_throw_in_catch_test.runTest = function(test, expectedTrace, expectedError, shouldCancel) {
    let tracer = new asyncstar_throw_in_catch_test.Tracer(core.String._check(expectedTrace), core.String._check(expectedTrace));
    let done = async.Completer.new();
    let subscription = null;
    subscription = dart.dsend(dart.dcall(test, tracer), 'listen', dart.fn(event => dart.async(function*(event) {
      tracer.trace("Y");
      if (dart.test(shouldCancel)) {
        yield dart.dsend(subscription, 'cancel');
        tracer.trace("C");
        done.complete(null);
      }
    }, dart.dynamic, event), dynamicToFuture()), {onError: dart.fn(error => {
        expect$.Expect.equals(expectedError, error);
        tracer.trace("X");
      }, dynamicTodynamic()), onDone: dart.fn(() => {
        tracer.done();
        done.complete(null);
      }, VoidTodynamic())});
    return done.future.then(dart.dynamic)(dart.fn(_ => tracer.done(), dynamicTovoid()));
  };
  dart.fn(asyncstar_throw_in_catch_test.runTest, dynamicAnddynamicAnddynamic__Todynamic());
  asyncstar_throw_in_catch_test.test = function() {
    return dart.async(function*() {
      yield asyncstar_throw_in_catch_test.runTest(asyncstar_throw_in_catch_test.foo1, "abcdYefC", null, true);
      yield asyncstar_throw_in_catch_test.runTest(asyncstar_throw_in_catch_test.foo2, "abcX", "Error", false);
      yield asyncstar_throw_in_catch_test.runTest(asyncstar_throw_in_catch_test.foo3, "abcYX", "Error", false);
      yield asyncstar_throw_in_catch_test.runTest(asyncstar_throw_in_catch_test.foo4, "abcdYeYfX", "Error2", false);
    }, dart.dynamic);
  };
  dart.fn(asyncstar_throw_in_catch_test.test, VoidTodynamic());
  asyncstar_throw_in_catch_test.main = function() {
    async_helper$.asyncTest(asyncstar_throw_in_catch_test.test);
  };
  dart.fn(asyncstar_throw_in_catch_test.main, VoidTovoid());
  // Exports:
  exports.asyncstar_throw_in_catch_test = asyncstar_throw_in_catch_test;
});

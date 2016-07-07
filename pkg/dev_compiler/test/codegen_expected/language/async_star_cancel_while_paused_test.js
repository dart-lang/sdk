dart_library.library('language/async_star_cancel_while_paused_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__async_star_cancel_while_paused_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const async_star_cancel_while_paused_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  async_star_cancel_while_paused_test.main = function() {
    let list = [];
    let sync = new async_star_cancel_while_paused_test.Sync();
    function f() {
      return dart.asyncStar(function*(stream) {
        list[dartx.add]("*1");
        if (stream.add(1)) return;
        yield;
        yield sync.wait();
        sync.release();
        list[dartx.add]("*2");
        if (stream.add(2)) return;
        yield;
        list[dartx.add]("*3");
      }, dart.dynamic);
    }
    dart.fn(f, VoidTodynamic());
    ;
    let stream = f();
    let sub = dart.dsend(stream, 'listen', dart.bind(list, dartx.add));
    async_helper$.asyncStart();
    return sync.wait().whenComplete(dart.fn(() => {
      expect$.Expect.listEquals(list, JSArrayOfObject().of(["*1", 1]));
      dart.dsend(sub, 'pause');
      return sync.wait();
    }, VoidToFuture())).whenComplete(dart.fn(() => {
      expect$.Expect.listEquals(list, JSArrayOfObject().of(["*1", 1, "*2"]));
      dart.dsend(sub, 'cancel');
      async.Future.delayed(new core.Duration({milliseconds: 200}), dart.fn(() => {
        expect$.Expect.listEquals(list, JSArrayOfObject().of(["*1", 1, "*2"]));
        async_helper$.asyncEnd();
      }, VoidTodynamic()));
    }, VoidTodynamic()));
  };
  dart.fn(async_star_cancel_while_paused_test.main, VoidTodynamic());
  const _completer = Symbol('_completer');
  async_star_cancel_while_paused_test.Sync = class Sync extends core.Object {
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
  dart.setSignature(async_star_cancel_while_paused_test.Sync, {
    methods: () => ({
      wait: dart.definiteFunctionType(async.Future, [], [dart.dynamic]),
      release: dart.definiteFunctionType(dart.void, [], [dart.dynamic])
    })
  });
  // Exports:
  exports.async_star_cancel_while_paused_test = async_star_cancel_while_paused_test;
});

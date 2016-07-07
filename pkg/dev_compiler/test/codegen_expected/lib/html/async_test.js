dart_library.library('lib/html/async_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__async_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const isolate = dart_sdk.isolate;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__future_matchers = unittest.src__matcher__future_matchers;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const async_test = Object.create(null);
  const async_oneshot = Object.create(null);
  const async_periodictimer = Object.create(null);
  const async_cancellingisolate = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let IsolateToFuture = () => (IsolateToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [isolate.Isolate])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let TimerTovoid = () => (TimerTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [async.Timer])))();
  async_test.oneshot = function(message) {
    return async_oneshot.main(dart.dload(message, 'first'), dart.dload(message, 'last'));
  };
  dart.fn(async_test.oneshot, dynamicTodynamic());
  async_test.periodicTimerIsolate = function(message) {
    return async_periodictimer.main(dart.dload(message, 'first'), dart.dload(message, 'last'));
  };
  dart.fn(async_test.periodicTimerIsolate, dynamicTodynamic());
  async_test.cancellingIsolate = function(message) {
    return async_cancellingisolate.main(dart.dload(message, 'first'), dart.dload(message, 'last'));
  };
  dart.fn(async_test.cancellingIsolate, dynamicTodynamic());
  async_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('one shot timer in pure isolate', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawn(async_test.oneshot, JSArrayOfObject().of([JSArrayOfString().of(['START']), response.sendPort]));
      src__matcher__expect.expect(remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())), src__matcher__future_matchers.completion('DONE'));
    }, VoidTodynamic()));
    unittest$.test('periodic timer in pure isolate', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawn(async_test.periodicTimerIsolate, JSArrayOfObject().of([JSArrayOfString().of(['START']), response.sendPort]));
      src__matcher__expect.expect(remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())), src__matcher__future_matchers.completion('DONE'));
    }, VoidTodynamic()));
    unittest$.test('cancellation in pure isolate', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawn(async_test.cancellingIsolate, JSArrayOfObject().of([JSArrayOfString().of(['START']), response.sendPort]));
      src__matcher__expect.expect(remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())), src__matcher__future_matchers.completion('DONE'));
    }, VoidTodynamic()));
  };
  dart.fn(async_test.main, VoidTodynamic());
  let const$;
  async_oneshot.main = function(message, replyTo) {
    let command = dart.dload(message, 'first');
    src__matcher__expect.expect(command, 'START');
    async.Timer.new(const$ || (const$ = dart.const(new core.Duration({milliseconds: 10}))), dart.fn(() => {
      dart.dsend(replyTo, 'send', 'DONE');
    }, VoidTovoid()));
  };
  dart.fn(async_oneshot.main, dynamicAnddynamicTodynamic());
  let const$0;
  let const$1;
  async_periodictimer.main = function(message, replyTo) {
    let command = dart.dload(message, 'first');
    src__matcher__expect.expect(command, 'START');
    let counter = 0;
    async.Timer.periodic(const$0 || (const$0 = dart.const(new core.Duration({milliseconds: 10}))), dart.fn(timer => {
      if (counter == 3) {
        counter = 1024;
        timer.cancel();
        async.Timer.new(const$1 || (const$1 = dart.const(new core.Duration({milliseconds: 30}))), dart.fn(() => {
          dart.dsend(replyTo, 'send', 'DONE');
        }, VoidTovoid()));
        return;
      }
      dart.assert(counter < 3);
      counter++;
    }, TimerTovoid()));
  };
  dart.fn(async_periodictimer.main, dynamicAnddynamicTodynamic());
  let const$2;
  let const$3;
  let const$4;
  async_cancellingisolate.main = function(message, replyTo) {
    let command = dart.dload(message, 'first');
    src__matcher__expect.expect(command, 'START');
    let shot = false;
    let oneshot = null;
    let periodic = null;
    periodic = async.Timer.periodic(const$2 || (const$2 = dart.const(new core.Duration({milliseconds: 10}))), dart.fn(timer => {
      src__matcher__expect.expect(shot, src__matcher__core_matchers.isFalse);
      shot = true;
      src__matcher__expect.expect(timer, src__matcher__core_matchers.same(periodic));
      dart.dsend(periodic, 'cancel');
      dart.dsend(oneshot, 'cancel');
      async.Timer.new(const$3 || (const$3 = dart.const(new core.Duration({milliseconds: 50}))), dart.fn(() => {
        dart.dsend(replyTo, 'send', 'DONE');
      }, VoidTovoid()));
    }, TimerTovoid()));
    oneshot = async.Timer.new(const$4 || (const$4 = dart.const(new core.Duration({milliseconds: 30}))), dart.fn(() => {
      src__matcher__expect.fail('Should never be invoked');
    }, VoidTovoid()));
  };
  dart.fn(async_cancellingisolate.main, dynamicAnddynamicTodynamic());
  // Exports:
  exports.async_test = async_test;
  exports.async_oneshot = async_oneshot;
  exports.async_periodictimer = async_periodictimer;
  exports.async_cancellingisolate = async_cancellingisolate;
});

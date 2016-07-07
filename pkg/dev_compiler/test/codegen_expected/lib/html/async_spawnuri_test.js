dart_library.library('lib/html/async_spawnuri_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__async_spawnuri_test(exports, dart_sdk, unittest) {
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
  const async_spawnuri_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let IsolateToFuture = () => (IsolateToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [isolate.Isolate])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_spawnuri_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('one shot timer in pure isolate', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawnUri(core.Uri.parse('async_oneshot.dart'), JSArrayOfString().of(['START']), response.sendPort);
      remote.catchError(dart.fn(x => src__matcher__expect.expect("Error in oneshot isolate", x), dynamicTovoid()));
      src__matcher__expect.expect(remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())), src__matcher__future_matchers.completion('DONE'));
    }, VoidTodynamic()));
    unittest$.test('periodic timer in pure isolate', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawnUri(core.Uri.parse('async_periodictimer.dart'), JSArrayOfString().of(['START']), response.sendPort);
      remote.catchError(dart.fn(x => src__matcher__expect.expect("Error in periodic timer isolate", x), dynamicTovoid()));
      src__matcher__expect.expect(remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())), src__matcher__future_matchers.completion('DONE'));
    }, VoidTodynamic()));
    unittest$.test('cancellation in pure isolate', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawnUri(core.Uri.parse('async_cancellingisolate.dart'), JSArrayOfString().of(['START']), response.sendPort);
      remote.catchError(dart.fn(x => src__matcher__expect.expect("Error in cancelling isolate", x), dynamicTovoid()));
      src__matcher__expect.expect(remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())), src__matcher__future_matchers.completion('DONE'));
    }, VoidTodynamic()));
  };
  dart.fn(async_spawnuri_test.main, VoidTodynamic());
  // Exports:
  exports.async_spawnuri_test = async_spawnuri_test;
});

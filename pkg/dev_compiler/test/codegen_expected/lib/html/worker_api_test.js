dart_library.library('lib/html/worker_api_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__worker_api_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const isolate = dart_sdk.isolate;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const worker_api_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTodynamic$ = () => (dynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let IsolateToFuture = () => (IsolateToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [isolate.Isolate])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  worker_api_test.worker = function(message) {
    let uri = dart.dindex(message, 0);
    let replyTo = dart.dindex(message, 1);
    try {
      let url = html.Url.createObjectUrl(html.Blob.new(JSArrayOfString().of(['']), 'application/javascript'));
      html.Url.revokeObjectUrl(url);
      dart.dsend(replyTo, 'send', 'Hello from Worker');
    } catch (e) {
      dart.dsend(replyTo, 'send', dart.str`Error: ${e}`);
    }

  };
  dart.fn(worker_api_test.worker, dynamicTodynamic$());
  worker_api_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('Use Worker API in Worker', dart.fn(() => {
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawn(worker_api_test.worker, JSArrayOfObject().of(['', response.sendPort]));
      remote.then(async.Future)(dart.fn(_ => response.first, IsolateToFuture())).then(dart.dynamic)(dynamicTodynamic()._check(unittest$.expectAsync(dart.fn(reply => src__matcher__expect.expect(reply, src__matcher__core_matchers.equals('Hello from Worker')), dynamicTovoid()))));
    }, VoidTodynamic()));
  };
  dart.fn(worker_api_test.main, VoidTodynamic());
  // Exports:
  exports.worker_api_test = worker_api_test;
});

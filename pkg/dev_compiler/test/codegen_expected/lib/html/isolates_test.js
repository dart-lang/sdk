dart_library.library('lib/html/isolates_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__isolates_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const isolate = dart_sdk.isolate;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const isolates_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let SendPortTovoid = () => (SendPortTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [isolate.SendPort])))();
  let SendPortAnddynamicToFuture = () => (SendPortAnddynamicToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [isolate.SendPort, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  isolates_test.responseFor = function(message) {
    return dart.str`response for ${message}`;
  };
  dart.fn(isolates_test.responseFor, dynamicToString());
  isolates_test.isolateEntry = function(initialReplyTo) {
    let port = isolate.ReceivePort.new();
    initialReplyTo.send(port.sendPort);
    let wasThrown = false;
    try {
      html.window[dartx.alert]('Test');
    } catch (e) {
      wasThrown = true;
    }

    if (!wasThrown) {
      return;
    }
    convert.JSON.encode(JSArrayOfint().of([1, 2, 3]));
    port.listen(dart.fn(message => {
      let data = dart.dindex(message, 0);
      let replyTo = dart.dindex(message, 1);
      dart.dsend(replyTo, 'send', isolates_test.responseFor(data));
    }, dynamicTovoid()));
  };
  dart.fn(isolates_test.isolateEntry, SendPortTovoid());
  isolates_test.sendReceive = function(port, msg) {
    let response = isolate.ReceivePort.new();
    port.send([msg, response.sendPort]);
    return response.first;
  };
  dart.fn(isolates_test.sendReceive, SendPortAnddynamicToFuture());
  isolates_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('IsolateSpawn', dart.fn(() => {
      let port = isolate.ReceivePort.new();
      isolate.Isolate.spawn(isolates_test.isolateEntry, port.sendPort);
      port.close();
    }, VoidTodynamic()));
    unittest$.test('NonDOMIsolates', dart.fn(() => {
      let callback = unittest$.expectAsync(dart.fn(() => {
      }, VoidTodynamic()));
      let response = isolate.ReceivePort.new();
      let remote = isolate.Isolate.spawn(isolates_test.isolateEntry, response.sendPort);
      response.first.then(dart.dynamic)(dart.fn(port => {
        let msg1 = 'foo';
        let msg2 = 'bar';
        isolates_test.sendReceive(isolate.SendPort._check(port), msg1).then(dart.dynamic)(dart.fn(response => {
          src__matcher__expect.expect(response, src__matcher__core_matchers.equals(isolates_test.responseFor(msg1)));
          isolates_test.sendReceive(isolate.SendPort._check(port), msg2).then(dart.dynamic)(dart.fn(response => {
            src__matcher__expect.expect(response, src__matcher__core_matchers.equals(isolates_test.responseFor(msg2)));
            dart.dcall(callback);
          }, dynamicTodynamic()));
        }, dynamicTodynamic()));
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
  };
  dart.fn(isolates_test.main, VoidTodynamic());
  // Exports:
  exports.isolates_test = isolates_test;
});

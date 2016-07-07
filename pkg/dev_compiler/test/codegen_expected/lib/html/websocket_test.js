dart_library.library('lib/html/websocket_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__websocket_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const websocket_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let EventTodynamic = () => (EventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.Event])))();
  let MessageEventTodynamic = () => (MessageEventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.MessageEvent])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  websocket_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.WebSocket[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('websocket', dart.fn(() => {
      let isWebSocket = src__matcher__core_matchers.predicate(dart.fn(x => html.WebSocket.is(x), dynamicTobool()), 'is a WebSocket');
      let expectation = dart.test(html.WebSocket[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
      unittest$.test('constructorTest', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let socket = html.WebSocket.new('ws://localhost/ws', 'chat');
          src__matcher__expect.expect(socket, src__matcher__core_matchers.isNotNull);
          src__matcher__expect.expect(socket, isWebSocket);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      if (dart.test(html.WebSocket[dartx.supported])) {
        unittest$.test('echo', dart.fn(() => {
          let socket = html.WebSocket.new(dart.str`ws://${html.window[dartx.location][dartx.host]}/ws`);
          socket[dartx.onOpen].first.then(dart.dynamic)(dart.fn(_ => {
            socket[dartx.send]('hello!');
          }, EventTodynamic()));
          return socket[dartx.onMessage].first.then(dart.dynamic)(dart.fn(e => {
            src__matcher__expect.expect(e[dartx.data], 'hello!');
            socket[dartx.close]();
          }, MessageEventTodynamic()));
        }, VoidToFuture()));
        unittest$.test('error handling', dart.fn(() => {
          let socket = html.WebSocket.new(dart.str`ws://${html.window[dartx.location][dartx.host]}/ws`);
          socket[dartx.onOpen].first.then(dart.dynamic)(dart.fn(_ => socket[dartx.send]('close-with-error'), EventTovoid()));
          return socket[dartx.onError].first.then(dart.dynamic)(dart.fn(e => {
            core.print(dart.str`${e} was caught, yay!`);
            socket[dartx.close]();
          }, EventTodynamic()));
        }, VoidToFuture()));
      }
    }, VoidTovoid()));
  };
  dart.fn(websocket_test.main, VoidTodynamic());
  // Exports:
  exports.websocket_test = websocket_test;
});

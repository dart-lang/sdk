dart_library.library('lib/html/native_gc_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__native_gc_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const native_gc_test = Object.create(null);
  let EventStreamProviderOfEvent = () => (EventStreamProviderOfEvent = dart.constFn(html.EventStreamProvider$(html.Event)))();
  let MouseEventTovoid = () => (MouseEventTovoid = dart.constFn(dart.functionType(dart.void, [html.MouseEvent])))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let MessageEventTovoid = () => (MessageEventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.MessageEvent])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let MouseEventTovoid$ = () => (MouseEventTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [html.MouseEvent])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dart.defineLazy(native_gc_test, {
    get testEvent() {
      return new (EventStreamProviderOfEvent())('test');
    },
    set testEvent(_) {}
  });
  native_gc_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('EventListener', dart.fn(() => {
      let N = 1000000;
      let M = 1000;
      let div = null;
      for (let i = 0; i < M; ++i) {
        let l = core.List.new(N);
        l[dartx.set](N - 1, i);
        div = html.Element.tag('div');
        native_gc_test.testEvent.forTarget(html.EventTarget._check(div)).listen(dart.fn(_ => {
          src__matcher__expect.expect(l[dartx.get](N - 1), M - 1);
        }, EventTovoid()));
      }
      let event = html.Event.new('test');
      dart.dsend(div, 'dispatchEvent', event);
    }, VoidTodynamic()));
    unittest$.test('WindowEventListener', dart.fn(() => {
      let message = 'WindowEventListenerTestPingMessage';
      let testDiv = html.DivElement.new();
      testDiv[dartx.id] = '#TestDiv';
      html.document[dartx.body][dartx.append](testDiv);
      html.window[dartx.onMessage].listen(dart.fn(e => {
        if (dart.equals(e[dartx.data], message)) testDiv[dartx.click]();
      }, MessageEventTovoid()));
      for (let i = 0; i < 100; ++i) {
        native_gc_test.triggerMajorGC();
      }
      testDiv[dartx.onClick].listen(MouseEventTovoid()._check(unittest$.expectAsync(dart.fn(e => {
      }, dynamicTodynamic()))));
      html.window[dartx.postMessage](message, '*');
    }, VoidTodynamic()));
  };
  dart.fn(native_gc_test.main, VoidTodynamic());
  native_gc_test.triggerMajorGC = function() {
    let list = core.List.new(1000000);
    let div = html.DivElement.new();
    div[dartx.onClick].listen(dart.fn(e => core.print(list[dartx.get](0)), MouseEventTovoid$()));
  };
  dart.fn(native_gc_test.triggerMajorGC, VoidTovoid());
  // Exports:
  exports.native_gc_test = native_gc_test;
});

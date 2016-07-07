dart_library.library('lib/html/event_customevent_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__event_customevent_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const js = dart_sdk.js;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const event_customevent_test = Object.create(null);
  let EventStreamProviderOfCustomEvent = () => (EventStreamProviderOfCustomEvent = dart.constFn(html.EventStreamProvider$(html.CustomEvent)))();
  let CustomEventTovoid = () => (CustomEventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.CustomEvent])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  event_customevent_test.DartPayloadData = class DartPayloadData extends core.Object {
    new(dartValue) {
      this.dartValue = dartValue;
    }
  };
  dart.setSignature(event_customevent_test.DartPayloadData, {
    constructors: () => ({new: dart.definiteFunctionType(event_customevent_test.DartPayloadData, [dart.dynamic])})
  });
  event_customevent_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('custom events', dart.fn(() => {
      let provider = new (EventStreamProviderOfCustomEvent())('foo');
      let el = html.DivElement.new();
      let fired = false;
      provider.forTarget(el).listen(dart.fn(ev => {
        fired = true;
        src__matcher__expect.expect(ev[dartx.detail], dart.map({type: 'detail'}));
      }, CustomEventTovoid()));
      let ev = html.CustomEvent.new('foo', {canBubble: false, cancelable: false, detail: dart.map({type: 'detail'})});
      el[dartx.dispatchEvent](ev);
      src__matcher__expect.expect(fired, src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
    unittest$.test('custom events from JS', dart.fn(() => {
      let scriptContents = '      var event = document.createEvent("CustomEvent");\n      event.initCustomEvent("js_custom_event", true, true, {type: "detail"});\n      window.dispatchEvent(event);\n    ';
      let fired = false;
      html.window[dartx.on].get('js_custom_event').listen(dart.fn(ev => {
        fired = true;
        src__matcher__expect.expect(dart.dload(ev, 'detail'), dart.map({type: 'detail'}));
      }, dynamicTovoid()));
      let script = html.ScriptElement.new();
      script[dartx.text] = scriptContents;
      html.document[dartx.body][dartx.append](script);
      src__matcher__expect.expect(fired, src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
    unittest$.test('custom events to JS', dart.fn(() => {
      src__matcher__expect.expect(js.context.get('gotDartEvent'), src__matcher__core_matchers.isNull);
      let scriptContents = '      window.addEventListener(\'dart_custom_event\', function(e) {\n        if (e.detail == \'dart_message\') {\n          e.preventDefault();\n          window.gotDartEvent = true;\n        }\n        window.console.log(\'here\' + e.detail);\n      }, false);';
      html.document[dartx.body][dartx.append]((() => {
        let _ = html.ScriptElement.new();
        _[dartx.text] = scriptContents;
        return _;
      })());
      let event = html.CustomEvent.new('dart_custom_event', {detail: 'dart_message'});
      html.window[dartx.dispatchEvent](event);
      src__matcher__expect.expect(js.context.get('gotDartEvent'), src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
    unittest$.test('custom data to Dart', dart.fn(() => {
      let data = new event_customevent_test.DartPayloadData(666);
      let event = html.CustomEvent.new('dart_custom_data_event', {detail: data});
      let future = html.window[dartx.on].get('dart_custom_data_event').first.then(dart.dynamic)(dart.fn(_ => {
        src__matcher__expect.expect(dart.dload(event[dartx.detail], 'dartValue'), 666);
      }, dynamicTodynamic()));
      html.document[dartx.body][dartx.dispatchEvent](event);
      return future;
    }, VoidToFuture()));
  };
  dart.fn(event_customevent_test.main, VoidTodynamic());
  // Exports:
  exports.event_customevent_test = event_customevent_test;
});

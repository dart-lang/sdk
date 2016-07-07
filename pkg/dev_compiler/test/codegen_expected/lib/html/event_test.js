dart_library.library('lib/html/event_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__event_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const html_config = unittest.html_config;
  const event_test = Object.create(null);
  let VoidToEvent = () => (VoidToEvent = dart.constFn(dart.functionType(html.Event, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.functionType(dart.void, [dart.dynamic])))();
  let dynamicTovoid$ = () => (dynamicTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFnAndFn__Todynamic = () => (StringAndFnAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidToEvent(), dynamicTovoid()], [core.String])))();
  let VoidToCompositionEvent = () => (VoidToCompositionEvent = dart.constFn(dart.definiteFunctionType(html.CompositionEvent, [])))();
  let VoidToEvent$ = () => (VoidToEvent$ = dart.constFn(dart.definiteFunctionType(html.Event, [])))();
  let VoidToHashChangeEvent = () => (VoidToHashChangeEvent = dart.constFn(dart.definiteFunctionType(html.HashChangeEvent, [])))();
  let VoidToMouseEvent = () => (VoidToMouseEvent = dart.constFn(dart.definiteFunctionType(html.MouseEvent, [])))();
  let VoidToStorageEvent = () => (VoidToStorageEvent = dart.constFn(dart.definiteFunctionType(html.StorageEvent, [])))();
  let VoidToUIEvent = () => (VoidToUIEvent = dart.constFn(dart.definiteFunctionType(html.UIEvent, [])))();
  let VoidToWheelEvent = () => (VoidToWheelEvent = dart.constFn(dart.definiteFunctionType(html.WheelEvent, [])))();
  event_test.eventTest = function(name, eventFn, validate, type) {
    if (type === void 0) type = 'foo';
    unittest$.test(name, dart.fn(() => {
      let el = html.Element.tag('div');
      let fired = false;
      el[dartx.on].get(type).listen(dart.fn(ev => {
        fired = true;
        dart.dcall(validate, ev);
      }, dynamicTovoid$()));
      el[dartx.dispatchEvent](eventFn());
      src__matcher__expect.expect(fired, src__matcher__core_matchers.isTrue, {reason: 'Expected event to be dispatched.'});
    }, VoidTodynamic()));
  };
  dart.fn(event_test.eventTest, StringAndFnAndFn__Todynamic());
  event_test.main = function() {
    html_config.useHtmlConfiguration();
    event_test.eventTest('CompositionEvent', dart.fn(() => html.CompositionEvent.new('compositionstart', {view: html.window, data: 'data'}), VoidToCompositionEvent()), dart.fn(ev => {
      src__matcher__expect.expect(dart.dload(ev, 'data'), 'data');
    }, dynamicTovoid$()), 'compositionstart');
    event_test.eventTest('Event', dart.fn(() => html.Event.new('foo', {canBubble: false, cancelable: false}), VoidToEvent$()), dart.fn(ev => {
      src__matcher__expect.expect(dart.dload(ev, 'type'), src__matcher__core_matchers.equals('foo'));
      src__matcher__expect.expect(dart.dload(ev, 'bubbles'), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(dart.dload(ev, 'cancelable'), src__matcher__core_matchers.isFalse);
    }, dynamicTovoid$()));
    event_test.eventTest('HashChangeEvent', dart.fn(() => html.HashChangeEvent.new('foo', {oldUrl: 'http://old.url', newUrl: 'http://new.url'}), VoidToHashChangeEvent()), dart.fn(ev => {
      src__matcher__expect.expect(dart.dload(ev, 'oldUrl'), src__matcher__core_matchers.equals('http://old.url'));
      src__matcher__expect.expect(dart.dload(ev, 'newUrl'), src__matcher__core_matchers.equals('http://new.url'));
    }, dynamicTovoid$()));
    event_test.eventTest('MouseEvent', dart.fn(() => html.MouseEvent.new('foo', {view: html.window, detail: 1, screenX: 2, screenY: 3, clientX: 4, clientY: 5, button: 6, ctrlKey: true, altKey: true, shiftKey: true, metaKey: true, relatedTarget: html.document[dartx.body]}), VoidToMouseEvent()), dart.fn(ev => {
      src__matcher__expect.expect(dart.dload(ev, 'detail'), 1);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'screen'), 'x'), 2);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'screen'), 'y'), 3);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'client'), 'x'), 4);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'client'), 'y'), 5);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'offset'), 'x'), 4);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'offset'), 'y'), 5);
      src__matcher__expect.expect(dart.dload(ev, 'button'), 6);
      src__matcher__expect.expect(dart.dload(ev, 'ctrlKey'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(dart.dload(ev, 'altKey'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(dart.dload(ev, 'shiftKey'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(dart.dload(ev, 'metaKey'), src__matcher__core_matchers.isTrue);
    }, dynamicTovoid$()));
    event_test.eventTest('StorageEvent', dart.fn(() => html.StorageEvent.new('foo', {key: 'key', url: 'http://example.url', storageArea: html.window[dartx.localStorage], canBubble: true, cancelable: true, oldValue: 'old', newValue: 'new'}), VoidToStorageEvent()), dart.fn(ev => {
      src__matcher__expect.expect(dart.dload(ev, 'key'), 'key');
      src__matcher__expect.expect(dart.dload(ev, 'url'), 'http://example.url');
      src__matcher__expect.expect(dart.dload(ev, 'storageArea'), src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(dart.dload(ev, 'oldValue'), 'old');
      src__matcher__expect.expect(dart.dload(ev, 'newValue'), 'new');
    }, dynamicTovoid$()));
    event_test.eventTest('UIEvent', dart.fn(() => html.UIEvent.new('foo', {view: html.window, detail: 12}), VoidToUIEvent()), dart.fn(ev => {
      src__matcher__expect.expect(html.window, dart.dload(ev, 'view'));
      src__matcher__expect.expect(12, dart.dload(ev, 'detail'));
    }, dynamicTovoid$()));
    event_test.eventTest('WheelEvent', dart.fn(() => html.WheelEvent.new("mousewheel", {deltaX: 1, deltaY: 0, detail: 4, screenX: 3, screenY: 4, clientX: 5, clientY: 6, ctrlKey: true, altKey: true, shiftKey: true, metaKey: true}), VoidToWheelEvent()), dart.fn(ev => {
      src__matcher__expect.expect(dart.dload(ev, 'deltaX'), 1);
      src__matcher__expect.expect(dart.dload(ev, 'deltaY'), 0);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'screen'), 'x'), 3);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'screen'), 'y'), 4);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'client'), 'x'), 5);
      src__matcher__expect.expect(dart.dload(dart.dload(ev, 'client'), 'y'), 6);
      src__matcher__expect.expect(dart.dload(ev, 'ctrlKey'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(dart.dload(ev, 'altKey'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(dart.dload(ev, 'shiftKey'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(dart.dload(ev, 'metaKey'), src__matcher__core_matchers.isTrue);
    }, dynamicTovoid$()), 'mousewheel');
  };
  dart.fn(event_test.main, VoidTodynamic());
  // Exports:
  exports.event_test = event_test;
});

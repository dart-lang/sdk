dart_library.library('lib/html/wheelevent_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__wheelevent_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const wheelevent_test = Object.create(null);
  let WheelEventTovoid = () => (WheelEventTovoid = dart.constFn(dart.functionType(dart.void, [html.WheelEvent])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  wheelevent_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('wheelEvent', dart.fn(() => {
      let element = html.DivElement.new();
      let eventType = html.Element.mouseWheelEvent.getEventType(element);
      element[dartx.onMouseWheel].listen(WheelEventTovoid()._check(unittest$.expectAsync(dart.fn(e => {
        src__matcher__expect.expect(dart.dload(dart.dload(e, 'screen'), 'x'), 100);
        src__matcher__expect.expect(dart.dload(e, 'deltaX'), 0);
        src__matcher__expect.expect(dart.dsend(dart.dload(e, 'deltaY'), 'toDouble'), 240.0);
        src__matcher__expect.expect(dart.dload(e, 'deltaMode'), html.WheelEvent.DOM_DELTA_PAGE);
      }, dynamicTodynamic()))));
      let event = html.WheelEvent.new(eventType, {deltaX: 0, deltaY: 240, deltaMode: html.WheelEvent.DOM_DELTA_PAGE, screenX: 100});
      element[dartx.dispatchEvent](event);
    }, VoidTodynamic()));
    unittest$.test('wheelEvent with deltaZ', dart.fn(() => {
      let element = html.DivElement.new();
      let eventType = html.Element.mouseWheelEvent.getEventType(element);
      element[dartx.onMouseWheel].listen(WheelEventTovoid()._check(unittest$.expectAsync(dart.fn(e => {
        src__matcher__expect.expect(dart.dload(e, 'deltaX'), 0);
        src__matcher__expect.expect(dart.dload(e, 'deltaY'), 0);
        src__matcher__expect.expect(dart.dload(dart.dload(e, 'screen'), 'x'), 0);
        src__matcher__expect.expect(dart.dsend(dart.dload(e, 'deltaZ'), 'toDouble'), 1.0);
      }, dynamicTodynamic()))));
      let event = html.WheelEvent.new(eventType, {deltaZ: 1.0});
      element[dartx.dispatchEvent](event);
    }, VoidTodynamic()));
    unittest$.test('wheelEvent Stream', dart.fn(() => {
      let element = html.DivElement.new();
      let eventType = html.Element.mouseWheelEvent.getEventType(element);
      element[dartx.onMouseWheel].listen(WheelEventTovoid()._check(unittest$.expectAsync(dart.fn(e => {
        src__matcher__expect.expect(dart.dload(dart.dload(e, 'screen'), 'x'), 100);
        src__matcher__expect.expect(dart.dsend(dart.dload(e, 'deltaX'), 'toDouble'), 240.0);
        src__matcher__expect.expect(dart.dload(e, 'deltaY'), 0);
      }, dynamicTodynamic()))));
      let event = html.WheelEvent.new(eventType, {deltaX: 240, deltaY: 0, screenX: 100});
      element[dartx.dispatchEvent](event);
    }, VoidTodynamic()));
  };
  dart.fn(wheelevent_test.main, VoidTodynamic());
  // Exports:
  exports.wheelevent_test = wheelevent_test;
});

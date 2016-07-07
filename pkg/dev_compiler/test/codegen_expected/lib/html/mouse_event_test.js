dart_library.library('lib/html/mouse_event_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__mouse_event_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const mouse_event_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mouse_event_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('relatedTarget', dart.fn(() => {
      let event = html.MouseEvent.new('mouseout');
      src__matcher__expect.expect(event[dartx.relatedTarget], src__matcher__core_matchers.isNull);
      event = html.MouseEvent.new('mouseout', {relatedTarget: html.document[dartx.body]});
      src__matcher__expect.expect(event[dartx.relatedTarget], html.document[dartx.body]);
    }, VoidTodynamic()));
  };
  dart.fn(mouse_event_test.main, VoidTodynamic());
  // Exports:
  exports.mouse_event_test = mouse_event_test;
});

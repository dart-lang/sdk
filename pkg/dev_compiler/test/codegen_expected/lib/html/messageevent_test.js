dart_library.library('lib/html/messageevent_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__messageevent_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const messageevent_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  messageevent_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('new MessageEvent', dart.fn(() => {
      let event = html.MessageEvent.new('type', {cancelable: true, data: 'data', origin: 'origin', lastEventId: 'lastEventId'});
      src__matcher__expect.expect(event[dartx.type], src__matcher__core_matchers.equals('type'));
      src__matcher__expect.expect(event[dartx.bubbles], src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(event[dartx.cancelable], src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(event[dartx.data], src__matcher__core_matchers.equals('data'));
      src__matcher__expect.expect(event[dartx.origin], src__matcher__core_matchers.equals('origin'));
      src__matcher__expect.expect(event[dartx.source], html.window);
    }, VoidTodynamic()));
  };
  dart.fn(messageevent_test.main, VoidTodynamic());
  // Exports:
  exports.messageevent_test = messageevent_test;
});

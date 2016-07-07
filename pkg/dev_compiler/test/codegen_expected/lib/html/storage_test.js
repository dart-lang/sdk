dart_library.library('lib/html/storage_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__storage_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const storage_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  storage_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('GetItem', dart.fn(() => {
      let value = html.window[dartx.localStorage][dartx.get]('does not exist');
      src__matcher__expect.expect(value, src__matcher__core_matchers.isNull);
    }, VoidTodynamic()));
    unittest$.test('SetItem', dart.fn(() => {
      let key = 'foo';
      let value = 'bar';
      html.window[dartx.localStorage][dartx.set](key, value);
      let stored = html.window[dartx.localStorage][dartx.get](key);
      src__matcher__expect.expect(stored, value);
    }, VoidTodynamic()));
    unittest$.test('event', dart.fn(() => {
      let event = html.StorageEvent.new('something', {oldValue: 'old', newValue: 'new', url: 'url', key: 'key'});
      src__matcher__expect.expect(html.StorageEvent.is(event), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(event[dartx.oldValue], 'old');
      src__matcher__expect.expect(event[dartx.newValue], 'new');
    }, VoidTodynamic()));
  };
  dart.fn(storage_test.main, VoidTodynamic());
  // Exports:
  exports.storage_test = storage_test;
});

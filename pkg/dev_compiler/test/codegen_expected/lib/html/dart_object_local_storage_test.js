dart_library.library('lib/html/dart_object_local_storage_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__dart_object_local_storage_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const dart_object_local_storage_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart_object_local_storage_test.main = function() {
    html_config.useHtmlConfiguration();
    let body = html.document[dartx.body];
    let localStorage = html.window[dartx.localStorage];
    let sessionStorage = html.window[dartx.sessionStorage];
    let element = html.Element.tag('canvas');
    element[dartx.id] = 'test';
    body[dartx.append](element);
    unittest$.test('body', dart.fn(() => {
      src__matcher__expect.expect(body, src__matcher__core_matchers.equals(html.document[dartx.body]));
    }, VoidTodynamic()));
    unittest$.test('localStorage', dart.fn(() => {
      src__matcher__expect.expect(localStorage, src__matcher__core_matchers.equals(html.window[dartx.localStorage]));
    }, VoidTodynamic()));
    unittest$.test('sessionStorage', dart.fn(() => {
      src__matcher__expect.expect(sessionStorage, src__matcher__core_matchers.equals(html.window[dartx.sessionStorage]));
    }, VoidTodynamic()));
    unittest$.test('unknown', dart.fn(() => {
      let test = html.document[dartx.query]('#test');
      src__matcher__expect.expect(element, src__matcher__core_matchers.equals(test));
    }, VoidTodynamic()));
  };
  dart.fn(dart_object_local_storage_test.main, VoidTodynamic());
  // Exports:
  exports.dart_object_local_storage_test = dart_object_local_storage_test;
});

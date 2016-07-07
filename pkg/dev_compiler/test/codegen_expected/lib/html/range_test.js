dart_library.library('lib/html/range_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__range_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const range_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  range_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supports_createContextualFragment', dart.fn(() => {
        src__matcher__expect.expect(html.Range[dartx.supportsCreateContextualFragment], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('supported works', dart.fn(() => {
        let range = html.Range.new();
        range[dartx.selectNode](html.document[dartx.body]);
        let expectation = dart.test(html.Range[dartx.supportsCreateContextualFragment]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          range[dartx.createContextualFragment]('<div></div>');
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(range_test.main, VoidTodynamic());
  // Exports:
  exports.range_test = range_test;
});

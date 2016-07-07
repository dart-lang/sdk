dart_library.library('lib/html/xsltprocessor_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__xsltprocessor_test(exports, dart_sdk, unittest) {
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
  const xsltprocessor_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  xsltprocessor_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.XsltProcessor[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      let isXsltProcessor = src__matcher__core_matchers.predicate(dart.fn(x => html.XsltProcessor.is(x), dynamicTobool()), 'is an XsltProcessor');
      let expectation = dart.test(html.XsltProcessor[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
      unittest$.test('constructorTest', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let processor = html.XsltProcessor.new();
          src__matcher__expect.expect(processor, src__matcher__core_matchers.isNotNull);
          src__matcher__expect.expect(processor, isXsltProcessor);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(xsltprocessor_test.main, VoidTodynamic());
  // Exports:
  exports.xsltprocessor_test = xsltprocessor_test;
});

dart_library.library('lib/html/performance_api_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__performance_api_test(exports, dart_sdk, unittest) {
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
  const performance_api_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  performance_api_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Performance[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('performance', dart.fn(() => {
      unittest$.test('PerformanceApi', dart.fn(() => {
        let expectation = dart.test(html.Performance[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let requestStart = html.window[dartx.performance][dartx.timing][dartx.requestStart];
          let responseStart = html.window[dartx.performance][dartx.timing][dartx.responseStart];
          let responseEnd = html.window[dartx.performance][dartx.timing][dartx.responseEnd];
          let loading = html.window[dartx.performance][dartx.timing][dartx.domLoading];
          let loadedStart = html.window[dartx.performance][dartx.timing][dartx.domContentLoadedEventStart];
          let loadedEnd = html.window[dartx.performance][dartx.timing][dartx.domContentLoadedEventEnd];
          let complete = html.window[dartx.performance][dartx.timing][dartx.domComplete];
          let loadEventStart = html.window[dartx.performance][dartx.timing][dartx.loadEventStart];
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(performance_api_test.main, VoidTodynamic());
  // Exports:
  exports.performance_api_test = performance_api_test;
});

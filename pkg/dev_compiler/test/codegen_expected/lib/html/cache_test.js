dart_library.library('lib/html/cache_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__cache_test(exports, dart_sdk, unittest) {
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
  const cache_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  cache_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.ApplicationCache[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('ApplicationCache', dart.fn(() => {
      unittest$.test('ApplicationCache', dart.fn(() => {
        let expectation = dart.test(html.ApplicationCache[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let appCache = html.window[dartx.applicationCache];
          src__matcher__expect.expect(cache_test.cacheStatusToString(appCache[dartx.status]), "UNCACHED");
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(cache_test.main, VoidTodynamic());
  cache_test.cacheStatusToString = function(status) {
    switch (status) {
      case html.ApplicationCache.UNCACHED:
      {
        return 'UNCACHED';
      }
      case html.ApplicationCache.IDLE:
      {
        return 'IDLE';
      }
      case html.ApplicationCache.CHECKING:
      {
        return 'CHECKING';
      }
      case html.ApplicationCache.DOWNLOADING:
      {
        return 'DOWNLOADING';
      }
      case html.ApplicationCache.UPDATEREADY:
      {
        return 'UPDATEREADY';
      }
      case html.ApplicationCache.OBSOLETE:
      {
        return 'OBSOLETE';
      }
      default:
      {
        return 'UNKNOWN CACHE STATUS';
      }
    }
    ;
  };
  dart.fn(cache_test.cacheStatusToString, intToString());
  // Exports:
  exports.cache_test = cache_test;
});

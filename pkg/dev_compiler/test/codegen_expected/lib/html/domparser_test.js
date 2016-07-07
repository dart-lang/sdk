dart_library.library('lib/html/domparser_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__domparser_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const domparser_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  domparser_test.main = function() {
    html_config.useHtmlConfiguration();
    let isDomParser = src__matcher__core_matchers.predicate(dart.fn(x => html.DomParser.is(x), dynamicTobool()), 'is a DomParser');
    unittest$.test('constructorTest', dart.fn(() => {
      let ctx = html.DomParser.new();
      src__matcher__expect.expect(ctx, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(ctx, isDomParser);
    }, VoidTodynamic()));
  };
  dart.fn(domparser_test.main, VoidTodynamic());
  // Exports:
  exports.domparser_test = domparser_test;
});

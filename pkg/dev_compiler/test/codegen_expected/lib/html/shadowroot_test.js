dart_library.library('lib/html/shadowroot_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__shadowroot_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const shadowroot_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidToShadowRoot = () => (VoidToShadowRoot = dart.constFn(dart.definiteFunctionType(html.ShadowRoot, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  shadowroot_test.main = function() {
    html_config.useHtmlConfiguration();
    let isShadowRoot = src__matcher__core_matchers.predicate(dart.fn(x => html.ShadowRoot.is(x), dynamicTobool()), 'is a ShadowRoot');
    unittest$.test('ShadowRoot supported', dart.fn(() => {
      let isSupported = html.ShadowRoot[dartx.supported];
      if (dart.test(isSupported)) {
        let div = html.DivElement.new();
        let shadowRoot = div[dartx.createShadowRoot]();
        src__matcher__expect.expect(shadowRoot, isShadowRoot);
        src__matcher__expect.expect(div[dartx.shadowRoot], shadowRoot);
      } else {
        src__matcher__expect.expect(dart.fn(() => html.DivElement.new()[dartx.createShadowRoot](), VoidToShadowRoot()), src__matcher__throws_matcher.throws);
      }
    }, VoidTodynamic()));
  };
  dart.fn(shadowroot_test.main, VoidTodynamic());
  // Exports:
  exports.shadowroot_test = shadowroot_test;
});

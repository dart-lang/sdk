dart_library.library('lib/html/cdata_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__cdata_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const cdata_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cdata_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('remove', dart.fn(() => {
      let div = html.Element.html('<div>content</div>');
      let cdata = div[dartx.nodes][dartx.get](0);
      src__matcher__expect.expect(html.CharacterData.is(cdata), true);
      src__matcher__expect.expect(cdata, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(div[dartx.innerHtml], 'content');
      cdata[dartx.remove]();
      src__matcher__expect.expect(div[dartx.innerHtml], '');
    }, VoidTodynamic()));
  };
  dart.fn(cdata_test.main, VoidTodynamic());
  // Exports:
  exports.cdata_test = cdata_test;
});

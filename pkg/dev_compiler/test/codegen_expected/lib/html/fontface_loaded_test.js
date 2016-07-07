dart_library.library('lib/html/fontface_loaded_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__fontface_loaded_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const fontface_loaded_test = Object.create(null);
  let ListTodynamic = () => (ListTodynamic = dart.constFn(dart.functionType(dart.dynamic, [core.List])))();
  let IterableOfFuture = () => (IterableOfFuture = dart.constFn(core.Iterable$(async.Future)))();
  let FontFaceAndFontFaceAndFontFaceSetTovoid = () => (FontFaceAndFontFaceAndFontFaceSetTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.FontFace, html.FontFace, html.FontFaceSet])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  fontface_loaded_test.NullTreeSanitizer = class NullTreeSanitizer extends core.Object {
    sanitizeTree(node) {}
  };
  fontface_loaded_test.NullTreeSanitizer[dart.implements] = () => [html.NodeTreeSanitizer];
  dart.setSignature(fontface_loaded_test.NullTreeSanitizer, {
    methods: () => ({sanitizeTree: dart.definiteFunctionType(dart.void, [html.Node])})
  });
  fontface_loaded_test.main = function() {
    html_config.useHtmlConfiguration();
    let style = html.Element.html('      <style>\n      @font-face {\n        font-family: \'Ahem\';\n        src: url(/root_dart/tests/html/Ahem.ttf);\n        font-style: italic;\n        font-weight: 300;\n        unicode-range: U+0-3FF;\n        font-variant: small-caps;\n        -webkit-font-feature-settings: "dlig" 1;\n        /* font-stretch property is not supported */\n      }\n      </style>\n      ', {treeSanitizer: new fontface_loaded_test.NullTreeSanitizer()});
    html.document[dartx.head][dartx.append](style);
    unittest$.test('document fonts - temporary', dart.fn(() => {
      let atLeastOneFont = false;
      let loaded = [];
      html.document[dartx.fonts][dartx.forEach](dart.fn((fontFace, _, __) => {
        atLeastOneFont = true;
        let f1 = fontFace[dartx.loaded];
        let f2 = fontFace[dartx.loaded];
        loaded[dartx.add](fontFace[dartx.load]());
        loaded[dartx.add](f1);
        loaded[dartx.add](f2);
      }, FontFaceAndFontFaceAndFontFaceSetTovoid()));
      src__matcher__expect.expect(atLeastOneFont, src__matcher__core_matchers.isTrue);
      return async.Future.wait(dart.dynamic)(IterableOfFuture()._check(loaded)).then(dart.dynamic)(ListTodynamic()._check(unittest$.expectAsync(dart.fn(_ => {
        html.document[dartx.fonts][dartx.forEach](dart.fn((fontFace, _, __) => {
          src__matcher__expect.expect(fontFace[dartx.status], 'loaded');
        }, FontFaceAndFontFaceAndFontFaceSetTovoid()));
      }, dynamicTodynamic()))));
    }, VoidToFuture()));
  };
  dart.fn(fontface_loaded_test.main, VoidTodynamic());
  // Exports:
  exports.fontface_loaded_test = fontface_loaded_test;
});

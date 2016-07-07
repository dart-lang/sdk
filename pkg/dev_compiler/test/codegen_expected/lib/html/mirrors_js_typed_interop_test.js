dart_library.library('lib/html/mirrors_js_typed_interop_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__mirrors_js_typed_interop_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const mirrors_js_typed_interop_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToInstanceMirror = () => (VoidToInstanceMirror = dart.constFn(dart.definiteFunctionType(mirrors.InstanceMirror, [])))();
  mirrors_js_typed_interop_test._injectJs = function() {
    html.document[dartx.body][dartx.append]((() => {
      let _ = html.ScriptElement.new();
      _[dartx.type] = 'text/javascript';
      _[dartx.innerHtml] = "  window.foo = {\n    x: 3,\n    z: 100,\n    multiplyBy2: function(arg) { return arg * 2; },\n  };\n";
      return _;
    })());
  };
  dart.fn(mirrors_js_typed_interop_test._injectJs, VoidTodynamic());
  let const$;
  mirrors_js_typed_interop_test.main = function() {
    mirrors_js_typed_interop_test._injectJs();
    html_config.useHtmlConfiguration();
    unittest$.test('dynamic dispatch', dart.fn(() => {
      let f = dart.global.foo;
      src__matcher__expect.expect(f.x, 3);
      src__matcher__expect.expect(dart.fn(() => mirrors.reflect(f).setField(const$ || (const$ = dart.const(core.Symbol.new('x'))), 123), VoidToInstanceMirror()), src__matcher__throws_matcher.throws);
      src__matcher__expect.expect(f.x, 3);
    }, VoidTodynamic()));
  };
  dart.fn(mirrors_js_typed_interop_test.main, VoidTodynamic());
  // Exports:
  exports.mirrors_js_typed_interop_test = mirrors_js_typed_interop_test;
});

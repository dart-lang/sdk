dart_library.library('lib/html/js_typed_interop_default_arg_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__js_typed_interop_default_arg_test_none_multi(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const js_typed_interop_default_arg_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  js_typed_interop_default_arg_test_none_multi._injectJs = function() {
    html.document[dartx.body][dartx.append]((() => {
      let _ = html.ScriptElement.new();
      _[dartx.type] = 'text/javascript';
      _[dartx.innerHtml] = "  var Foo = {\n    get42: function(b) { return arguments.length >= 1 ? b : 42; },\n    get43: function(b) { return arguments.length >= 1 ? b : 43; }\n  };\n";
      return _;
    })());
  };
  dart.fn(js_typed_interop_default_arg_test_none_multi._injectJs, VoidTodynamic());
  js_typed_interop_default_arg_test_none_multi.main = function() {
    js_typed_interop_default_arg_test_none_multi._injectJs();
    html_config.useHtmlConfiguration();
    unittest$.test('call directly from dart', dart.fn(() => {
      src__matcher__expect.expect(dart.global.Foo.get42(2), 2);
      src__matcher__expect.expect(dart.global.Foo.get42(), 42);
    }, VoidTodynamic()));
    unittest$.test('call tearoff from dart with arg', dart.fn(() => {
      let f = dart.global.Foo.get42;
    }, VoidTodynamic()));
    unittest$.test('call tearoff from dart with default', dart.fn(() => {
      let f = dart.global.Foo.get42;
      f = dart.global.Foo.get43;
      src__matcher__expect.expect(f(), 43);
    }, VoidTodynamic()));
  };
  dart.fn(js_typed_interop_default_arg_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.js_typed_interop_default_arg_test_none_multi = js_typed_interop_default_arg_test_none_multi;
});

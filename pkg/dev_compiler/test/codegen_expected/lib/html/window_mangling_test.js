dart_library.library('lib/html/window_mangling_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__window_mangling_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const window_mangling_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(window_mangling_test, {
    get navigator() {
      return "Dummy";
    }
  });
  window_mangling_test.$eq = function(x, y) {
    return false;
  };
  dart.fn(window_mangling_test.$eq, dynamicAnddynamicTodynamic());
  window_mangling_test.$eq$ = function(x, y) {
    return false;
  };
  dart.fn(window_mangling_test.$eq$, dynamicAnddynamicTodynamic());
  window_mangling_test.main = function() {
    html_config.useHtmlConfiguration();
    let win = html.window;
    unittest$.test('windowMethod', dart.fn(() => {
      let message = window_mangling_test.navigator;
      let x = win[dartx.navigator];
      src__matcher__expect.expect(x, src__matcher__operator_matchers.isNot(src__matcher__core_matchers.equals(message)));
    }, VoidTodynamic()));
    unittest$.test('windowEquals', dart.fn(() => {
      src__matcher__expect.expect(window_mangling_test.$eq(win, win), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(dart.equals(win, win), src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
    unittest$.test('windowEquals', dart.fn(() => {
      src__matcher__expect.expect(window_mangling_test.$eq$(win, win), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(dart.equals(win, win), src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
  };
  dart.fn(window_mangling_test.main, VoidTodynamic());
  // Exports:
  exports.window_mangling_test = window_mangling_test;
});

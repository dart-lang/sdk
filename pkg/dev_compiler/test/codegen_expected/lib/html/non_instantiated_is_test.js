dart_library.library('lib/html/non_instantiated_is_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__non_instantiated_is_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const non_instantiated_is_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(non_instantiated_is_test, {
    get a() {
      return JSArrayOfObject().of([new core.Object()]);
    },
    set a(_) {}
  });
  non_instantiated_is_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('is', dart.fn(() => {
      src__matcher__expect.expect(html.Node.is(non_instantiated_is_test.a[dartx.get](0)), src__matcher__core_matchers.isFalse);
    }, VoidTodynamic()));
  };
  dart.fn(non_instantiated_is_test.main, VoidTodynamic());
  // Exports:
  exports.non_instantiated_is_test = non_instantiated_is_test;
});

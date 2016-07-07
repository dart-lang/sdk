dart_library.library('lib/html/typed_arrays_5_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_5_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const typed_arrays_5_test = Object.create(null);
  let doubleTobool = () => (doubleTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.double])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_arrays_5_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('filter_dynamic', dart.fn(() => {
      let a = typed_data.Float32List.new(1024);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, i[dartx.toDouble]());
      }
      src__matcher__expect.expect(a[dartx.where](dart.fn(x => dart.notNull(x) >= 1000, doubleTobool()))[dartx.length], src__matcher__core_matchers.equals(24));
    }, VoidTodynamic()));
    unittest$.test('filter_typed', dart.fn(() => {
      let a = typed_data.Float32List.new(1024);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, i[dartx.toDouble]());
      }
      src__matcher__expect.expect(a[dartx.where](dart.fn(x => dart.notNull(x) >= 1000, doubleTobool()))[dartx.length], src__matcher__core_matchers.equals(24));
    }, VoidTodynamic()));
    unittest$.test('contains', dart.fn(() => {
      let a = typed_data.Int16List.new(1024);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, i);
      }
      src__matcher__expect.expect(a[dartx.contains](0), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(a[dartx.contains](5), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(a[dartx.contains](1023), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(a[dartx.contains](-5), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(a[dartx.contains](-1), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(a[dartx.contains](1024), src__matcher__core_matchers.isFalse);
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_5_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_5_test = typed_arrays_5_test;
});

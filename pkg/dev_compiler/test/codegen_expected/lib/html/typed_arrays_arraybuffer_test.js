dart_library.library('lib/html/typed_arrays_arraybuffer_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_arraybuffer_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__throws_matchers = unittest.src__matcher__throws_matchers;
  const typed_arrays_arraybuffer_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToListOfint = () => (VoidToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [])))();
  typed_arrays_arraybuffer_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('constructor', dart.fn(() => {
      let a = typed_data.Int8List.new(100);
      src__matcher__expect.expect(a[dartx.lengthInBytes], 100);
    }, VoidTodynamic()));
    unittest$.test('sublist1', dart.fn(() => {
      let a = typed_data.Int8List.new(100);
      let s = a[dartx.sublist](10, 40);
      src__matcher__expect.expect(s[dartx.length], 30);
    }, VoidTodynamic()));
    unittest$.test('sublist2', dart.fn(() => {
      let a = typed_data.Int8List.new(100);
      src__matcher__expect.expect(dart.fn(() => a[dartx.sublist](10, 400), VoidToListOfint()), src__matcher__throws_matchers.throwsRangeError);
    }, VoidTodynamic()));
    unittest$.test('sublist3', dart.fn(() => {
      let a = typed_data.Int8List.new(100);
      src__matcher__expect.expect(dart.fn(() => a[dartx.sublist](50, 10), VoidToListOfint()), src__matcher__throws_matchers.throwsRangeError);
    }, VoidTodynamic()));
    unittest$.test('sublist4', dart.fn(() => {
      let a = typed_data.Int8List.new(100);
      src__matcher__expect.expect(dart.fn(() => a[dartx.sublist](-90, -30), VoidToListOfint()), src__matcher__throws_matchers.throwsRangeError);
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_arraybuffer_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_arraybuffer_test = typed_arrays_arraybuffer_test;
});

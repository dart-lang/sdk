dart_library.library('lib/html/blob_constructor_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__blob_constructor_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__numeric_matchers = unittest.src__matcher__numeric_matchers;
  const blob_constructor_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfBlob = () => (JSArrayOfBlob = dart.constFn(_interceptors.JSArray$(html.Blob)))();
  let JSArrayOfByteBuffer = () => (JSArrayOfByteBuffer = dart.constFn(_interceptors.JSArray$(typed_data.ByteBuffer)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  blob_constructor_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('basic', dart.fn(() => {
      let b = html.Blob.new([]);
      src__matcher__expect.expect(b[dartx.size], src__matcher__numeric_matchers.isZero);
    }, VoidTodynamic()));
    unittest$.test('type1', dart.fn(() => {
      let b = html.Blob.new(JSArrayOfString().of(['Harry']), 'text');
      src__matcher__expect.expect(b[dartx.size], 5);
      src__matcher__expect.expect(b[dartx.type], 'text');
    }, VoidTodynamic()));
    unittest$.test('endings1', dart.fn(() => {
      let b = html.Blob.new(JSArrayOfString().of(['A\nB\n']), null, 'transparent');
      src__matcher__expect.expect(b[dartx.size], 4);
    }, VoidTodynamic()));
    unittest$.test('endings2', dart.fn(() => {
      let b = html.Blob.new(JSArrayOfString().of(['A\nB\n']), null, 'native');
      src__matcher__expect.expect(b[dartx.size], dart.fn(x => dart.equals(x, 4) || dart.equals(x, 6), dynamicTobool()), {reason: "b.size should be 4 or 6"});
    }, VoidTodynamic()));
    unittest$.test('twoStrings', dart.fn(() => {
      let b = html.Blob.new(JSArrayOfString().of(['123', 'xyz']), 'text/plain;charset=UTF-8');
      src__matcher__expect.expect(b[dartx.size], 6);
    }, VoidTodynamic()));
    unittest$.test('fromBlob1', dart.fn(() => {
      let b1 = html.Blob.new([]);
      let b2 = html.Blob.new(JSArrayOfBlob().of([b1]));
      src__matcher__expect.expect(b2[dartx.size], src__matcher__numeric_matchers.isZero);
    }, VoidTodynamic()));
    unittest$.test('fromBlob2', dart.fn(() => {
      let b1 = html.Blob.new(JSArrayOfString().of(['x']));
      let b2 = html.Blob.new(JSArrayOfBlob().of([b1, b1]));
      src__matcher__expect.expect(b1[dartx.size], 1);
      src__matcher__expect.expect(b2[dartx.size], 2);
    }, VoidTodynamic()));
    unittest$.test('fromArrayBuffer', dart.fn(() => {
      let a = typed_data.Uint8List.new(100)[dartx.buffer];
      let b = html.Blob.new(JSArrayOfByteBuffer().of([a, a]));
      src__matcher__expect.expect(b[dartx.size], 200);
    }, VoidTodynamic()));
  };
  dart.fn(blob_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.blob_constructor_test = blob_constructor_test;
});

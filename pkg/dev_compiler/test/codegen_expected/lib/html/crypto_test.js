dart_library.library('lib/html/crypto_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__crypto_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const crypto_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  crypto_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Crypto[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      if (dart.test(html.Crypto[dartx.supported])) {
        unittest$.test('exists', dart.fn(() => {
          let crypto = html.window[dartx.crypto];
          src__matcher__expect.expect(html.Crypto.is(crypto), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
        unittest$.test('successful call', dart.fn(() => {
          let crypto = html.window[dartx.crypto];
          let data = typed_data.Uint8List.new(100);
          src__matcher__expect.expect(data[dartx.every](dart.fn(e => e == 0, intTobool())), src__matcher__core_matchers.isTrue);
          crypto[dartx.getRandomValues](data);
          src__matcher__expect.expect(data[dartx.any](dart.fn(e => e != 0, intTobool())), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
        unittest$.test('type mismatch', dart.fn(() => {
          let crypto = html.window[dartx.crypto];
          let data = typed_data.Float32List.new(100);
          src__matcher__expect.expect(dart.fn(() => {
            crypto[dartx.getRandomValues](data);
          }, VoidTodynamic()), src__matcher__throws_matcher.throws, {reason: 'Only typed array views with integer types allowed'});
        }, VoidTodynamic()));
      }
    }, VoidTovoid()));
  };
  dart.fn(crypto_test.main, VoidTodynamic());
  // Exports:
  exports.crypto_test = crypto_test;
});

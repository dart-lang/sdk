dart_library.library('lib/html/audioelement_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__audioelement_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const audioelement_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  audioelement_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('constructorTest1', dart.fn(() => {
      let audio = html.AudioElement.new();
      src__matcher__expect.expect(audio, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(html.AudioElement.is(audio), src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
    unittest$.test('constructorTest2', dart.fn(() => {
      let audio = html.AudioElement.new('IntentionallyMissingFileURL');
      src__matcher__expect.expect(audio, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(html.AudioElement.is(audio), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(audio[dartx.src], src__matcher__core_matchers.contains('IntentionallyMissingFileURL'));
    }, VoidTodynamic()));
    unittest$.test('canPlayTypeTest', dart.fn(() => {
      let audio = html.AudioElement.new();
      let canPlay = audio[dartx.canPlayType]("audio/mp4");
      src__matcher__expect.expect(canPlay, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(typeof canPlay == 'string', src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
  };
  dart.fn(audioelement_test.main, VoidTodynamic());
  // Exports:
  exports.audioelement_test = audioelement_test;
});

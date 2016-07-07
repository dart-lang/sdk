dart_library.library('lib/html/speechrecognition_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__speechrecognition_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const speechrecognition_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  speechrecognition_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.SpeechRecognition[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('types', dart.fn(() => {
      let expectation = dart.test(html.SpeechRecognition[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
      unittest$.test('SpeechRecognition', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          html.SpeechRecognition.new();
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('SpeechRecognitionError', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let e = html.Event.eventType('SpeechRecognitionError', 'speech');
          src__matcher__expect.expect(html.SpeechRecognitionError.is(e), true);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(speechrecognition_test.main, VoidTodynamic());
  // Exports:
  exports.speechrecognition_test = speechrecognition_test;
});

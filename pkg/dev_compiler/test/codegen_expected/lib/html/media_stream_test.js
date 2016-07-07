dart_library.library('lib/html/media_stream_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__media_stream_test(exports, dart_sdk, unittest) {
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
  const media_stream_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  media_stream_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported_media', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.MediaStream[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_MediaStreamEvent', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.MediaStreamEvent[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_MediaStreamTrackEvent', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.MediaStreamTrackEvent[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('constructors', dart.fn(() => {
      unittest$.test('MediaStreamEvent', dart.fn(() => {
        let expectation = dart.test(html.MediaStreamEvent[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let event = html.Event.eventType('MediaStreamEvent', 'media');
          src__matcher__expect.expect(html.MediaStreamEvent.is(event), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('MediaStreamTrackEvent', dart.fn(() => {
        let expectation = dart.test(html.MediaStreamTrackEvent[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let event = html.Event.eventType('MediaStreamTrackEvent', 'media');
          src__matcher__expect.expect(html.MediaStreamTrackEvent.is(event), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(media_stream_test.main, VoidTodynamic());
  // Exports:
  exports.media_stream_test = media_stream_test;
});

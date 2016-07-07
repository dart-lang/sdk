dart_library.library('lib/html/mediasource_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__mediasource_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const mediasource_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mediasource_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    let isMediaSource = src__matcher__core_matchers.predicate(dart.fn(x => html.MediaSource.is(x), dynamicTobool()), 'is a MediaSource');
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.MediaSource[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      let source = null;
      if (dart.test(html.MediaSource[dartx.supported])) {
        source = html.MediaSource.new();
      }
      unittest$.test('constructorTest', dart.fn(() => {
        if (dart.test(html.MediaSource[dartx.supported])) {
          src__matcher__expect.expect(source, src__matcher__core_matchers.isNotNull);
          src__matcher__expect.expect(source, isMediaSource);
        }
      }, VoidTodynamic()));
      unittest$.test('media types', dart.fn(() => {
        if (dart.test(html.MediaSource[dartx.supported])) {
          src__matcher__expect.expect(html.MediaSource.isTypeSupported('text/html'), false);
          src__matcher__expect.expect(html.MediaSource.isTypeSupported('video/webm;codecs="vp8,vorbis"'), true);
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(mediasource_test.main, VoidTodynamic());
  // Exports:
  exports.mediasource_test = mediasource_test;
});

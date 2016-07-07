dart_library.library('lib/html/audiobuffersourcenode_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__audiobuffersourcenode_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const web_audio = dart_sdk.web_audio;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const audiobuffersourcenode_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  audiobuffersourcenode_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(web_audio.AudioContext[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('createBuffer', dart.fn(() => {
        if (dart.test(web_audio.AudioContext[dartx.supported])) {
          let ctx = web_audio.AudioContext.new();
          let node = ctx[dartx.createBufferSource]();
          src__matcher__expect.expect(web_audio.AudioBufferSourceNode.is(node), src__matcher__core_matchers.isTrue);
          node[dartx.start](ctx[dartx.currentTime], 0, 2);
          src__matcher__expect.expect(web_audio.AudioBufferSourceNode.is(node), src__matcher__core_matchers.isTrue);
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(audiobuffersourcenode_test.main, VoidTodynamic());
  // Exports:
  exports.audiobuffersourcenode_test = audiobuffersourcenode_test;
});

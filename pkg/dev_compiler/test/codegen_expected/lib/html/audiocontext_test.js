dart_library.library('lib/html/audiocontext_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__audiocontext_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const web_audio = dart_sdk.web_audio;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const audiocontext_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  audiocontext_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    let isAudioContext = src__matcher__core_matchers.predicate(dart.fn(x => web_audio.AudioContext.is(x), dynamicTobool()), 'is an AudioContext');
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(web_audio.AudioContext[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      let context = null;
      if (dart.test(web_audio.AudioContext[dartx.supported])) {
        context = web_audio.AudioContext.new();
      }
      unittest$.test('constructorTest', dart.fn(() => {
        if (dart.test(web_audio.AudioContext[dartx.supported])) {
          src__matcher__expect.expect(context, src__matcher__core_matchers.isNotNull);
          src__matcher__expect.expect(context, isAudioContext);
        }
      }, VoidTodynamic()));
      unittest$.test('audioRenames', dart.fn(() => {
        if (dart.test(web_audio.AudioContext[dartx.supported])) {
          let gainNode = web_audio.GainNode._check(dart.dsend(context, 'createGain'));
          gainNode[dartx.connectNode](web_audio.AudioNode._check(dart.dload(context, 'destination')));
          src__matcher__expect.expect(web_audio.GainNode.is(gainNode), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(web_audio.AnalyserNode.is(dart.dsend(context, 'createAnalyser')), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(web_audio.AudioNode.is(dart.dsend(context, 'createChannelMerger')), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(web_audio.AudioNode.is(dart.dsend(context, 'createChannelSplitter')), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(web_audio.OscillatorNode.is(dart.dsend(context, 'createOscillator')), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(web_audio.PannerNode.is(dart.dsend(context, 'createPanner')), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(web_audio.ScriptProcessorNode.is(dart.dsend(context, 'createScriptProcessor', 4096)), src__matcher__core_matchers.isTrue);
        }
      }, VoidTodynamic()));
      unittest$.test('oscillatorTypes', dart.fn(() => {
        if (dart.test(web_audio.AudioContext[dartx.supported])) {
          let oscillator = web_audio.OscillatorNode._check(dart.dsend(context, 'createOscillator'));
          oscillator[dartx.connectNode](web_audio.AudioNode._check(dart.dload(context, 'destination')));
          oscillator[dartx.type] = 'sawtooth';
          src__matcher__expect.expect(oscillator[dartx.type], src__matcher__core_matchers.equals('sawtooth'));
          oscillator[dartx.type] = 'sine';
          src__matcher__expect.expect(oscillator[dartx.type], src__matcher__core_matchers.equals('sine'));
          oscillator[dartx.type] = 'square';
          src__matcher__expect.expect(oscillator[dartx.type], src__matcher__core_matchers.equals('square'));
          oscillator[dartx.type] = 'triangle';
          src__matcher__expect.expect(oscillator[dartx.type], src__matcher__core_matchers.equals('triangle'));
          src__matcher__expect.expect(oscillator[dartx.type], src__matcher__core_matchers.equals('triangle'));
          src__matcher__expect.expect(oscillator[dartx.type], src__matcher__core_matchers.equals('triangle'));
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(audiocontext_test.main, VoidTodynamic());
  // Exports:
  exports.audiocontext_test = audiocontext_test;
});

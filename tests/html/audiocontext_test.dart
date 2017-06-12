library AudioContextTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';
import 'dart:async';

main() {
  useHtmlIndividualConfiguration();

  var isAudioContext =
      predicate((x) => x is AudioContext, 'is an AudioContext');

  group('supported', () {
    test('supported', () {
      expect(AudioContext.supported, true);
    });
  });

  group('functional', () {
    var context;
    if (AudioContext.supported) {
      context = new AudioContext();
    }

    test('constructorTest', () {
      if (AudioContext.supported) {
        expect(context, isNotNull);
        expect(context, isAudioContext);
      }
    });

    test('audioRenames', () {
      if (AudioContext.supported) {
        GainNode gainNode = context.createGain();
        gainNode.connectNode(context.destination);
        expect(gainNode is GainNode, isTrue);

        expect(context.createAnalyser() is AnalyserNode, isTrue);
        expect(context.createChannelMerger() is AudioNode, isTrue);
        expect(context.createChannelSplitter() is AudioNode, isTrue);
        expect(context.createOscillator() is OscillatorNode, isTrue);
        expect(context.createPanner() is PannerNode, isTrue);
        expect(
            context.createScriptProcessor(4096) is ScriptProcessorNode, isTrue);
      }
    });

    // TODO(9322): This test times out.
    /*
    test('onAudioProcess', () {
      if(AudioContext.supported) {
        var completer = new Completer<bool>();
        var context = new AudioContext();
        var scriptProcessor = context.createScriptProcessor(1024, 1, 2);
        scriptProcessor.connectNode(context.destination);
        bool alreadyCalled = false;
        scriptProcessor.onAudioProcess.listen((event) {
          if (!alreadyCalled) {
            completer.complete(true);
          }
          alreadyCalled = true;
        });
        return completer.future;
      }
    });
    */

    test('oscillatorTypes', () {
      if (AudioContext.supported) {
        OscillatorNode oscillator = context.createOscillator();
        oscillator.connectNode(context.destination);

        oscillator.type = 'sawtooth';
        expect(oscillator.type, equals('sawtooth'));

        oscillator.type = 'sine';
        expect(oscillator.type, equals('sine'));

        oscillator.type = 'square';
        expect(oscillator.type, equals('square'));

        oscillator.type = 'triangle';
        expect(oscillator.type, equals('triangle'));

        //expect(() => oscillator.type = 7, throws); Firefox does not throw, it
        //simply ignores this value.
        expect(oscillator.type, equals('triangle'));

        // Firefox does not throw when it receives invalid values; it simply
        // ignores them.
        //expect(() => oscillator.type = ['heap object not a string'], throws);
        expect(oscillator.type, equals('triangle'));
      }
    });
  });
}

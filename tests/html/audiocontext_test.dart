library AudioContextTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
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
    test('constructorTest', () {
      if(AudioContext.supported) {
        var ctx = new AudioContext();
        expect(ctx, isNotNull);
        expect(ctx, isAudioContext);
      }
    });

    test('createBuffer', () {
      if(AudioContext.supported) {
        var ctx = new AudioContext();
        ArrayBufferView arrayBufferView = new Float32Array.fromList([]);
        try {
          // Test that native overload is chosen correctly. Native
          // implementation should throw 'SyntaxError' DomException because the
          // buffer is empty.
          AudioBuffer buffer = ctx.createBuffer(arrayBufferView.buffer, false);
        } catch (e) {
          expect(e.name, DomException.SYNTAX);
        }
      }
    });

    test('audioRenames', () {
      if(AudioContext.supported) {
        AudioContext context = new AudioContext();
        GainNode gainNode = context.createGain();
        gainNode.connect(context.destination, 0, 0);
        expect(gainNode is GainNode, isTrue);

        expect(context.createAnalyser() is AnalyserNode, isTrue);
        expect(context.createChannelMerger() is AudioNode, isTrue);
        expect(context.createChannelSplitter() is AudioNode, isTrue);
        expect(context.createOscillator() is OscillatorNode, isTrue);
        expect(context.createPanner() is PannerNode, isTrue);
        expect(context.createScriptProcessor(4096) is ScriptProcessorNode,
            isTrue);
      }
    });

    test('onAudioProcess', () {
      if(AudioContext.supported) {
        var completer = new Completer<bool>();
        var context = new AudioContext();
        var scriptProcessor = context.createScriptProcessor(1024, 1, 2);
        scriptProcessor.connect(context.destination, 0, 0);
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
  });
}

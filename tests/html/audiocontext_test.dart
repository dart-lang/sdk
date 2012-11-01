library AudioContextTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  useHtmlConfiguration();

  var isAudioContext =
      predicate((x) => x is AudioContext, 'is an AudioContext');

  test('constructorTest', () {
      var ctx = new AudioContext();
      expect(ctx, isNotNull);
      expect(ctx, isAudioContext);
  });
  test('createBuffer', () {
      var ctx = new AudioContext();
      ArrayBufferView arrayBufferView = new Float32Array.fromList([]);
      try {
        // Test that native overload is chosen correctly. Native implementation
        // should throw 'SYNTAX_ERR' DOMException because the buffer is empty.
        AudioBuffer buffer = ctx.createBuffer(arrayBufferView.buffer, false);
      } catch (e) {
        expect(e.code, equals(DOMException.SYNTAX_ERR));
      }
  });

  test('audioRenames', () {
    AudioContext context = new AudioContext();
    GainNode gainNode = context.createGain();
    gainNode.connect(context.destination, 0, 0);
    expect(gainNode is GainNode, isTrue);

    expect(context.createAnalyser() is AnalyserNode, isTrue);
    expect(context.createChannelMerger() is ChannelMergerNode, isTrue);
    expect(context.createChannelSplitter() is ChannelSplitterNode, isTrue);
    expect(context.createOscillator() is OscillatorNode, isTrue);
    expect(context.createPanner() is PannerNode, isTrue);
    expect(context.createScriptProcessor(4096) is ScriptProcessorNode, isTrue);
  });
}

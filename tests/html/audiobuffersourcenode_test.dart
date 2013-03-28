library AudioBufferSourceNodeTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:web_audio';

main() {

  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(AudioContext.supported, true);
    });
  });

  group('functional', () {
    test('createBuffer', () {
      if(AudioContext.supported) {
        var ctx = new AudioContext();
        AudioBufferSourceNode node = ctx.createBufferSource();
        node.start(ctx.currentTime, 0, 2);
        node.stop(ctx.currentTime + 2);
        expect(node is AudioBufferSourceNode, isTrue);
      }
    });
  });
}

library AudioBufferSourceNodeTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:web_audio';

main() {

  useHtmlConfiguration();

  test('createBuffer', () {
      var ctx = new AudioContext();
      AudioBufferSourceNode node = ctx.createBufferSource();
      node.start(ctx.currentTime, 0, 2);
      node.stop(ctx.currentTime + 2);
      expect(node is AudioBufferSourceNode, isTrue);
  });
}

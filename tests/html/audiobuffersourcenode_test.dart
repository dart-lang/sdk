library AudioBufferSourceNodeTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
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
      if (AudioContext.supported) {
        var ctx = new AudioContext();
        AudioBufferSourceNode node = ctx.createBufferSource();
        expect(node is AudioBufferSourceNode, isTrue);
        node.start(ctx.currentTime, 0, 2);
        expect(node is AudioBufferSourceNode, isTrue);
      }
    });
  });
}

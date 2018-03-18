import 'dart:web_audio';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(AudioContext.supported, isTrue);
    });
  });

  group('functional', () {
    test('createBuffer', () {
      if (AudioContext.supported) {
        var ctx = new AudioContext();
        AudioBufferSourceNode node = ctx.createBufferSource();
        expect(node is AudioBufferSourceNode, isTrue);
        node.start2(ctx.currentTime, 0, 2);
        expect(node is AudioBufferSourceNode, isTrue);
      }
    });
  });
}

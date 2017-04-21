import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('constructorTest1', () {
    var audio = new AudioElement();
    expect(audio, isNotNull);
    expect(audio is AudioElement, isTrue);
  });

  test('constructorTest2', () {
    var audio = new AudioElement('IntentionallyMissingFileURL');
    expect(audio, isNotNull);
    expect(audio is AudioElement, isTrue);
    expect(audio.src.contains('IntentionallyMissingFileURL'), isTrue);
  });

  test('canPlayTypeTest', () {
    var audio = new AudioElement();
    var canPlay = audio.canPlayType("audio/mp4");
    expect(canPlay, isNotNull);
    expect(canPlay is String, isTrue);
  });
}

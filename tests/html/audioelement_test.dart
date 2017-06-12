library AudioElementTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('constructorTest1', () {
    var audio = new AudioElement();
    expect(audio, isNotNull);
    expect(audio is AudioElement, isTrue);
  });

  test('constructorTest2', () {
    var audio = new AudioElement('IntentionallyMissingFileURL');
    expect(audio, isNotNull);
    expect(audio is AudioElement, isTrue);
    expect(audio.src, contains('IntentionallyMissingFileURL'));
  });

  test('canPlayTypeTest', () {
    var audio = new AudioElement();
    var canPlay = audio.canPlayType("audio/mp4");
    expect(canPlay, isNotNull);
    expect(canPlay is String, isTrue);
  });
}

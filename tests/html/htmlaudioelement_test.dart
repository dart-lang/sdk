library AudioElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  useHtmlConfiguration();

  var isAudioElement =
      predicate((x) => x is AudioElement, 'is an AudioElement');

  test('constructorTest1', () {
      var audio = new AudioElement();   // would be new Audio() in JS
      expect(audio, isNotNull);
      expect(audio, isAudioElement);
    });

  test('constructorTest2', () {
      var audio = new AudioElement('hahaURL');
      expect(audio, isNotNull);
      expect(audio, isAudioElement);
      expect(audio.src.indexOf('hahaURL'), greaterThanOrEqualTo(0));
    });
}

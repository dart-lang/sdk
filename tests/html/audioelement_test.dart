#library('AudioElementTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('constructorTest1', () {
      var audio = new AudioElement();
      expect(audio, isNotNull);
      expect(audio is AudioElement, isTrue);
    });

  test('constructorTest2', () {
      var audio = new AudioElement('hahaURL');
      expect(audio, isNotNull);
      expect(audio is AudioElement, isTrue);
      expect(audio.src, contains('hahaURL'));
    });
}

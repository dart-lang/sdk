#library('AudioElementTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('constructorTest1', () {
      var audio = new AudioElement();
      expect(audio, isNotNull);
      expect(audio is AudioElement);
    });

  test('constructorTest2', () {
      var audio = new AudioElement('hahaURL');
      expect(audio, isNotNull);
      expect(audio is AudioElement);
      expect(audio.src, contains('hahaURL'));
    });
}

#library('AudioElementTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('constructorTest1', () {
      var audio = new AudioElement();
      Expect.isTrue(audio != null);
      Expect.isTrue(audio is AudioElement);
    });

  test('constructorTest2', () {
      var audio = new AudioElement('hahaURL');
      Expect.isTrue(audio != null);
      Expect.isTrue(audio is AudioElement);
      Expect.isTrue(audio.src.indexOf('hahaURL') >= 0);
    });
}

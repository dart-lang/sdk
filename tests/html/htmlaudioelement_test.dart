#library('AudioElementTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest1', () {
      var audio = new AudioElement();   // would be new Audio() in JS
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

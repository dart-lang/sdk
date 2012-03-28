#library('AudioElementTest');
#import('../../../../lib/unittest/unittest_html.dart');
#import('dart:html');

main() {

  forLayoutTests();

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

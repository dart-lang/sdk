#library('HTMLAudioElementTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {

  forLayoutTests();

  test('constructorTest1', () {
      var audio = new HTMLAudioElement();   // would be new Audio() in JS
      Expect.isTrue(audio != null);
      Expect.isTrue(audio is HTMLAudioElement);
    });

  test('constructorTest2', () {
      var audio = new HTMLAudioElement('hahaURL');
      Expect.isTrue(audio != null);
      Expect.isTrue(audio is HTMLAudioElement);
      Expect.isTrue(audio.src.indexOf('hahaURL') >= 0);
    });
}

#library('CallbacksTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('RequestAnimationFrameCallback', () {
    window.webkitRequestAnimationFrame((int time) => false, document.body);
  });
}

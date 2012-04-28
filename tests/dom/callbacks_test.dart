#library('CallbacksTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();
  test('RequestAnimationFrameCallback', () {
    window.webkitRequestAnimationFrame((int time) => false);
  });
}

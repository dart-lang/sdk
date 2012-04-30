#library('CallbacksTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('RequestAnimationFrameCallback', () {
    window.webkitRequestAnimationFrame((int time) => false);
  });
}

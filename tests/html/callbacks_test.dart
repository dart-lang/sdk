#library('CallbacksTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('RequestAnimationFrameCallback', () {
    window.webkitRequestAnimationFrame((int time) => false);
  });
}

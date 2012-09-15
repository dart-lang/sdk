#library('CallbacksTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('RequestAnimationFrameCallback', () {
    window.webkitRequestAnimationFrame((int time) => false);
  });
}

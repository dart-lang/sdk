#library('AudioBufferSourceNodeTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('createBuffer', () {
      var ctx = new AudioContext();
      AudioBufferSourceNode node = ctx.createBufferSource();
      node.start(ctx.currentTime, 0, 2);
      node.stop(ctx.currentTime + 2);
      expect(node is AudioBufferSourceNode);
  });
}

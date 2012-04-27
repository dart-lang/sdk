#library('WrapperTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  CanvasElement canvas;
  CanvasRenderingContext2D context;

  canvas = new Element.tag('canvas');
  canvas.id = 'canvas';
  canvas.attributes['width'] = 100;
  canvas.attributes['height'] = 100;
  document.body.nodes.add(canvas);
  context = canvas.getContext('2d');

  useHtmlConfiguration();
  test('DomType', () {
    Expect.isTrue(canvas is DOMType);
    Expect.isTrue(context is DOMType);
  });
  test('ObjectLocalStorage', () {
    final element = document.query('#canvas');
    element.dartObjectLocalStorage = 42;

    Expect.equals(42, canvas.dynamic.dartObjectLocalStorage);
  });
  test('TypeName', () {
    final element = document.query('#canvas');
    Expect.stringEquals('CanvasElement', element.typeName);
    Expect.stringEquals('CanvasElement', canvas.dynamic.typeName);
    Expect.stringEquals('CanvasRenderingContext2D', context.dynamic.typeName);
  });
}

#library('WrapperTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {
  HTMLCanvasElement canvas;
  CanvasRenderingContext2D context;

  // FIXME: once main is run on content loaded, this hack won't be necessary.
  window.setTimeout(() {
    canvas = document.createElement('canvas');
    canvas.id = 'canvas';
    canvas.setAttribute('width', '100');
    canvas.setAttribute('height', '100');
    document.body.appendChild(canvas);
    context = canvas.getContext('2d');
  }, 0);

  forLayoutTests();
  test('DomType', () {
    Expect.isTrue(canvas is DOMType);
    Expect.isTrue(context is DOMType);
  });
  test('ObjectLocalStorage', () {
    final element = document.getElementById('canvas');
    element.dartObjectLocalStorage = 42;

    Expect.equals(42, canvas.dynamic.dartObjectLocalStorage);
  });
  test('TypeName', () {
    final element = document.getElementById('canvas');
    Expect.stringEquals('HTMLCanvasElement', element.typeName);
    Expect.stringEquals('HTMLCanvasElement', canvas.dynamic.typeName);
    Expect.stringEquals('CanvasRenderingContext2D', context.dynamic.typeName);
  });
}

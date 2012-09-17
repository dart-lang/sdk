#library('InstanceOfTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  CanvasElement canvas;

  canvas = new Element.tag('canvas');
  canvas.attributes['width'] = 100;
  canvas.attributes['height'] = 100;
  document.body.nodes.add(canvas);

  useHtmlConfiguration();
  test('Instanceof', () {
    Expect.isFalse(canvas is CanvasRenderingContext);
    Expect.isFalse(canvas is CanvasRenderingContext2D);
    Expect.isTrue(canvas is Element);
    Expect.isTrue(canvas is CanvasElement);
    Expect.isFalse(canvas is ImageData);
    // Expect.isFalse(canvas is CanvasPixelArray);

    CanvasRenderingContext2D context = canvas.getContext('2d');
    Expect.isTrue(context is CanvasRenderingContext);
    Expect.isTrue(context is CanvasRenderingContext2D);
    Expect.isFalse(context is Element);
    Expect.isFalse(context is CanvasElement);
    Expect.isFalse(context is ImageData);
    // Expect.isFalse(context is CanvasPixelArray);

    // FIXME(b/5286633): Interface injection type check workaround.
    var image = context.createImageData(canvas.width as Dynamic,
                                        canvas.height as Dynamic);
    Expect.isFalse(image is CanvasRenderingContext);
    Expect.isFalse(image is CanvasRenderingContext2D);
    Expect.isFalse(image is Element);
    Expect.isFalse(image is CanvasElement);
    Expect.isTrue(image is ImageData);
    // Expect.isFalse(image is CanvasPixelArray);

    // Include CanvasPixelArray since constructor and prototype are not
    // available until one is created.
    var bytes = image.data;
    Expect.isFalse(bytes is CanvasRenderingContext);
    Expect.isFalse(bytes is CanvasRenderingContext2D);
    Expect.isFalse(bytes is Element);
    Expect.isFalse(bytes is CanvasElement);
    Expect.isFalse(bytes is ImageData);
    Expect.isTrue(bytes is Uint8ClampedArray);

    // FIXME: Ensure this is an SpanElement when we next update
    // WebKit IDL.
    var span = new Element.tag('span');
    Expect.isTrue(span is Element);
  });
}

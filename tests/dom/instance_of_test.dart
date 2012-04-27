#library('InstanceOfTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  HTMLCanvasElement canvas;

  canvas = document.createElement('canvas');
  canvas.setAttribute('width', '100');
  canvas.setAttribute('height', '100');
  document.body.appendChild(canvas);

  useDomConfiguration();
  test('Instanceof', () {
    Expect.isFalse(canvas is CanvasRenderingContext);
    Expect.isFalse(canvas is CanvasRenderingContext2D);
    Expect.isTrue(canvas is HTMLElement);
    Expect.isTrue(canvas is HTMLCanvasElement);
    Expect.isFalse(canvas is ImageData);
    // Expect.isFalse(canvas is CanvasPixelArray);

    CanvasRenderingContext2D context = canvas.getContext('2d');
    Expect.isTrue(context is CanvasRenderingContext);
    Expect.isTrue(context is CanvasRenderingContext2D);
    Expect.isFalse(context is HTMLElement);
    Expect.isFalse(context is HTMLCanvasElement);
    Expect.isFalse(context is ImageData);
    // Expect.isFalse(context is CanvasPixelArray);

    // FIXME(b/5286633): Interface injection type check workaround.
    var image = context.createImageData(canvas.width.dynamic, canvas.height.dynamic);
    Expect.isFalse(image is CanvasRenderingContext);
    Expect.isFalse(image is CanvasRenderingContext2D);
    Expect.isFalse(image is HTMLElement);
    Expect.isFalse(image is HTMLCanvasElement);
    Expect.isTrue(image is ImageData);
    // Expect.isFalse(image is CanvasPixelArray);

    // Include CanvasPixelArray since constructor and prototype are not
    // available until one is created.
    var bytes = image.data;
    Expect.isFalse(bytes is CanvasRenderingContext);
    Expect.isFalse(bytes is CanvasRenderingContext2D);
    Expect.isFalse(bytes is HTMLElement);
    Expect.isFalse(bytes is HTMLCanvasElement);
    Expect.isFalse(bytes is ImageData);
    Expect.isTrue(bytes is Uint8ClampedArray);

    // FIXME: Ensure this is an HTMLSpanElement when we next update
    // WebKit IDL.
    var span = document.createElement('span');
    Expect.isTrue(span is HTMLElement);
  });
}

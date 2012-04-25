#library('CanvasTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/html_config.dart');
#import('dart:html');

// We have aliased the legacy type CanvasPixelArray with the new type
// Uint8ClampedArray by mapping the CanvasPixelArray type tag to
// Uint8ClampedArray.  It is not a perfect match since CanvasPixelArray is
// missing the ArrayBufferView members.  These should appear to be null.

Object confuseType(x) => [1, x, [x], 's'] [1];

main() {
  CanvasElement canvas;
  CanvasRenderingContext2D context;
  int width = 100;
  int height = 100;

  canvas = new Element.tag('canvas');
  canvas.width = width;
  canvas.height = height;
  document.body.nodes.add(canvas);

  context = canvas.getContext('2d');

  useHtmlConfiguration();

  test('CreateImageData', () {
    ImageData image = context.createImageData(canvas.width,
                                              canvas.height);
    Uint8ClampedArray data = image.data;
    // It is legal for the dart2js compiler to believe the type of the native
    // ImageData.data and elides the check, so check the type explicitly:
    Expect.isTrue(confuseType(data) is Uint8ClampedArray);

    Expect.equals(40000, data.length);
    checkPixel(data, 0, [0, 0, 0, 0]);
    checkPixel(data, width * height - 1, [0, 0, 0, 0]);

    data[100] = 200;
    Expect.equals(200, data[100]);
  });

  test('PutImageData', () {
    ImageData data = context.getImageData(0, 0, width, height);
    data.data[0] = 25;
    data.data[3] = 255;
    context.putImageData(data, 0, 0);

    data = context.getImageData(0, 0, width, height);
    Expect.equals(25, data.data[0]);
    Expect.equals(255, data.data[3]);
  });
}

void checkPixel(Uint8ClampedArray data, int offset, List<int> rgba)
{
  offset *= 4;
  for (var i = 0; i < 4; ++i) {
    Expect.equals(rgba[i], data[offset + i]);
  }
}

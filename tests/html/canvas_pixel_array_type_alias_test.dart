#library('CanvasTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
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
    expect(confuseType(data) is Uint8ClampedArray, reason: 'canvas array type');

    expect(data, hasLength(40000));
    checkPixel(data, 0, [0, 0, 0, 0]);
    checkPixel(data, width * height - 1, [0, 0, 0, 0]);

    data[100] = 200;
    expect(data[100], equals(200));
  });
}

void checkPixel(Uint8ClampedArray data, int offset, List<int> rgba)
{
  offset *= 4;
  for (var i = 0; i < 4; ++i) {
    Expect.equals(rgba[i], data[offset + i]);
  }
}

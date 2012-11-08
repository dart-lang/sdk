library CanvasTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  CanvasElement canvas;
  CanvasRenderingContext2D context;
  int width = 100;
  int height = 100;

  canvas = new Element.tag('canvas');
  canvas.attributes['width'] = width;
  canvas.attributes['height'] = height;
  document.body.nodes.add(canvas);

  context = canvas.context2d;

  useHtmlConfiguration();
  test('CreateImageData', () {
    ImageData image = context.createImageData(canvas.width,
                                              canvas.height);
    Uint8ClampedArray data = image.data;

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
    expect(data[offset + i], equals(rgba[i]));
  }
}

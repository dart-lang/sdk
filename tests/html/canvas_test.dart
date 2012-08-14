#library('CanvasTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

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
  test('FillStyle', () {
    context.fillStyle = "red";
    context.fillRect(10, 10, 20, 20);

    Uint8ClampedArray data = context.getImageData(0, 0, width, height).data;
    checkPixel(data, 0, [0, 0, 0, 0]);
    checkPixel(data, 9 + width * 10, [0, 0, 0, 0]);
    checkPixel(data, 10 + width * 10, [255, 0, 0, 255]);
    checkPixel(data, 29 + width * 10, [255, 0, 0, 255]);
    checkPixel(data, 30 + width * 10, [0, 0, 0, 0]);
  });
  test('FillStyleGradient', () {
    var gradient = context.createLinearGradient(0,0,20,20);
    gradient.addColorStop(0,'red');
    gradient.addColorStop(1,'blue');
    context.fillStyle = gradient;
    context.fillRect(0, 0, 20, 20);
    expect(context.fillStyle is CanvasGradient, isTrue);
  });
  test('SetFillColor', () {
    // With floats.
    context.setFillColor(10, 10, 10, 10);
    context.fillRect(10, 10, 20, 20);

    // With rationals.
    context.setFillColor(10.0, 10.0, 10.0, 10.0);
    context.fillRect(20, 20, 30, 30);

    // With ints.
    context.setFillColor(10, 10, 10, 10);
    context.fillRect(30, 30, 40, 40);

    // TODO(vsm): Verify the result once we have the ability to read pixels.
  });
  test('StrokeStyle', () {
    context.strokeStyle = "blue";
    context.strokeRect(30, 30, 10, 20);

    // TODO(vsm): Verify the result once we have the ability to read pixels.
  });
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
  test('PutImageData', () {
    ImageData data = context.getImageData(0, 0, width, height);
    data.data[0] = 25;
    data.data[3] = 255;
    context.putImageData(data, 0, 0);

    data = context.getImageData(0, 0, width, height);
    expect(data.data[0], equals(25));
    expect(data.data[3], equals(255));
  });
}

void checkPixel(Uint8ClampedArray data, int offset, List<int> rgba)
{
  offset *= 4;
  for (var i = 0; i < 4; ++i) {
    expect(data[offset + i], equals(rgba[i]));
  }
}

#library('CanvasTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {
  HTMLCanvasElement canvas;
  CanvasRenderingContext2D context;
  int width = 100;
  int height = 100;

  canvas = document.createElement('canvas');
  canvas.setAttribute('width', '$width');
  canvas.setAttribute('height', '$height');
  document.body.appendChild(canvas);

  context = canvas.getContext('2d');

  forLayoutTests();
  test('FillStyle', () {
    context.fillStyle = "red";
    context.fillRect(10, 10, 20, 20);

    CanvasPixelArray data = context.getImageData(0, 0, width, height).data;
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
    expect(context.fillStyle is CanvasGradient).isTrue();
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
    CanvasPixelArray data = image.data;

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

void checkPixel(CanvasPixelArray data, int offset, List<int> rgba)
{
  offset *= 4;
  for (var i = 0; i < 4; ++i) {
    Expect.equals(rgba[i], data[offset + i]);
  }
}

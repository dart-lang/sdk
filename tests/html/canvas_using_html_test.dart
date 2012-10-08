#library('CanvasUsingHtmlTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html', prefix: 'html');
#import('dart:html');

// Version of Canvas test that implicitly uses dart:html library via unittests.

main() {
  CanvasElement canvas;
  CanvasRenderingContext2D context;

  canvas = new Element.tag('canvas');
  canvas.attributes['width'] = 100;
  canvas.attributes['height'] = 100;
  document.body.nodes.add(canvas);
  context = canvas.getContext('2d');

  useHtmlConfiguration();
  test('FillStyle', () {
    context.fillStyle = "red";
    context.fillRect(10, 10, 20, 20);

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
    Uint8ClampedArray bytes = image.data;

    // FIXME: uncomment when numeric index getters are supported.
    //var byte = bytes[0];

    expect(bytes, hasLength(40000));
  });
}

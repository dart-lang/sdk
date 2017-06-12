library InstanceOfTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  CanvasElement canvas;

  canvas = new Element.tag('canvas');
  canvas.attributes['width'] = '100';
  canvas.attributes['height'] = '100';
  document.body.append(canvas);

  var isCanvasRenderingContext = predicate(
      (x) => x is CanvasRenderingContext, 'is a CanvasRenderingContext');
  var isCanvasRenderingContext2D = predicate(
      (x) => x is CanvasRenderingContext2D, 'is a CanvasRenderingContext2D');
  var isElement = predicate((x) => x is Element, 'is an Element');
  var isCanvasElement =
      predicate((x) => x is CanvasElement, 'is a CanvasElement');
  var isImageData = predicate((x) => x is ImageData, 'is an ImageData');
  //var isUint8ClampedArray =
  //  predicate((x) => x is Uint8ClampedArray, 'is a Uint8ClampedArray');
  var isIntList = predicate((x) => x is List<int>, 'is a List<int>');

  useHtmlConfiguration();
  test('Instanceof', () {
    expect(canvas, isNot(isCanvasRenderingContext));
    expect(canvas, isNot(isCanvasRenderingContext2D));
    expect(canvas, isElement);
    expect(canvas, isCanvasElement);
    expect(canvas, isNot(isImageData));
    // expect(canvas, isNot(isCanvasPixelArray));

    CanvasRenderingContext2D context = canvas.getContext('2d');
    expect(context, isCanvasRenderingContext);
    expect(context, isCanvasRenderingContext2D);
    expect(context, isNot(isElement));
    expect(context, isNot(isCanvasElement));
    expect(context, isNot(isImageData));
    // expect(context, isNot(isCanvasPixelArray));

    // FIXME(b/5286633): Interface injection type check workaround.
    var image = context.createImageData(
        canvas.width as dynamic, canvas.height as dynamic);
    expect(image, isNot(isCanvasRenderingContext));
    expect(image, isNot(isCanvasRenderingContext2D));
    expect(image, isNot(isElement));
    expect(image, isNot(isCanvasElement));
    expect(image, isImageData);
    // expect(image, isNot(isCanvasPixelArray));

    // Include CanvasPixelArray since constructor and prototype are not
    // available until one is created.
    var bytes = image.data;
    expect(bytes, isNot(isCanvasRenderingContext));
    expect(bytes, isNot(isCanvasRenderingContext2D));
    expect(bytes, isNot(isElement));
    expect(bytes, isNot(isCanvasElement));
    expect(bytes, isNot(isImageData));
    expect(bytes, isIntList);

    // FIXME: Ensure this is an SpanElement when we next update
    // WebKit IDL.
    var span = new Element.tag('span');
    expect(span, isElement);
  });
}

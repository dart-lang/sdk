import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  CanvasElement canvas;

  canvas = new Element.tag('canvas');
  canvas.attributes['width'] = '100';
  canvas.attributes['height'] = '100';
  document.body.append(canvas);

  var isCanvasRenderingContext = predicate(
      (x) => x is CanvasRenderingContext, 'is a CanvasRenderingContext');
  var isNotCanvasRenderingContext = predicate(
      (x) => x is! CanvasRenderingContext, 'is not a CanvasRenderingContext');
  var isCanvasRenderingContext2D = predicate(
      (x) => x is CanvasRenderingContext2D, 'is a CanvasRenderingContext2D');
  var isNotCanvasRenderingContext2D = predicate(
      (x) => x is! CanvasRenderingContext2D,
      'is not a CanvasRenderingContext2D');
  var isElement = predicate((x) => x is Element, 'is an Element');
  var isNotElement = predicate((x) => x is! Element, 'is not an Element');
  var isCanvasElement =
      predicate((x) => x is CanvasElement, 'is a CanvasElement');
  var isNotCanvasElement =
      predicate((x) => x is! CanvasElement, 'is not a CanvasElement');
  var isImageData = predicate((x) => x is ImageData, 'is an ImageData');
  var isNotImageData = predicate((x) => x is! ImageData, 'is not an ImageData');
  //var isUint8ClampedArray =
  //  predicate((x) => x is Uint8ClampedArray, 'is a Uint8ClampedArray');
  var isIntList = predicate((x) => x is List<int>, 'is a List<int>');

  test('Instanceof', () {
    expect(canvas, isNotCanvasRenderingContext);
    expect(canvas, isNotCanvasRenderingContext2D);
    expect(canvas, isElement);
    expect(canvas, isCanvasElement);
    expect(canvas, isNotImageData);
    // expect(canvas, isNot(isCanvasPixelArray));

    CanvasRenderingContext2D context = canvas.getContext('2d');
    expect(context, isCanvasRenderingContext);
    expect(context, isCanvasRenderingContext2D);
    expect(context, isNotElement);
    expect(context, isNotCanvasElement);
    expect(context, isNotImageData);
    // expect(context, isNot(isCanvasPixelArray));

    // FIXME(b/5286633): Interface injection type check workaround.
    var image = context.createImageData(
        canvas.width as dynamic, canvas.height as dynamic);
    expect(image, isNotCanvasRenderingContext);
    expect(image, isNotCanvasRenderingContext2D);
    expect(image, isNotElement);
    expect(image, isNotCanvasElement);
    expect(image, isImageData);
    // expect(image, isNot(isCanvasPixelArray));

    // Include CanvasPixelArray since constructor and prototype are not
    // available until one is created.
    var bytes = image.data;
    expect(bytes, isNotCanvasRenderingContext);
    expect(bytes, isNotCanvasRenderingContext2D);
    expect(bytes, isNotElement);
    expect(bytes, isNotCanvasElement);
    expect(bytes, isNotImageData);
    expect(bytes, isIntList);

    // FIXME: Ensure this is an SpanElement when we next update
    // WebKit IDL.
    var span = new Element.tag('span');
    expect(span, isElement);
  });
}

dart_library.library('lib/html/instance_of_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__instance_of_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const instance_of_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instance_of_test.main = function() {
    let canvas = null;
    canvas = html.CanvasElement._check(html.Element.tag('canvas'));
    canvas[dartx.attributes][dartx.set]('width', '100');
    canvas[dartx.attributes][dartx.set]('height', '100');
    html.document[dartx.body][dartx.append](canvas);
    let isCanvasRenderingContext = src__matcher__core_matchers.predicate(dart.fn(x => html.CanvasRenderingContext.is(x), dynamicTobool()), 'is a CanvasRenderingContext');
    let isCanvasRenderingContext2D = src__matcher__core_matchers.predicate(dart.fn(x => html.CanvasRenderingContext2D.is(x), dynamicTobool()), 'is a CanvasRenderingContext2D');
    let isElement = src__matcher__core_matchers.predicate(dart.fn(x => html.Element.is(x), dynamicTobool()), 'is an Element');
    let isCanvasElement = src__matcher__core_matchers.predicate(dart.fn(x => html.CanvasElement.is(x), dynamicTobool()), 'is a CanvasElement');
    let isImageData = src__matcher__core_matchers.predicate(dart.fn(x => html.ImageData.is(x), dynamicTobool()), 'is an ImageData');
    let isIntList = src__matcher__core_matchers.predicate(dart.fn(x => ListOfint().is(x), dynamicTobool()), 'is a List<int>');
    html_config.useHtmlConfiguration();
    unittest$.test('Instanceof', dart.fn(() => {
      src__matcher__expect.expect(canvas, src__matcher__operator_matchers.isNot(isCanvasRenderingContext));
      src__matcher__expect.expect(canvas, src__matcher__operator_matchers.isNot(isCanvasRenderingContext2D));
      src__matcher__expect.expect(canvas, isElement);
      src__matcher__expect.expect(canvas, isCanvasElement);
      src__matcher__expect.expect(canvas, src__matcher__operator_matchers.isNot(isImageData));
      let context = html.CanvasRenderingContext2D._check(canvas[dartx.getContext]('2d'));
      src__matcher__expect.expect(context, isCanvasRenderingContext);
      src__matcher__expect.expect(context, isCanvasRenderingContext2D);
      src__matcher__expect.expect(context, src__matcher__operator_matchers.isNot(isElement));
      src__matcher__expect.expect(context, src__matcher__operator_matchers.isNot(isCanvasElement));
      src__matcher__expect.expect(context, src__matcher__operator_matchers.isNot(isImageData));
      let image = context[dartx.createImageData](canvas[dartx.width], core.num._check(canvas[dartx.height]));
      src__matcher__expect.expect(image, src__matcher__operator_matchers.isNot(isCanvasRenderingContext));
      src__matcher__expect.expect(image, src__matcher__operator_matchers.isNot(isCanvasRenderingContext2D));
      src__matcher__expect.expect(image, src__matcher__operator_matchers.isNot(isElement));
      src__matcher__expect.expect(image, src__matcher__operator_matchers.isNot(isCanvasElement));
      src__matcher__expect.expect(image, isImageData);
      let bytes = image[dartx.data];
      src__matcher__expect.expect(bytes, src__matcher__operator_matchers.isNot(isCanvasRenderingContext));
      src__matcher__expect.expect(bytes, src__matcher__operator_matchers.isNot(isCanvasRenderingContext2D));
      src__matcher__expect.expect(bytes, src__matcher__operator_matchers.isNot(isElement));
      src__matcher__expect.expect(bytes, src__matcher__operator_matchers.isNot(isCanvasElement));
      src__matcher__expect.expect(bytes, src__matcher__operator_matchers.isNot(isImageData));
      src__matcher__expect.expect(bytes, isIntList);
      let span = html.Element.tag('span');
      src__matcher__expect.expect(span, isElement);
    }, VoidTodynamic()));
  };
  dart.fn(instance_of_test.main, VoidTodynamic());
  // Exports:
  exports.instance_of_test = instance_of_test;
});

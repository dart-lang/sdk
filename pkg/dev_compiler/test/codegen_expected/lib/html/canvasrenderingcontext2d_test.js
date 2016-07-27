dart_library.library('lib/html/canvasrenderingcontext2d_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__canvasrenderingcontext2d_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__numeric_matchers = unittest.src__matcher__numeric_matchers;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const canvasrenderingcontext2d_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.functionType(dart.void, [html.Event])))();
  let RectangleOfint = () => (RectangleOfint = dart.constFn(math.Rectangle$(core.int)))();
  let ListOfintAndListOfintTodynamic = () => (ListOfintAndListOfintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfint(), ListOfint()])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intAndintToListOfint = () => (intAndintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [core.int, core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let intAndintTobool = () => (intAndintTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int, core.int])))();
  let ListOfintAndintAndintToString = () => (ListOfintAndintAndintToString = dart.constFn(dart.definiteFunctionType(core.String, [ListOfint(), core.int, core.int])))();
  let boolToString = () => (boolToString = dart.constFn(dart.definiteFunctionType(core.String, [core.bool])))();
  let intAndint__Tovoid = () => (intAndint__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int], [core.bool])))();
  let intAndintTovoid = () => (intAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let EventTovoid$ = () => (EventTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  canvasrenderingcontext2d_test.checkPixel = function(pixel, expected) {
    src__matcher__expect.expect(pixel[dartx.get](0), src__matcher__numeric_matchers.closeTo(expected[dartx.get](0), 2));
    src__matcher__expect.expect(pixel[dartx.get](1), src__matcher__numeric_matchers.closeTo(expected[dartx.get](1), 2));
    src__matcher__expect.expect(pixel[dartx.get](2), src__matcher__numeric_matchers.closeTo(expected[dartx.get](2), 2));
    src__matcher__expect.expect(pixel[dartx.get](3), src__matcher__numeric_matchers.closeTo(expected[dartx.get](3), 2));
  };
  dart.fn(canvasrenderingcontext2d_test.checkPixel, ListOfintAndListOfintTodynamic());
  canvasrenderingcontext2d_test.canvas = null;
  canvasrenderingcontext2d_test.context = null;
  canvasrenderingcontext2d_test.otherCanvas = null;
  canvasrenderingcontext2d_test.otherContext = null;
  canvasrenderingcontext2d_test.video = null;
  canvasrenderingcontext2d_test.createCanvas = function() {
    canvasrenderingcontext2d_test.canvas = html.CanvasElement.new();
    dart.dput(canvasrenderingcontext2d_test.canvas, 'width', 100);
    dart.dput(canvasrenderingcontext2d_test.canvas, 'height', 100);
    canvasrenderingcontext2d_test.context = dart.dload(canvasrenderingcontext2d_test.canvas, 'context2D');
  };
  dart.fn(canvasrenderingcontext2d_test.createCanvas, VoidTovoid());
  canvasrenderingcontext2d_test.createOtherCanvas = function() {
    canvasrenderingcontext2d_test.otherCanvas = html.CanvasElement.new();
    dart.dput(canvasrenderingcontext2d_test.otherCanvas, 'width', 10);
    dart.dput(canvasrenderingcontext2d_test.otherCanvas, 'height', 10);
    canvasrenderingcontext2d_test.otherContext = dart.dload(canvasrenderingcontext2d_test.otherCanvas, 'context2D');
    dart.dput(canvasrenderingcontext2d_test.otherContext, 'fillStyle', "red");
    dart.dsend(canvasrenderingcontext2d_test.otherContext, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.otherCanvas, 'width'), dart.dload(canvasrenderingcontext2d_test.otherCanvas, 'height'));
  };
  dart.fn(canvasrenderingcontext2d_test.createOtherCanvas, VoidTovoid());
  canvasrenderingcontext2d_test.setupFunc = function() {
    canvasrenderingcontext2d_test.createCanvas();
    canvasrenderingcontext2d_test.createOtherCanvas();
    canvasrenderingcontext2d_test.video = html.VideoElement.new();
  };
  dart.fn(canvasrenderingcontext2d_test.setupFunc, VoidTovoid());
  canvasrenderingcontext2d_test.tearDownFunc = function() {
    canvasrenderingcontext2d_test.canvas = null;
    canvasrenderingcontext2d_test.context = null;
    canvasrenderingcontext2d_test.otherCanvas = null;
    canvasrenderingcontext2d_test.otherContext = null;
    canvasrenderingcontext2d_test.video = null;
  };
  dart.fn(canvasrenderingcontext2d_test.tearDownFunc, VoidTovoid());
  canvasrenderingcontext2d_test.readPixel = function(x, y) {
    let imageData = dart.dsend(canvasrenderingcontext2d_test.context, 'getImageData', x, y, 1, 1);
    return ListOfint()._check(dart.dload(imageData, 'data'));
  };
  dart.fn(canvasrenderingcontext2d_test.readPixel, intAndintToListOfint());
  canvasrenderingcontext2d_test.isPixelFilled = function(x, y) {
    return canvasrenderingcontext2d_test.readPixel(x, y)[dartx.any](dart.fn(p => p != 0, intTobool()));
  };
  dart.fn(canvasrenderingcontext2d_test.isPixelFilled, intAndintTobool());
  canvasrenderingcontext2d_test.pixelDataToString = function(data, x, y) {
    return dart.str`[${data[dartx.join](", ")}]`;
  };
  dart.fn(canvasrenderingcontext2d_test.pixelDataToString, ListOfintAndintAndintToString());
  canvasrenderingcontext2d_test._filled = function(v) {
    return dart.test(v) ? "filled" : "unfilled";
  };
  dart.fn(canvasrenderingcontext2d_test._filled, boolToString());
  canvasrenderingcontext2d_test.expectPixelFilled = function(x, y, filled) {
    if (filled === void 0) filled = true;
    src__matcher__expect.expect(canvasrenderingcontext2d_test.isPixelFilled(x, y), filled, {reason: dart.str`Pixel at (${x}, ${y}) was expected to` + dart.str` be: <${canvasrenderingcontext2d_test._filled(filled)}> but was: <${canvasrenderingcontext2d_test._filled(!dart.test(filled))}> with data: ` + dart.str`${canvasrenderingcontext2d_test.pixelDataToString(canvasrenderingcontext2d_test.readPixel(x, y), x, y)}`});
  };
  dart.fn(canvasrenderingcontext2d_test.expectPixelFilled, intAndint__Tovoid());
  canvasrenderingcontext2d_test.expectPixelUnfilled = function(x, y) {
    canvasrenderingcontext2d_test.expectPixelFilled(x, y, false);
  };
  dart.fn(canvasrenderingcontext2d_test.expectPixelUnfilled, intAndintTovoid());
  canvasrenderingcontext2d_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('pixel_manipulation', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      unittest$.test('setFillColorRgb', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setFillColorRgb', 255, 0, 255, 1);
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        src__matcher__expect.expect(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([255, 0, 255, 255]));
      }, VoidTodynamic()));
      unittest$.test('setFillColorHsl hue', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setFillColorHsl', 0, 100, 50);
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([255, 0, 0, 255]));
      }, VoidTodynamic()));
      unittest$.test('setFillColorHsl hue 2', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setFillColorHsl', 240, 100, 50);
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([0, 0, 255, 255]));
      }, VoidTodynamic()));
      unittest$.test('setFillColorHsl sat', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setFillColorHsl', 0, 0, 50);
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([127, 127, 127, 255]));
      }, VoidTodynamic()));
      unittest$.test('setStrokeColorRgb', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setStrokeColorRgb', 255, 0, 255, 1);
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 10);
        dart.dsend(canvasrenderingcontext2d_test.context, 'strokeRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        src__matcher__expect.expect(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([255, 0, 255, 255]));
      }, VoidTodynamic()));
      unittest$.test('setStrokeColorHsl hue', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setStrokeColorHsl', 0, 100, 50);
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 10);
        dart.dsend(canvasrenderingcontext2d_test.context, 'strokeRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        src__matcher__expect.expect(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([255, 0, 0, 255]));
      }, VoidTodynamic()));
      unittest$.test('setStrokeColorHsl hue 2', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setStrokeColorHsl', 240, 100, 50);
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 10);
        dart.dsend(canvasrenderingcontext2d_test.context, 'strokeRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        src__matcher__expect.expect(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([0, 0, 255, 255]));
      }, VoidTodynamic()));
      unittest$.test('setStrokeColorHsl sat', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'setStrokeColorHsl', 0, 0, 50);
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 10);
        dart.dsend(canvasrenderingcontext2d_test.context, 'strokeRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([127, 127, 127, 255]));
      }, VoidTodynamic()));
      unittest$.test('fillStyle', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', "red");
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([255, 0, 0, 255]));
      }, VoidTodynamic()));
      unittest$.test('strokeStyle', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'strokeStyle', "blue");
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 10);
        dart.dsend(canvasrenderingcontext2d_test.context, 'strokeRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        src__matcher__expect.expect(canvasrenderingcontext2d_test.readPixel(2, 2), JSArrayOfint().of([0, 0, 255, 255]));
      }, VoidTodynamic()));
      unittest$.test('fillStyle linearGradient', dart.fn(() => {
        let gradient = dart.dsend(canvasrenderingcontext2d_test.context, 'createLinearGradient', 0, 0, 20, 20);
        dart.dsend(gradient, 'addColorStop', 0, 'red');
        dart.dsend(gradient, 'addColorStop', 1, 'blue');
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', gradient);
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        src__matcher__expect.expect(html.CanvasGradient.is(dart.dload(canvasrenderingcontext2d_test.context, 'fillStyle')), src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
      unittest$.test('putImageData', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', 'green');
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        let expectedData = html.ImageData._check(dart.dsend(canvasrenderingcontext2d_test.context, 'getImageData', 0, 0, 10, 10));
        expectedData[dartx.data][dartx.set](0, 25);
        expectedData[dartx.data][dartx.set](1, 65);
        expectedData[dartx.data][dartx.set](2, 255);
        expectedData[dartx.data][dartx.set](3, 255);
        dart.dsend(canvasrenderingcontext2d_test.context, 'putImageData', expectedData, 0, 0);
        let resultingData = dart.dsend(canvasrenderingcontext2d_test.context, 'getImageData', 0, 0, 10, 10);
        src__matcher__expect.expect(dart.dload(resultingData, 'data'), expectedData[dartx.data]);
      }, VoidTodynamic()));
      unittest$.test('putImageData dirty rectangle', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', 'green');
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillRect', 0, 0, dart.dload(canvasrenderingcontext2d_test.canvas, 'width'), dart.dload(canvasrenderingcontext2d_test.canvas, 'height'));
        let drawnData = html.ImageData._check(dart.dsend(canvasrenderingcontext2d_test.context, 'getImageData', 0, 0, 10, 10));
        drawnData[dartx.data][dartx.set](0, 25);
        drawnData[dartx.data][dartx.set](1, 65);
        drawnData[dartx.data][dartx.set](2, 255);
        drawnData[dartx.data][dartx.set](3, 255);
        drawnData[dartx.data][dartx.set](2 * 4 + 0, 25);
        drawnData[dartx.data][dartx.set](2 * 4 + 1, 65);
        drawnData[dartx.data][dartx.set](2 * 4 + 2, 255);
        drawnData[dartx.data][dartx.set](2 * 4 + 3, 255);
        drawnData[dartx.data][dartx.set](7 * 4 + 0, 25);
        drawnData[dartx.data][dartx.set](7 * 4 + 1, 65);
        drawnData[dartx.data][dartx.set](7 * 4 + 2, 255);
        drawnData[dartx.data][dartx.set](7 * 4 + 3, 255);
        dart.dsend(canvasrenderingcontext2d_test.context, 'putImageData', drawnData, 0, 0, 1, 0, 5, 5);
        let expectedData = html.ImageData._check(dart.dsend(canvasrenderingcontext2d_test.context, 'createImageData', 10, 10));
        for (let i = 0; i < dart.notNull(expectedData[dartx.data][dartx.length]); i++) {
          switch (i[dartx['%']](4)) {
            case 0:
            {
              expectedData[dartx.data][dartx.set](i, 0);
              break;
            }
            case 1:
            {
              expectedData[dartx.data][dartx.set](i, 128);
              break;
            }
            case 2:
            {
              expectedData[dartx.data][dartx.set](i, 0);
              break;
            }
            case 3:
            {
              expectedData[dartx.data][dartx.set](i, 255);
              break;
            }
          }
        }
        expectedData[dartx.data][dartx.set](2 * 4 + 0, 25);
        expectedData[dartx.data][dartx.set](2 * 4 + 1, 65);
        expectedData[dartx.data][dartx.set](2 * 4 + 2, 255);
        expectedData[dartx.data][dartx.set](2 * 4 + 3, 255);
        let resultingData = dart.dsend(canvasrenderingcontext2d_test.context, 'getImageData', 0, 0, 10, 10);
        src__matcher__expect.expect(dart.dload(resultingData, 'data'), expectedData[dartx.data]);
      }, VoidTodynamic()));
      unittest$.test('putImageData throws with wrong number of arguments', dart.fn(() => {
        let expectedData = html.ImageData._check(dart.dsend(canvasrenderingcontext2d_test.context, 'getImageData', 0, 0, 10, 10));
        src__matcher__expect.expect(dart.fn(() => dart.dsend(canvasrenderingcontext2d_test.context, 'putImageData', expectedData, 0, 0, 1), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => dart.dsend(canvasrenderingcontext2d_test.context, 'putImageData', expectedData, 0, 0, 1, 1), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => dart.dsend(canvasrenderingcontext2d_test.context, 'putImageData', expectedData, 0, 0, 1, 1, 5), VoidTodynamic()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('arc', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      unittest$.test('default arc should be clockwise', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'beginPath');
        let r = 10;
        let cx = 20;
        let cy = 20;
        dart.dsend(canvasrenderingcontext2d_test.context, 'arc', cx, cy, r, 0, math.PI / 2);
        dart.dput(canvasrenderingcontext2d_test.context, 'strokeStyle', 'green');
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 2);
        dart.dsend(canvasrenderingcontext2d_test.context, 'stroke');
        canvasrenderingcontext2d_test.expectPixelUnfilled(cx, cy);
        canvasrenderingcontext2d_test.expectPixelFilled(cx + r, cy, true);
        canvasrenderingcontext2d_test.expectPixelFilled(cx, cy + r, true);
        canvasrenderingcontext2d_test.expectPixelFilled(cx - r, cy, false);
        canvasrenderingcontext2d_test.expectPixelFilled(cx, cy - r, false);
        canvasrenderingcontext2d_test.expectPixelFilled((cx + r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy + r / dart.notNull(math.SQRT2))[dartx.toInt](), true);
        canvasrenderingcontext2d_test.expectPixelFilled((cx - r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy + r / dart.notNull(math.SQRT2))[dartx.toInt](), false);
        canvasrenderingcontext2d_test.expectPixelFilled((cx - r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy - r / dart.notNull(math.SQRT2))[dartx.toInt](), false);
        canvasrenderingcontext2d_test.expectPixelFilled((cx + r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy - r / dart.notNull(math.SQRT2))[dartx.toInt](), false);
      }, VoidTodynamic()));
      unittest$.test('arc anticlockwise', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'beginPath');
        let r = 10;
        let cx = 20;
        let cy = 20;
        dart.dsend(canvasrenderingcontext2d_test.context, 'arc', cx, cy, r, 0.1, math.PI / 2 - 0.1, true);
        dart.dput(canvasrenderingcontext2d_test.context, 'strokeStyle', 'green');
        dart.dput(canvasrenderingcontext2d_test.context, 'lineWidth', 2);
        dart.dsend(canvasrenderingcontext2d_test.context, 'stroke');
        canvasrenderingcontext2d_test.expectPixelUnfilled(cx, cy);
        canvasrenderingcontext2d_test.expectPixelFilled(cx + r, cy, true);
        canvasrenderingcontext2d_test.expectPixelFilled(cx, cy + r, true);
        canvasrenderingcontext2d_test.expectPixelFilled(cx - r, cy, true);
        canvasrenderingcontext2d_test.expectPixelFilled(cx, cy - r, true);
        canvasrenderingcontext2d_test.expectPixelFilled((cx + r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy + r / dart.notNull(math.SQRT2))[dartx.toInt](), false);
        canvasrenderingcontext2d_test.expectPixelFilled((cx - r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy + r / dart.notNull(math.SQRT2))[dartx.toInt](), true);
        canvasrenderingcontext2d_test.expectPixelFilled((cx - r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy - r / dart.notNull(math.SQRT2))[dartx.toInt](), true);
        canvasrenderingcontext2d_test.expectPixelFilled((cx + r / dart.notNull(math.SQRT2))[dartx.toInt](), (cy - r / dart.notNull(math.SQRT2))[dartx.toInt](), true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('drawImage_image_element', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      unittest$.test('with 3 params', dart.fn(() => {
        let dataUrl = dart.dsend(canvasrenderingcontext2d_test.otherCanvas, 'toDataUrl', 'image/gif');
        let img = html.ImageElement.new();
        img[dartx.onLoad].listen(EventTovoid()._check(unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImage', img, 50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
          canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
          canvasrenderingcontext2d_test.expectPixelUnfilled(60, 60);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
        }, dynamicTodynamic()))));
        img[dartx.onError].listen(dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, EventTovoid$()));
        img[dartx.src] = core.String._check(dataUrl);
      }, VoidTodynamic()));
      unittest$.test('with 5 params', dart.fn(() => {
        let dataUrl = dart.dsend(canvasrenderingcontext2d_test.otherCanvas, 'toDataUrl', 'image/gif');
        let img = html.ImageElement.new();
        img[dartx.onLoad].listen(EventTovoid()._check(unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', img, new (RectangleOfint())(50, 50, 20, 20));
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
          canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
          canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
          canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
        }, dynamicTodynamic()))));
        img[dartx.onError].listen(dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, EventTovoid$()));
        img[dartx.src] = core.String._check(dataUrl);
      }, VoidTodynamic()));
      unittest$.test('with 9 params', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.otherContext, 'fillStyle', "blue");
        dart.dsend(canvasrenderingcontext2d_test.otherContext, 'fillRect', 5, 5, 5, 5);
        let dataUrl = dart.dsend(canvasrenderingcontext2d_test.otherCanvas, 'toDataUrl', 'image/gif');
        let img = html.ImageElement.new();
        img[dartx.onLoad].listen(EventTovoid()._check(unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', img, new (RectangleOfint())(50, 50, 20, 20), {sourceRect: new (RectangleOfint())(2, 2, 6, 6)});
          canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(50, 50), JSArrayOfint().of([255, 0, 0, 255]));
          canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(55, 55), JSArrayOfint().of([255, 0, 0, 255]));
          canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(60, 50), JSArrayOfint().of([255, 0, 0, 255]));
          canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(65, 65), JSArrayOfint().of([0, 0, 255, 255]));
          canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(69, 69), JSArrayOfint().of([0, 0, 255, 255]));
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
          canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
          canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
          canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
        }, dynamicTodynamic()))));
        img[dartx.onError].listen(dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, EventTovoid$()));
        img[dartx.src] = core.String._check(dataUrl);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    let mp4VideoUrl = '/root_dart/tests/html/small.mp4';
    let webmVideoUrl = '/root_dart/tests/html/small.webm';
    let mp4VideoDataUrl = 'data:video/mp4;base64,AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAA' + 'AIZnJlZQAAAsdtZGF0AAACmwYF//+X3EXpvebZSLeWLNgg2SPu73gyNjQgLSBjb3JlID' + 'EyMCByMjE1MSBhM2Y0NDA3IC0gSC4yNjQvTVBFRy00IEFWQyBjb2RlYyAtIENvcHlsZW' + 'Z0IDIwMDMtMjAxMSAtIGh0dHA6Ly93d3cudmlkZW9sYW4ub3JnL3gyNjQuaHRtbCAtIG' + '9wdGlvbnM6IGNhYmFjPTEgcmVmPTMgZGVibG9jaz0xOjA6MCBhbmFseXNlPTB4MToweD' + 'ExMSBtZT1oZXggc3VibWU9NyBwc3k9MSBwc3lfcmQ9MS4wMDowLjAwIG1peGVkX3JlZj' + '0wIG1lX3JhbmdlPTE2IGNocm9tYV9tZT0xIHRyZWxsaXM9MSA4eDhkY3Q9MCBjcW09MC' + 'BkZWFkem9uZT0yMSwxMSBmYXN0X3Bza2lwPTEgY2hyb21hX3FwX29mZnNldD0tMiB0aH' + 'JlYWRzPTE4IHNsaWNlZF90aHJlYWRzPTAgbnI9MCBkZWNpbWF0ZT0xIGludGVybGFjZW' + 'Q9MCBibHVyYXlfY29tcGF0PTAgY29uc3RyYWluZWRfaW50cmE9MCBiZnJhbWVzPTMgYl' + '9weXJhbWlkPTAgYl9hZGFwdD0xIGJfYmlhcz0wIGRpcmVjdD0xIHdlaWdodGI9MCBvcG' + 'VuX2dvcD0xIHdlaWdodHA9MiBrZXlpbnQ9MjUwIGtleWludF9taW49MjUgc2NlbmVjdX' + 'Q9NDAgaW50cmFfcmVmcmVzaD0wIHJjX2xvb2thaGVhZD00MCByYz1jcmYgbWJ0cmVlPT' + 'EgY3JmPTUxLjAgcWNvbXA9MC42MCBxcG1pbj0wIHFwbWF4PTY5IHFwc3RlcD00IGlwX3' + 'JhdGlvPTEuMjUgYXE9MToxLjAwAIAAAAARZYiEB//3aoK5/tP9+8yeuIEAAAAHQZoi2P' + '/wgAAAAzxtb292AAAAbG12aGQAAAAAAAAAAAAAAAAAAAPoAAAAUAABAAABAAAAAAAAAA' + 'AAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAA' + 'AAAAAAAAAAAAAAAAAAAAACAAAAGGlvZHMAAAAAEICAgAcAT/////7/AAACUHRyYWsAAA' + 'BcdGtoZAAAAA8AAAAAAAAAAAAAAAEAAAAAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAQAAAA' + 'AAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAACAAAAAgAAAAAACRlZHRzAAAAHG' + 'Vsc3QAAAAAAAAAAQAAAFAAAAABAAEAAAAAAchtZGlhAAAAIG1kaGQAAAAAAAAAAAAAAA' + 'AAAAAZAAAAAlXEAAAAAAAtaGRscgAAAAAAAAAAdmlkZQAAAAAAAAAAAAAAAFZpZGVvSG' + 'FuZGxlcgAAAAFzbWluZgAAABR2bWhkAAAAAQAAAAAAAAAAAAAAJGRpbmYAAAAcZHJlZg' + 'AAAAAAAAABAAAADHVybCAAAAABAAABM3N0YmwAAACXc3RzZAAAAAAAAAABAAAAh2F2Yz' + 'EAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAACAAIAEgAAABIAAAAAAAAAAEAAAAAAAAAAA' + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY//8AAAAxYXZjQwFNQAr/4QAYZ01ACuiPyy' + '4C2QAAAwABAAADADIPEiUSAQAGaOvAZSyAAAAAGHN0dHMAAAAAAAAAAQAAAAIAAAABAA' + 'AAFHN0c3MAAAAAAAAAAQAAAAEAAAAYY3R0cwAAAAAAAAABAAAAAgAAAAEAAAAcc3RzYw' + 'AAAAAAAAABAAAAAQAAAAEAAAABAAAAHHN0c3oAAAAAAAAAAAAAAAIAAAK0AAAACwAAAB' + 'hzdGNvAAAAAAAAAAIAAAAwAAAC5AAAAGB1ZHRhAAAAWG1ldGEAAAAAAAAAIWhkbHIAAA' + 'AAAAAAAG1kaXJhcHBsAAAAAAAAAAAAAAAAK2lsc3QAAAAjqXRvbwAAABtkYXRhAAAAAQ' + 'AAAABMYXZmNTMuMjEuMQ==';
    let webmVideoDataUrl = 'data:video/webm;base64,GkXfowEAAAAAAAAfQoaBAUL3gQFC8oEEQvOBCEKChHdlY' + 'm1Ch4ECQoWBAhhTgGcBAAAAAAAB/hFNm3RALE27i1OrhBVJqWZTrIHfTbuMU6uEFlSua' + '1OsggEsTbuMU6uEHFO7a1OsggHk7AEAAAAAAACkAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVSalmAQAAAAAAA' + 'EEq17GDD0JATYCLTGF2ZjUzLjIxLjFXQYtMYXZmNTMuMjEuMXOkkJatuHwTJ7cvFLSzB' + 'Smxbp5EiYhAVAAAAAAAABZUrmsBAAAAAAAAR64BAAAAAAAAPteBAXPFgQGcgQAitZyDd' + 'W5khoVWX1ZQOIOBASPjg4QCYloA4AEAAAAAAAASsIEIuoEIVLCBCFS6gQhUsoEDH0O2d' + 'QEAAAAAAABZ54EAo72BAACA8AIAnQEqCAAIAABHCIWFiIWEiAICAnWqA/gD+gINTRgA/' + 'v0hRf/kb+PnRv/I4//8WE8DijI//FRAo5WBACgAsQEAARAQABgAGFgv9AAIAAAcU7trA' + 'QAAAAAAAA67jLOBALeH94EB8YIBfw==';
    unittest$.group('drawImage_video_element', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      unittest$.test('with 3 params', dart.fn(() => {
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onCanPlay'), 'listen', unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImage', canvasrenderingcontext2d_test.video, 50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(54, 54);
          canvasrenderingcontext2d_test.expectPixelFilled(57, 57);
          canvasrenderingcontext2d_test.expectPixelUnfilled(58, 58);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
        }, dynamicTodynamic())));
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onError'), 'listen', dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, dynamicTodynamic()));
        if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/webm; codecs="vp8.0, vorbis"', ''), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', webmVideoUrl);
        } else if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', mp4VideoUrl);
        } else {
          html.window[dartx.console].log('Video is not supported on this system.');
        }
      }, VoidTodynamic()));
      unittest$.test('with 5 params', dart.fn(() => {
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onCanPlay'), 'listen', unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', canvasrenderingcontext2d_test.video, new (RectangleOfint())(50, 50, 20, 20));
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
          canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
          canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
          canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
        }, dynamicTodynamic())));
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onError'), 'listen', dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, dynamicTodynamic()));
        if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/webm; codecs="vp8.0, vorbis"', ''), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', webmVideoUrl);
        } else if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', mp4VideoUrl);
        } else {
          html.window[dartx.console].log('Video is not supported on this system.');
        }
      }, VoidTodynamic()));
      unittest$.test('with 9 params', dart.fn(() => {
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onCanPlay'), 'listen', unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', canvasrenderingcontext2d_test.video, new (RectangleOfint())(50, 50, 20, 20), {sourceRect: new (RectangleOfint())(2, 2, 6, 6)});
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
          canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
          canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
          canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
        }, dynamicTodynamic())));
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onError'), 'listen', dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, dynamicTodynamic()));
        if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/webm; codecs="vp8.0, vorbis"', ''), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', webmVideoUrl);
        } else if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', mp4VideoUrl);
        } else {
          html.window[dartx.console].log('Video is not supported on this system.');
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('drawImage_video_element_dataUrl', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      unittest$.test('with 9 params', dart.fn(() => {
        canvasrenderingcontext2d_test.video = html.VideoElement.new();
        canvasrenderingcontext2d_test.canvas = html.CanvasElement.new();
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onCanPlay'), 'listen', unittest$.expectAsync(dart.fn(_ => {
          dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', canvasrenderingcontext2d_test.video, new (RectangleOfint())(50, 50, 20, 20), {sourceRect: new (RectangleOfint())(2, 2, 6, 6)});
          canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
          canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
          canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
          canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
          canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
          canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
          canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
          canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
        }, dynamicTodynamic())));
        dart.dsend(dart.dload(canvasrenderingcontext2d_test.video, 'onError'), 'listen', dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, dynamicTodynamic()));
        if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/webm; codecs="vp8.0, vorbis"', ''), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', webmVideoDataUrl);
        } else if (!dart.equals(dart.dsend(canvasrenderingcontext2d_test.video, 'canPlayType', 'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null), '')) {
          dart.dput(canvasrenderingcontext2d_test.video, 'src', mp4VideoDataUrl);
        } else {
          html.window[dartx.console].log('Video is not supported on this system.');
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('drawImage_canvas_element', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      unittest$.test('with 3 params', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'drawImage', canvasrenderingcontext2d_test.otherCanvas, 50, 50);
        canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
        canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
        canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
        canvasrenderingcontext2d_test.expectPixelUnfilled(60, 60);
        canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
        canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
      }, VoidTodynamic()));
      unittest$.test('with 5 params', dart.fn(() => {
        dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', canvasrenderingcontext2d_test.otherCanvas, new (RectangleOfint())(50, 50, 20, 20));
        canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
        canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
        canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
        canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
        canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
        canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
        canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
        canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
      }, VoidTodynamic()));
      unittest$.test('with 9 params', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.otherContext, 'fillStyle', "blue");
        dart.dsend(canvasrenderingcontext2d_test.otherContext, 'fillRect', 5, 5, 5, 5);
        dart.dsend(canvasrenderingcontext2d_test.context, 'drawImageToRect', canvasrenderingcontext2d_test.otherCanvas, new (RectangleOfint())(50, 50, 20, 20), {sourceRect: new (RectangleOfint())(2, 2, 6, 6)});
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(50, 50), JSArrayOfint().of([255, 0, 0, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(55, 55), JSArrayOfint().of([255, 0, 0, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(60, 50), JSArrayOfint().of([255, 0, 0, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(65, 65), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(69, 69), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.expectPixelFilled(50, 50);
        canvasrenderingcontext2d_test.expectPixelFilled(55, 55);
        canvasrenderingcontext2d_test.expectPixelFilled(59, 59);
        canvasrenderingcontext2d_test.expectPixelFilled(60, 60);
        canvasrenderingcontext2d_test.expectPixelFilled(69, 69);
        canvasrenderingcontext2d_test.expectPixelUnfilled(70, 70);
        canvasrenderingcontext2d_test.expectPixelUnfilled(0, 0);
        canvasrenderingcontext2d_test.expectPixelUnfilled(80, 80);
      }, VoidTodynamic()));
      unittest$.test('createImageData', dart.fn(() => {
        let imageData = dart.dsend(canvasrenderingcontext2d_test.context, 'createImageData', 15, 15);
        src__matcher__expect.expect(dart.dload(imageData, 'width'), 15);
        src__matcher__expect.expect(dart.dload(imageData, 'height'), 15);
        let other = dart.dsend(canvasrenderingcontext2d_test.context, 'createImageDataFromImageData', imageData);
        src__matcher__expect.expect(dart.dload(other, 'width'), 15);
        src__matcher__expect.expect(dart.dload(other, 'height'), 15);
      }, VoidTodynamic()));
      unittest$.test('createPattern', dart.fn(() => {
        let pattern = dart.dsend(canvasrenderingcontext2d_test.context, 'createPattern', html.CanvasElement.new(), '');
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('fillText', dart.fn(() => {
      unittest$.setUp(canvasrenderingcontext2d_test.setupFunc);
      unittest$.tearDown(canvasrenderingcontext2d_test.tearDownFunc);
      let x = 20;
      let y = 20;
      unittest$.test('without maxWidth', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'font', '40pt Garamond');
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', 'blue');
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillText', '█', x, y);
        let width = dart.dsend(dart.dload(dart.dsend(canvasrenderingcontext2d_test.context, 'measureText', '█'), 'width'), 'ceil');
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(x, y), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(x + 10, y), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.expectPixelUnfilled(x - 10, y);
        canvasrenderingcontext2d_test.expectPixelFilled(x, y);
        canvasrenderingcontext2d_test.expectPixelFilled(x + 10, y);
        canvasrenderingcontext2d_test.expectPixelFilled(dart.asInt(x + dart.notNull(core.num._check(width)) - 2), y);
        canvasrenderingcontext2d_test.expectPixelUnfilled(dart.asInt(x + dart.notNull(core.num._check(width)) + 1), y);
      }, VoidTodynamic()));
      unittest$.test('with maxWidth null', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'font', '40pt Garamond');
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', 'blue');
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillText', '█', x, y, null);
        let width = dart.dsend(dart.dload(dart.dsend(canvasrenderingcontext2d_test.context, 'measureText', '█'), 'width'), 'ceil');
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(x, y), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(x + 10, y), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.expectPixelUnfilled(x - 10, y);
        canvasrenderingcontext2d_test.expectPixelFilled(x, y);
        canvasrenderingcontext2d_test.expectPixelFilled(x + 10, y);
        canvasrenderingcontext2d_test.expectPixelFilled(dart.asInt(x + dart.notNull(core.num._check(width)) - 2), y);
        canvasrenderingcontext2d_test.expectPixelUnfilled(dart.asInt(x + dart.notNull(core.num._check(width)) + 1), y);
      }, VoidTodynamic()));
      unittest$.test('with maxWidth defined', dart.fn(() => {
        dart.dput(canvasrenderingcontext2d_test.context, 'font', '40pt Garamond');
        dart.dput(canvasrenderingcontext2d_test.context, 'fillStyle', 'blue');
        let maxWidth = 20;
        dart.dsend(canvasrenderingcontext2d_test.context, 'fillText', '█', x, y, maxWidth);
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(x, y), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.checkPixel(canvasrenderingcontext2d_test.readPixel(x + 10, y), JSArrayOfint().of([0, 0, 255, 255]));
        canvasrenderingcontext2d_test.expectPixelUnfilled(x - 10, y);
        canvasrenderingcontext2d_test.expectPixelUnfilled(x + maxWidth + 1, y);
        canvasrenderingcontext2d_test.expectPixelUnfilled(x + maxWidth + 20, y);
        canvasrenderingcontext2d_test.expectPixelFilled(x, y);
        canvasrenderingcontext2d_test.expectPixelFilled(x + 10, y);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(canvasrenderingcontext2d_test.main, VoidTodynamic());
  // Exports:
  exports.canvasrenderingcontext2d_test = canvasrenderingcontext2d_test;
});

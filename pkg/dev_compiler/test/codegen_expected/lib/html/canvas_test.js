dart_library.library('lib/html/canvas_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__canvas_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const canvas_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.functionType(dart.void, [html.Event])))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let EventTovoid$ = () => (EventTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  let ListOfintAndintAndListOfintTovoid = () => (ListOfintAndintAndListOfintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfint(), core.int, ListOfint()])))();
  canvas_test.main = function() {
    let canvas = null;
    let context = null;
    let width = 100;
    let height = 100;
    canvas = html.CanvasElement.new({width: width, height: height});
    html.document[dartx.body][dartx.append](canvas);
    context = canvas[dartx.context2D];
    html_config.useHtmlConfiguration();
    unittest$.test('CreateImageData', dart.fn(() => {
      let image = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height]);
      let data = image[dartx.data];
      src__matcher__expect.expect(data, src__matcher__core_matchers.hasLength(40000));
      canvas_test.checkPixel(data, 0, JSArrayOfint().of([0, 0, 0, 0]));
      canvas_test.checkPixel(data, width * height - 1, JSArrayOfint().of([0, 0, 0, 0]));
      data[dartx.set](100, 200);
      src__matcher__expect.expect(data[dartx.get](100), src__matcher__core_matchers.equals(200));
    }, VoidTodynamic()));
    unittest$.test('toDataUrl', dart.fn(() => {
      let canvas = html.CanvasElement.new({width: 100, height: 100});
      let context = canvas[dartx.context2D];
      context[dartx.fillStyle] = 'red';
      context[dartx.fill]();
      let url = canvas[dartx.toDataUrl]();
      let img = html.ImageElement.new();
      img[dartx.onLoad].listen(EventTovoid()._check(unittest$.expectAsync(dart.fn(_ => {
        src__matcher__expect.expect(img[dartx.complete], true);
      }, dynamicTodynamic()))));
      img[dartx.onError].listen(dart.fn(_ => {
        src__matcher__expect.fail('URL failed to load.');
      }, EventTovoid$()));
      img[dartx.src] = url;
    }, VoidTodynamic()));
  };
  dart.fn(canvas_test.main, VoidTodynamic());
  canvas_test.checkPixel = function(data, offset, rgba) {
    offset = dart.notNull(offset) * 4;
    for (let i = 0; i < 4; ++i) {
      src__matcher__expect.expect(data[dartx.get](dart.notNull(offset) + i), src__matcher__core_matchers.equals(rgba[dartx.get](i)));
    }
  };
  dart.fn(canvas_test.checkPixel, ListOfintAndintAndListOfintTovoid());
  // Exports:
  exports.canvas_test = canvas_test;
});

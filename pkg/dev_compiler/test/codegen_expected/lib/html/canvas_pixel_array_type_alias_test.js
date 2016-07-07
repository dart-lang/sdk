dart_library.library('lib/html/canvas_pixel_array_type_alias_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__canvas_pixel_array_type_alias_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const canvas_pixel_array_type_alias_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ListOfintAndintAndListOfintTovoid = () => (ListOfintAndintAndListOfintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfint(), core.int, ListOfint()])))();
  canvas_pixel_array_type_alias_test.inscrutable = null;
  canvas_pixel_array_type_alias_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    canvas_pixel_array_type_alias_test.inscrutable = dart.fn(x => x, dynamicTodynamic());
    let width = 100;
    let height = 100;
    let canvas = html.CanvasElement.new({width: width, height: height});
    html.document[dartx.body][dartx.append](canvas);
    let context = canvas[dartx.context2D];
    unittest$.group('basic', dart.fn(() => {
      unittest$.test('CreateImageData', dart.fn(() => {
        let image = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height]);
        let data = image[dartx.data];
        src__matcher__expect.expect(ListOfint().is(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)), src__matcher__core_matchers.isTrue, {reason: 'canvas array type'});
        src__matcher__expect.expect(data, src__matcher__core_matchers.hasLength(40000));
        canvas_pixel_array_type_alias_test.checkPixel(data, 0, JSArrayOfint().of([0, 0, 0, 0]));
        canvas_pixel_array_type_alias_test.checkPixel(data, width * height - 1, JSArrayOfint().of([0, 0, 0, 0]));
        data[dartx.set](100, 200);
        src__matcher__expect.expect(data[dartx.get](100), src__matcher__core_matchers.equals(200));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('types1', dart.fn(() => {
      unittest$.test('isList', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(core.List.is(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)), true);
      }, VoidTodynamic()));
      unittest$.test('isListT_pos', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(ListOfint().is(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)), true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('types2', dart.fn(() => {
      unittest$.test('isListT_neg', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(ListOfString().is(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)), false);
      }, VoidTodynamic()));
      unittest$.test('isUint8ClampedList', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(typed_data.Uint8ClampedList.is(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)), true);
      }, VoidTodynamic()));
      unittest$.test('consistent_isUint8ClampedList', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(typed_data.Uint8ClampedList.is(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)) == typed_data.Uint8ClampedList.is(data), src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
      unittest$.test('consistent_runtimeType', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(dart.equals(dart.runtimeType(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data)), dart.runtimeType(data)), src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('types2_runtimeTypeName', dart.fn(() => {
      unittest$.test('runtimeTypeName', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(dart.str`${dart.runtimeType(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data))}`, 'Uint8ClampedList');
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('typed_data', dart.fn(() => {
      unittest$.test('elementSizeInBytes', dart.fn(() => {
        let data = context[dartx.createImageData](canvas[dartx.width], canvas[dartx.height])[dartx.data];
        src__matcher__expect.expect(dart.dload(dart.dcall(canvas_pixel_array_type_alias_test.inscrutable, data), 'elementSizeInBytes'), 1);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(canvas_pixel_array_type_alias_test.main, VoidTodynamic());
  canvas_pixel_array_type_alias_test.checkPixel = function(data, offset, rgba) {
    offset = dart.notNull(offset) * 4;
    for (let i = 0; i < 4; ++i) {
      src__matcher__expect.expect(rgba[dartx.get](i), src__matcher__core_matchers.equals(data[dartx.get](dart.notNull(offset) + i)));
    }
  };
  dart.fn(canvas_pixel_array_type_alias_test.checkPixel, ListOfintAndintAndListOfintTovoid());
  // Exports:
  exports.canvas_pixel_array_type_alias_test = canvas_pixel_array_type_alias_test;
});

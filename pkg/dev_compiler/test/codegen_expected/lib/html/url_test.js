dart_library.library('lib/html/url_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__url_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__numeric_matchers = unittest.src__matcher__numeric_matchers;
  const src__matcher__string_matchers = unittest.src__matcher__string_matchers;
  const url_test = Object.create(null);
  let JSArrayOfUint8List = () => (JSArrayOfUint8List = dart.constFn(_interceptors.JSArray$(typed_data.Uint8List)))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.functionType(dart.void, [html.Event])))();
  let VoidToBlob = () => (VoidToBlob = dart.constFn(dart.definiteFunctionType(html.Blob, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let EventTovoid$ = () => (EventTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  url_test.main = function() {
    html_config.useHtmlConfiguration();
    function createImageBlob() {
      let canvas = html.CanvasElement.new();
      canvas[dartx.width] = 100;
      canvas[dartx.height] = 100;
      let context = canvas[dartx.context2D];
      context[dartx.fillStyle] = 'red';
      context[dartx.fillRect](0, 0, canvas[dartx.width], canvas[dartx.height]);
      let dataUri = canvas[dartx.toDataUrl]('image/png');
      let byteString = html.window[dartx.atob](dataUri[dartx.split](',')[dartx.get](1));
      let mimeString = dataUri[dartx.split](',')[dartx.get](0)[dartx.split](':')[dartx.get](1)[dartx.split](';')[dartx.get](0);
      let arrayBuffer = typed_data.Uint8List.new(byteString[dartx.length]);
      let dataArray = typed_data.Uint8List.view(arrayBuffer[dartx.buffer]);
      for (let i = 0; i < dart.notNull(byteString[dartx.length]); i++) {
        dataArray[dartx.set](i, byteString[dartx.codeUnitAt](i));
      }
      let blob = html.Blob.new(JSArrayOfUint8List().of([arrayBuffer]), 'image/png');
      return blob;
    }
    dart.fn(createImageBlob, VoidToBlob());
    unittest$.group('blob', dart.fn(() => {
      unittest$.test('createObjectUrlFromBlob', dart.fn(() => {
        let blob = createImageBlob();
        let url = html.Url.createObjectUrlFromBlob(blob);
        src__matcher__expect.expect(url[dartx.length], src__matcher__numeric_matchers.greaterThan(0));
        src__matcher__expect.expect(url, src__matcher__string_matchers.startsWith('blob:'));
        let img = html.ImageElement.new();
        img[dartx.onLoad].listen(EventTovoid()._check(unittest$.expectAsync(dart.fn(_ => {
          src__matcher__expect.expect(img[dartx.complete], true);
        }, dynamicTodynamic()))));
        img[dartx.onError].listen(dart.fn(_ => {
          src__matcher__expect.fail('URL failed to load.');
        }, EventTovoid$()));
        img[dartx.src] = url;
      }, VoidTodynamic()));
      unittest$.test('revokeObjectUrl', dart.fn(() => {
        let blob = createImageBlob();
        let url = html.Url.createObjectUrlFromBlob(blob);
        src__matcher__expect.expect(url, src__matcher__string_matchers.startsWith('blob:'));
        html.Url.revokeObjectUrl(url);
        let img = html.ImageElement.new();
        img[dartx.onError].listen(EventTovoid()._check(unittest$.expectAsync(dart.fn(_ => {
        }, dynamicTodynamic()))));
        img[dartx.onLoad].listen(dart.fn(_ => {
          src__matcher__expect.fail('URL should not have loaded.');
        }, EventTovoid$()));
        img[dartx.src] = url;
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(url_test.main, VoidTodynamic());
  // Exports:
  exports.url_test = url_test;
});

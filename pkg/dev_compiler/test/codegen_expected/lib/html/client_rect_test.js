dart_library.library('lib/html/client_rect_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__client_rect_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const client_rect_test = Object.create(null);
  let RectangleOfnum = () => (RectangleOfnum = dart.constFn(math.Rectangle$(core.num)))();
  let ListOfRectangleOfnum = () => (ListOfRectangleOfnum = dart.constFn(core.List$(RectangleOfnum())))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidToElement = () => (VoidToElement = dart.constFn(dart.definiteFunctionType(html.Element, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  client_rect_test.main = function() {
    let isRectList = src__matcher__core_matchers.predicate(dart.fn(x => ListOfRectangleOfnum().is(x), dynamicTobool()), 'is a List<Rectangle>');
    function insertTestDiv() {
      let element = html.Element.tag('div');
      element[dartx.innerHtml] = '    A large block of text should go here. Click this\n    block of text multiple times to see each line\n    highlight with every click of the mouse button.\n    ';
      html.document[dartx.body][dartx.append](element);
      return element;
    }
    dart.fn(insertTestDiv, VoidToElement());
    html_config.useHtmlConfiguration();
    unittest$.test("ClientRectList test", dart.fn(() => {
      insertTestDiv();
      let range = html.Range.new();
      let rects = range[dartx.getClientRects]();
      src__matcher__expect.expect(rects, isRectList);
    }, VoidTodynamic()));
  };
  dart.fn(client_rect_test.main, VoidTodynamic());
  // Exports:
  exports.client_rect_test = client_rect_test;
});

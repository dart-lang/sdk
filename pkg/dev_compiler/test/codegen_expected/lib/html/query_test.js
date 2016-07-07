dart_library.library('lib/html/query_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__query_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const query_test = Object.create(null);
  let JSArrayOfNode = () => (JSArrayOfNode = dart.constFn(_interceptors.JSArray$(html.Node)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  query_test.main = function() {
    html_config.useHtmlConfiguration();
    let div = html.DivElement.new();
    let canvas = html.CanvasElement.new({width: 200, height: 200});
    canvas[dartx.id] = 'testcanvas';
    let element = html.Element.html("<div><br/><img/><input/><img/></div>");
    html.document[dartx.body][dartx.nodes][dartx.addAll](JSArrayOfNode().of([div, canvas, element]));
    let isCanvasElement = src__matcher__core_matchers.predicate(dart.fn(x => html.CanvasElement.is(x), dynamicTobool()), 'is a CanvasElement');
    let isImageElement = src__matcher__core_matchers.predicate(dart.fn(x => html.ImageElement.is(x), dynamicTobool()), 'is an ImageElement');
    unittest$.test('query', dart.fn(() => {
      let e = html.query('#testcanvas');
      src__matcher__expect.expect(e, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(e[dartx.id], 'testcanvas');
      src__matcher__expect.expect(e, isCanvasElement);
      src__matcher__expect.expect(e, canvas);
    }, VoidTodynamic()));
    unittest$.test('query (None)', dart.fn(() => {
      let e = html.query('#nothere');
      src__matcher__expect.expect(e, src__matcher__core_matchers.isNull);
    }, VoidTodynamic()));
    unittest$.test('queryAll (One)', dart.fn(() => {
      let l = html.queryAll('canvas');
      src__matcher__expect.expect(l[dartx.length], 1);
      src__matcher__expect.expect(l[dartx.get](0), canvas);
    }, VoidTodynamic()));
    unittest$.test('queryAll (Multiple)', dart.fn(() => {
      let l = html.queryAll('img');
      src__matcher__expect.expect(l[dartx.length], 2);
      src__matcher__expect.expect(l[dartx.get](0), isImageElement);
      src__matcher__expect.expect(l[dartx.get](1), isImageElement);
      src__matcher__expect.expect(l[dartx.get](0), src__matcher__operator_matchers.isNot(src__matcher__core_matchers.equals(l[dartx.get](1))));
    }, VoidTodynamic()));
    unittest$.test('queryAll (None)', dart.fn(() => {
      let l = html.queryAll('video');
      src__matcher__expect.expect(l[dartx.isEmpty], src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
  };
  dart.fn(query_test.main, VoidTodynamic());
  // Exports:
  exports.query_test = query_test;
});

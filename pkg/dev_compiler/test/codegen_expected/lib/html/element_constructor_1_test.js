dart_library.library('lib/html/element_constructor_1_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_constructor_1_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__string_matchers = unittest.src__matcher__string_matchers;
  const element_constructor_1_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  element_constructor_1_test.main = function() {
    html_config.useHtmlConfiguration();
    let isAnchorElement = src__matcher__core_matchers.predicate(dart.fn(x => html.AnchorElement.is(x), dynamicTobool()), 'is an AnchorElement');
    let isAreaElement = src__matcher__core_matchers.predicate(dart.fn(x => html.AreaElement.is(x), dynamicTobool()), 'is an AreaElement');
    let isDivElement = src__matcher__core_matchers.predicate(dart.fn(x => html.DivElement.is(x), dynamicTobool()), 'is a DivElement');
    let isCanvasElement = src__matcher__core_matchers.predicate(dart.fn(x => html.CanvasElement.is(x), dynamicTobool()), 'is a CanvasElement');
    let isParagraphElement = src__matcher__core_matchers.predicate(dart.fn(x => html.ParagraphElement.is(x), dynamicTobool()), 'is a ParagraphElement');
    let isSpanElement = src__matcher__core_matchers.predicate(dart.fn(x => html.SpanElement.is(x), dynamicTobool()), 'is a SpanElement');
    let isSelectElement = src__matcher__core_matchers.predicate(dart.fn(x => html.SelectElement.is(x), dynamicTobool()), 'is a SelectElement');
    unittest$.test('anchor1', dart.fn(() => {
      let e = html.AnchorElement.new();
      src__matcher__expect.expect(e, isAnchorElement);
    }, VoidTodynamic()));
    unittest$.test('anchor2', dart.fn(() => {
      let e = html.AnchorElement.new({href: '#blah'});
      src__matcher__expect.expect(e, isAnchorElement);
      src__matcher__expect.expect(e[dartx.href], src__matcher__string_matchers.endsWith('#blah'));
    }, VoidTodynamic()));
    unittest$.test('area', dart.fn(() => {
      let e = html.AreaElement.new();
      src__matcher__expect.expect(e, isAreaElement);
    }, VoidTodynamic()));
    unittest$.test('div', dart.fn(() => {
      let e = html.DivElement.new();
      src__matcher__expect.expect(e, isDivElement);
    }, VoidTodynamic()));
    unittest$.test('canvas1', dart.fn(() => {
      let e = html.CanvasElement.new();
      src__matcher__expect.expect(e, isCanvasElement);
    }, VoidTodynamic()));
    unittest$.test('canvas2', dart.fn(() => {
      let e = html.CanvasElement.new({height: 100, width: 200});
      src__matcher__expect.expect(e, isCanvasElement);
      src__matcher__expect.expect(e[dartx.width], 200);
      src__matcher__expect.expect(e[dartx.height], 100);
    }, VoidTodynamic()));
    unittest$.test('p', dart.fn(() => {
      let e = html.ParagraphElement.new();
      src__matcher__expect.expect(e, isParagraphElement);
    }, VoidTodynamic()));
    unittest$.test('span', dart.fn(() => {
      let e = html.SpanElement.new();
      src__matcher__expect.expect(e, isSpanElement);
    }, VoidTodynamic()));
    unittest$.test('select', dart.fn(() => {
      let e = html.SelectElement.new();
      src__matcher__expect.expect(e, isSelectElement);
    }, VoidTodynamic()));
  };
  dart.fn(element_constructor_1_test.main, VoidTodynamic());
  // Exports:
  exports.element_constructor_1_test = element_constructor_1_test;
});

dart_library.library('lib/html/element_dimensions_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_dimensions_test(exports, dart_sdk, unittest) {
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
  const element_dimensions_test = Object.create(null);
  let JSArrayOfNode = () => (JSArrayOfNode = dart.constFn(_interceptors.JSArray$(html.Node)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  element_dimensions_test.main = function() {
    html_config.useHtmlConfiguration();
    let isElement = src__matcher__core_matchers.predicate(dart.fn(x => html.Element.is(x), dynamicTobool()), 'is an Element');
    let isCanvasElement = src__matcher__core_matchers.predicate(dart.fn(x => html.CanvasElement.is(x), dynamicTobool()), 'is a CanvasElement');
    let isDivElement = src__matcher__core_matchers.predicate(dart.fn(x => html.DivElement.is(x), dynamicTobool()), 'is a isDivElement');
    let div = html.DivElement.new();
    div[dartx.id] = 'test';
    html.document[dartx.body][dartx.nodes][dartx.add](div);
    function initDiv() {
      let style = div[dartx.style];
      style[dartx.padding] = '4px';
      style[dartx.border] = '0px solid #fff';
      style[dartx.margin] = '6px';
      style[dartx.height] = '10px';
      style[dartx.width] = '11px';
      style[dartx.boxSizing] = 'content-box';
      style[dartx.overflow] = 'visible';
    }
    dart.fn(initDiv, VoidTovoid());
    div[dartx.nodes][dartx.addAll](JSArrayOfNode().of([html.DivElement.new(), html.CanvasElement.new(), html.DivElement.new(), html.Text.new('Hello'), html.DivElement.new(), html.Text.new('World'), html.CanvasElement.new()]));
    unittest$.group('dimensions', dart.fn(() => {
      unittest$.setUp(initDiv);
      unittest$.test('contentEdge.height', dart.fn(() => {
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(all1.contentEdge.height, 10);
        src__matcher__expect.expect(all1.get(0)[dartx.getComputedStyle]()[dartx.getPropertyValue]('height'), '10px');
        all1.contentEdge.height = new html.Dimension.px(600);
        all1.contentEdge.height = 600;
        src__matcher__expect.expect(all1.contentEdge.height, 600);
        src__matcher__expect.expect(all1.get(0)[dartx.getComputedStyle]()[dartx.getPropertyValue]('height'), '600px');
        all1.get(0)[dartx.style][dartx.visibility] = 'hidden';
        src__matcher__expect.expect(all1.contentEdge.height, 600);
        all1.get(0)[dartx.style][dartx.visibility] = 'visible';
        all1.contentEdge.height = new html.Dimension.px(-1);
        src__matcher__expect.expect(all1.contentEdge.height, 0);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.contentEdge.height, 0);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.contentEdge.height, 0);
      }, VoidTodynamic()));
      unittest$.test('contentEdge.height with border-box', dart.fn(() => {
        let all1 = html.queryAll('#test');
        div[dartx.style][dartx.boxSizing] = 'border-box';
        src__matcher__expect.expect(all1.contentEdge.height, 2);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.contentEdge.height, 0);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.contentEdge.height, 0);
      }, VoidTodynamic()));
      unittest$.test('contentEdge.width', dart.fn(() => {
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(all1.contentEdge.width, 11);
        src__matcher__expect.expect(all1.get(0)[dartx.getComputedStyle]()[dartx.getPropertyValue]('width'), '11px');
        all1.contentEdge.width = new html.Dimension.px(600);
        src__matcher__expect.expect(all1.contentEdge.width, 600);
        src__matcher__expect.expect(all1.get(0)[dartx.getComputedStyle]()[dartx.getPropertyValue]('width'), '600px');
        all1.get(0)[dartx.style][dartx.visibility] = 'hidden';
        src__matcher__expect.expect(all1.contentEdge.width, 600);
        all1.get(0)[dartx.style][dartx.visibility] = 'visible';
        all1.contentEdge.width = new html.Dimension.px(-1);
        src__matcher__expect.expect(all1.contentEdge.width, 0);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.contentEdge.width, 0);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.contentEdge.width, 0);
      }, VoidTodynamic()));
      unittest$.test('contentEdge.width with border-box', dart.fn(() => {
        let all1 = html.queryAll('#test');
        div[dartx.style][dartx.boxSizing] = 'border-box';
        src__matcher__expect.expect(all1.contentEdge.width, 3);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.contentEdge.width, 0);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.contentEdge.width, 0);
      }, VoidTodynamic()));
      unittest$.test('paddingEdge.height', dart.fn(() => {
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(all1.paddingEdge.height, 18);
        all1.get(0)[dartx.style][dartx.visibility] = 'hidden';
        src__matcher__expect.expect(all1.paddingEdge.height, 18);
        all1.get(0)[dartx.style][dartx.visibility] = 'visible';
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.paddingEdge.height, 18);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.paddingEdge.height, 650);
      }, VoidTodynamic()));
      unittest$.test('paddingEdge.height with border-box', dart.fn(() => {
        let all1 = html.queryAll('#test');
        div[dartx.style][dartx.boxSizing] = 'border-box';
        src__matcher__expect.expect(all1.paddingEdge.height, 10);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.paddingEdge.height, 640);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.paddingEdge.height, 640);
      }, VoidTodynamic()));
      unittest$.test('paddingEdge.width', dart.fn(() => {
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(all1.paddingEdge.width, 19);
        all1.get(0)[dartx.style][dartx.visibility] = 'hidden';
        src__matcher__expect.expect(all1.paddingEdge.width, 19);
        all1.get(0)[dartx.style][dartx.visibility] = 'visible';
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.paddingEdge.width, 19);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.paddingEdge.width, 651);
      }, VoidTodynamic()));
      unittest$.test('paddingEdge.width with border-box', dart.fn(() => {
        let all1 = html.queryAll('#test');
        div[dartx.style][dartx.boxSizing] = 'border-box';
        src__matcher__expect.expect(all1.paddingEdge.width, 11);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.paddingEdge.width, 640);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.paddingEdge.width, 640);
      }, VoidTodynamic()));
      unittest$.test('borderEdge.height and marginEdge.height', dart.fn(() => {
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(div[dartx.borderEdge].height, 18);
        src__matcher__expect.expect(div[dartx.marginEdge].height, 30);
        src__matcher__expect.expect(all1.borderEdge.height, 18);
        src__matcher__expect.expect(all1.marginEdge.height, 30);
        all1.get(0)[dartx.style][dartx.visibility] = 'hidden';
        src__matcher__expect.expect(all1.borderEdge.height, 18);
        all1.get(0)[dartx.style][dartx.visibility] = 'visible';
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.borderEdge.height, 22);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.borderEdge.height, 654);
        src__matcher__expect.expect(all1.marginEdge.height, 666);
      }, VoidTodynamic()));
      unittest$.test('borderEdge.height and marginEdge.height with border-box', dart.fn(() => {
        let all1 = html.queryAll('#test');
        div[dartx.style][dartx.boxSizing] = 'border-box';
        src__matcher__expect.expect(all1.borderEdge.height, 10);
        src__matcher__expect.expect(all1.marginEdge.height, 22);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.borderEdge.height, 640);
        src__matcher__expect.expect(all1.marginEdge.height, 652);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.borderEdge.height, 644);
        src__matcher__expect.expect(all1.marginEdge.height, 656);
      }, VoidTodynamic()));
      unittest$.test('borderEdge.width and marginEdge.width', dart.fn(() => {
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(all1.borderEdge.width, 19);
        src__matcher__expect.expect(all1.marginEdge.width, 31);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.borderEdge.width, 23);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.borderEdge.width, 655);
        src__matcher__expect.expect(all1.marginEdge.width, 667);
      }, VoidTodynamic()));
      unittest$.test('borderEdge.width and marginEdge.width with border-box', dart.fn(() => {
        let all1 = html.queryAll('#test');
        div[dartx.style][dartx.boxSizing] = 'border-box';
        src__matcher__expect.expect(all1.borderEdge.width, 11);
        src__matcher__expect.expect(all1.marginEdge.width, 23);
        div[dartx.style][dartx.padding] = '20pc';
        src__matcher__expect.expect(all1.borderEdge.width, 640);
        src__matcher__expect.expect(all1.marginEdge.width, 652);
        div[dartx.style][dartx.border] = '2px solid #fff';
        src__matcher__expect.expect(all1.borderEdge.width, 644);
        src__matcher__expect.expect(all1.marginEdge.width, 656);
      }, VoidTodynamic()));
      unittest$.test('left and top', dart.fn(() => {
        div[dartx.style][dartx.border] = '1px solid #fff';
        div[dartx.style][dartx.margin] = '6px 7px';
        div[dartx.style][dartx.padding] = '4px 5px';
        let all1 = html.queryAll('#test');
        src__matcher__expect.expect(all1.borderEdge.left, all1.get(0)[dartx.getBoundingClientRect]()[dartx.left]);
        src__matcher__expect.expect(all1.borderEdge.top, all1.get(0)[dartx.getBoundingClientRect]()[dartx.top]);
        src__matcher__expect.expect(all1.contentEdge.left, dart.notNull(all1.get(0)[dartx.getBoundingClientRect]()[dartx.left]) + 1 + 5);
        src__matcher__expect.expect(all1.contentEdge.top, dart.notNull(all1.get(0)[dartx.getBoundingClientRect]()[dartx.top]) + 1 + 4);
        src__matcher__expect.expect(all1.marginEdge.left, dart.notNull(all1.get(0)[dartx.getBoundingClientRect]()[dartx.left]) - 7);
        src__matcher__expect.expect(all1.marginEdge.top, dart.notNull(all1.get(0)[dartx.getBoundingClientRect]()[dartx.top]) - 6);
        src__matcher__expect.expect(all1.paddingEdge.left, dart.notNull(all1.get(0)[dartx.getBoundingClientRect]()[dartx.left]) + 1);
        src__matcher__expect.expect(all1.paddingEdge.top, dart.notNull(all1.get(0)[dartx.getBoundingClientRect]()[dartx.top]) + 1);
      }, VoidTodynamic()));
      unittest$.test('setHeight ElementList', dart.fn(() => {
        div[dartx.style][dartx.border] = '1px solid #fff';
        div[dartx.style][dartx.margin] = '6px 7px';
        div[dartx.style][dartx.padding] = '4px 5px';
        let all1 = html.queryAll('div');
        all1.contentEdge.height = new html.Dimension.px(200);
        all1.contentEdge.height = 200;
        for (let elem of all1) {
          src__matcher__expect.expect(elem[dartx.contentEdge].height, 200);
        }
        all1.contentEdge.height = new html.Dimension.px(10);
        for (let elem of all1) {
          src__matcher__expect.expect(elem[dartx.contentEdge].height, 10);
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(element_dimensions_test.main, VoidTodynamic());
  // Exports:
  exports.element_dimensions_test = element_dimensions_test;
});

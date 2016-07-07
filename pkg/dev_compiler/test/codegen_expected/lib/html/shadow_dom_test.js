dart_library.library('lib/html/shadow_dom_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__shadow_dom_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const shadow_dom_test = Object.create(null);
  let JSArrayOfDivElement = () => (JSArrayOfDivElement = dart.constFn(_interceptors.JSArray$(html.DivElement)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  shadow_dom_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.ShadowRoot[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('ShadowDOM_tests', dart.fn(() => {
      let div1 = null, div2 = null, shadowRoot = null, paragraph1 = null, paragraph2 = null;
      function init() {
        paragraph1 = html.ParagraphElement.new();
        paragraph2 = html.ParagraphElement.new();
        [paragraph1, paragraph2][dartx.forEach](dart.fn(p => {
          dart.dsend(dart.dload(p, 'classes'), 'add', 'foo');
        }, dynamicTovoid()));
        div1 = html.DivElement.new();
        div2 = html.DivElement.new();
        dart.dsend(dart.dload(div1, 'classes'), 'add', 'foo');
        shadowRoot = dart.dsend(div2, 'createShadowRoot');
        dart.dsend(shadowRoot, 'append', paragraph1);
        dart.dsend(shadowRoot, 'append', html.ContentElement.new());
        dart.dsend(div2, 'append', paragraph2);
        html.document[dartx.body][dartx.append](html.Node._check(div1));
        html.document[dartx.body][dartx.append](html.Node._check(div2));
      }
      dart.fn(init, VoidTodynamic());
      let expectation = dart.test(html.ShadowRoot[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
      unittest$.test("Shadowed nodes aren't visible to queries from outside ShadowDOM", dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          init();
          src__matcher__expect.expect(html.queryAll('.foo'), src__matcher__core_matchers.equals([div1, paragraph2]));
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('Parent node of a shadow root must be null.', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          init();
          src__matcher__expect.expect(dart.dload(shadowRoot, 'parent'), src__matcher__core_matchers.isNull);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('Querying in shadowed fragment respects the shadow boundary.', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          init();
          src__matcher__expect.expect(dart.dsend(shadowRoot, 'queryAll', '.foo'), src__matcher__core_matchers.equals([paragraph1]));
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      if (dart.test(html.ShadowRoot[dartx.supported])) {
        unittest$.test('Shadowroot contents are distributed', dart.fn(() => {
          let div = html.DivElement.new();
          let box1 = html.DivElement.new();
          box1[dartx.classes].add('foo');
          div[dartx.append](box1);
          let box2 = html.DivElement.new();
          div[dartx.append](box2);
          let sRoot = div[dartx.createShadowRoot]();
          let content1 = html.ContentElement.new();
          content1[dartx.select] = ".foo";
          sRoot[dartx.append](content1);
          let content2 = html.ContentElement.new();
          sRoot[dartx.append](content2);
          src__matcher__expect.expect(content1[dartx.getDistributedNodes](), JSArrayOfDivElement().of([box1]));
          src__matcher__expect.expect(content2[dartx.getDistributedNodes](), JSArrayOfDivElement().of([box2]));
        }, VoidTodynamic()));
      }
    }, VoidTovoid()));
  };
  dart.fn(shadow_dom_test.main, VoidTodynamic());
  // Exports:
  exports.shadow_dom_test = shadow_dom_test;
});

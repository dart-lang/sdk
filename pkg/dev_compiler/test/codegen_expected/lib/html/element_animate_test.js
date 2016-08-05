dart_library.library('lib/html/element_animate_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_animate_test(exports, dart_sdk, unittest) {
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
  const element_animate_test = Object.create(null);
  let MapOfString$dynamic = () => (MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))();
  let JSArrayOfMapOfString$dynamic = () => (JSArrayOfMapOfString$dynamic = dart.constFn(_interceptors.JSArray$(MapOfString$dynamic())))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.functionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  element_animate_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('animate_supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Animation[dartx.supported], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('simple_timing', dart.fn(() => {
      unittest$.test('simple timing', dart.fn(() => {
        let body = html.document[dartx.body];
        let opacity = core.num.parse(body[dartx.getComputedStyle]()[dartx.opacity]);
        body[dartx.animate](JSArrayOfMapOfString$dynamic().of([dart.map({opacity: 100}, core.String, dart.dynamic), dart.map({opacity: 0}, core.String, dart.dynamic)]), 100);
        let newOpacity = core.num.parse(body[dartx.getComputedStyle]()[dartx.opacity]);
        src__matcher__expect.expect(newOpacity == opacity, src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('timing_dict', dart.fn(() => {
      unittest$.test('timing dict', dart.fn(() => {
        let body = html.document[dartx.body];
        let fontSize = body[dartx.getComputedStyle]()[dartx.fontSize];
        let player = body[dartx.animate](JSArrayOfMapOfString$dynamic().of([dart.map({"font-size": "500px"}, core.String, dart.dynamic), dart.map({"font-size": fontSize}, core.String, dart.dynamic)]), dart.map({duration: 100}, core.String, core.int));
        let newFontSize = body[dartx.getComputedStyle]()[dartx.fontSize];
        src__matcher__expect.expect(newFontSize == fontSize, src__matcher__core_matchers.isFalse);
        player[dartx.on].get('finish').listen(dynamicTovoid()._check(unittest$.expectAsync(dart.fn(_ => 'done', dynamicToString()))));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('omit_timing', dart.fn(() => {
      unittest$.test('omit timing', dart.fn(() => {
        let body = html.document[dartx.body];
        let player = body[dartx.animate](JSArrayOfMapOfString$dynamic().of([dart.map({transform: "translate(100px, -100%)"}, core.String, dart.dynamic), dart.map({transform: "translate(400px, 500px)"}, core.String, dart.dynamic)]));
        player[dartx.on].get('finish').listen(dynamicTovoid()._check(unittest$.expectAsync(dart.fn(_ => 'done', dynamicToString()))));
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(element_animate_test.main, VoidTodynamic());
  // Exports:
  exports.element_animate_test = element_animate_test;
});

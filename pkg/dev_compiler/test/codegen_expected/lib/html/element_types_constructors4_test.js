dart_library.library('lib/html/element_types_constructors4_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_types_constructors4_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const src__matcher__expect = unittest.src__matcher__expect;
  const element_types_constructors4_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFn__Todynamic = () => (StringAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidTobool()], [core.bool])))();
  let VoidTobool$ = () => (VoidTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  element_types_constructors4_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    function check(name, fn, supported) {
      if (supported === void 0) supported = true;
      unittest$.test(name, dart.fn(() => {
        let expectation = dart.test(supported) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          src__matcher__expect.expect(fn(), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }
    dart.fn(check, StringAndFn__Todynamic());
    unittest$.group('constructors', dart.fn(() => {
      check('p', dart.fn(() => html.ParagraphElement.is(html.ParagraphElement.new()), VoidTobool$()));
      check('param', dart.fn(() => html.ParamElement.is(html.ParamElement.new()), VoidTobool$()));
      check('pre', dart.fn(() => html.PreElement.is(html.PreElement.new()), VoidTobool$()));
      check('progress', dart.fn(() => html.ProgressElement.is(html.ProgressElement.new()), VoidTobool$()), html.ProgressElement[dartx.supported]);
      check('q', dart.fn(() => html.QuoteElement.is(html.QuoteElement.new()), VoidTobool$()));
      check('script', dart.fn(() => html.ScriptElement.is(html.ScriptElement.new()), VoidTobool$()));
      check('select', dart.fn(() => html.SelectElement.is(html.SelectElement.new()), VoidTobool$()));
      check('shadow', dart.fn(() => html.ShadowElement.is(html.ShadowElement.new()), VoidTobool$()), html.ShadowElement[dartx.supported]);
      check('source', dart.fn(() => html.SourceElement.is(html.SourceElement.new()), VoidTobool$()));
      check('span', dart.fn(() => html.SpanElement.is(html.SpanElement.new()), VoidTobool$()));
      check('style', dart.fn(() => html.StyleElement.is(html.StyleElement.new()), VoidTobool$()));
    }, VoidTovoid()));
  };
  dart.fn(element_types_constructors4_test.main, VoidTodynamic());
  // Exports:
  exports.element_types_constructors4_test = element_types_constructors4_test;
});

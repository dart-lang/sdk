dart_library.library('lib/html/element_types_constructors2_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_types_constructors2_test(exports, dart_sdk, unittest) {
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
  const element_types_constructors2_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFn__Todynamic = () => (StringAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidTobool()], [core.bool])))();
  let VoidTobool$ = () => (VoidTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  element_types_constructors2_test.main = function() {
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
      check('fieldset', dart.fn(() => html.FieldSetElement.is(html.FieldSetElement.new()), VoidTobool$()));
      check('form', dart.fn(() => html.FormElement.is(html.FormElement.new()), VoidTobool$()));
      check('head', dart.fn(() => html.HeadElement.is(html.HeadElement.new()), VoidTobool$()));
      check('hr', dart.fn(() => html.HRElement.is(html.HRElement.new()), VoidTobool$()));
      check('html', dart.fn(() => html.HtmlHtmlElement.is(html.HtmlHtmlElement.new()), VoidTobool$()));
      check('h1', dart.fn(() => html.HeadingElement.is(html.HeadingElement.h1()), VoidTobool$()));
      check('h2', dart.fn(() => html.HeadingElement.is(html.HeadingElement.h2()), VoidTobool$()));
      check('h3', dart.fn(() => html.HeadingElement.is(html.HeadingElement.h3()), VoidTobool$()));
      check('h4', dart.fn(() => html.HeadingElement.is(html.HeadingElement.h4()), VoidTobool$()));
      check('h5', dart.fn(() => html.HeadingElement.is(html.HeadingElement.h5()), VoidTobool$()));
      check('h6', dart.fn(() => html.HeadingElement.is(html.HeadingElement.h6()), VoidTobool$()));
      check('iframe', dart.fn(() => html.IFrameElement.is(html.IFrameElement.new()), VoidTobool$()));
      check('img', dart.fn(() => html.ImageElement.is(html.ImageElement.new()), VoidTobool$()));
      check('input', dart.fn(() => html.InputElement.is(html.InputElement.new()), VoidTobool$()));
      check('keygen', dart.fn(() => html.KeygenElement.is(html.KeygenElement.new()), VoidTobool$()), html.KeygenElement[dartx.supported]);
    }, VoidTovoid()));
  };
  dart.fn(element_types_constructors2_test.main, VoidTodynamic());
  // Exports:
  exports.element_types_constructors2_test = element_types_constructors2_test;
});

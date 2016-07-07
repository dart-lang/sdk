dart_library.library('lib/html/element_types_constructors6_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_types_constructors6_test(exports, dart_sdk, unittest) {
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
  const element_types_constructors6_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFn__Todynamic = () => (StringAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidTobool()], [core.bool])))();
  let VoidTobool$ = () => (VoidTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  element_types_constructors6_test.main = function() {
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
    unittest$.group('ul', dart.fn(() => {
      check('ul', dart.fn(() => html.UListElement.is(html.UListElement.new()), VoidTobool$()));
      unittest$.test('accepts li', dart.fn(() => {
        let ul = html.UListElement.new();
        let li = html.LIElement.new();
        ul[dartx.append](li);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('constructors', dart.fn(() => {
      check('video', dart.fn(() => html.VideoElement.is(html.VideoElement.new()), VoidTobool$()));
      check('unknown', dart.fn(() => html.UnknownElement.is(html.Element.tag('someunknown')), VoidTobool$()));
    }, VoidTovoid()));
  };
  dart.fn(element_types_constructors6_test.main, VoidTodynamic());
  // Exports:
  exports.element_types_constructors6_test = element_types_constructors6_test;
});

dart_library.library('lib/html/element_types_constructors3_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_types_constructors3_test(exports, dart_sdk, unittest) {
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
  const element_types_constructors3_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFn__Todynamic = () => (StringAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidTobool()], [core.bool])))();
  let VoidTobool$ = () => (VoidTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  element_types_constructors3_test.main = function() {
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
      check('li', dart.fn(() => html.LIElement.is(html.LIElement.new()), VoidTobool$()));
      check('label', dart.fn(() => html.LabelElement.is(html.LabelElement.new()), VoidTobool$()));
      check('legen', dart.fn(() => html.LegendElement.is(html.LegendElement.new()), VoidTobool$()));
      check('link', dart.fn(() => html.LinkElement.is(html.LinkElement.new()), VoidTobool$()));
      check('map', dart.fn(() => html.MapElement.is(html.MapElement.new()), VoidTobool$()));
      check('menu', dart.fn(() => html.MenuElement.is(html.MenuElement.new()), VoidTobool$()));
      check('meta', dart.fn(() => html.MetaElement.is(html.MetaElement.new()), VoidTobool$()));
      check('meter', dart.fn(() => html.MeterElement.is(html.MeterElement.new()), VoidTobool$()), html.MeterElement[dartx.supported]);
      check('del', dart.fn(() => html.ModElement.is(html.Element.tag('del')), VoidTobool$()));
      check('ins', dart.fn(() => html.ModElement.is(html.Element.tag('ins')), VoidTobool$()));
      check('object', dart.fn(() => html.ObjectElement.is(html.ObjectElement.new()), VoidTobool$()), html.ObjectElement[dartx.supported]);
      check('ol', dart.fn(() => html.OListElement.is(html.OListElement.new()), VoidTobool$()));
      check('optgroup', dart.fn(() => html.OptGroupElement.is(html.OptGroupElement.new()), VoidTobool$()));
      check('option', dart.fn(() => html.OptionElement.is(html.OptionElement.new()), VoidTobool$()));
      check('output', dart.fn(() => html.OutputElement.is(html.OutputElement.new()), VoidTobool$()), html.OutputElement[dartx.supported]);
    }, VoidTovoid()));
  };
  dart.fn(element_types_constructors3_test.main, VoidTodynamic());
  // Exports:
  exports.element_types_constructors3_test = element_types_constructors3_test;
});

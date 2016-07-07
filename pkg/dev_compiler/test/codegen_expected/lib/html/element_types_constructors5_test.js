dart_library.library('lib/html/element_types_constructors5_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_types_constructors5_test(exports, dart_sdk, unittest) {
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
  const element_types_constructors5_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFn__Todynamic = () => (StringAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidTobool()], [core.bool])))();
  let VoidTobool$ = () => (VoidTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  element_types_constructors5_test.main = function() {
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
      check('table', dart.fn(() => html.TableElement.is(html.TableElement.new()), VoidTobool$()));
      check('template', dart.fn(() => html.TemplateElement.is(html.TemplateElement.new()), VoidTobool$()), html.TemplateElement[dartx.supported]);
      check('textarea', dart.fn(() => html.TextAreaElement.is(html.TextAreaElement.new()), VoidTobool$()));
      check('title', dart.fn(() => html.TitleElement.is(html.TitleElement.new()), VoidTobool$()));
      check('td', dart.fn(() => html.TableCellElement.is(html.TableCellElement.new()), VoidTobool$()));
      check('col', dart.fn(() => html.TableColElement.is(html.TableColElement.new()), VoidTobool$()));
      check('colgroup', dart.fn(() => html.TableColElement.is(html.Element.tag('colgroup')), VoidTobool$()));
      check('tr', dart.fn(() => html.TableRowElement.is(html.TableRowElement.new()), VoidTobool$()));
      check('tbody', dart.fn(() => html.TableSectionElement.is(html.Element.tag('tbody')), VoidTobool$()));
      check('tfoot', dart.fn(() => html.TableSectionElement.is(html.Element.tag('tfoot')), VoidTobool$()));
      check('thead', dart.fn(() => html.TableSectionElement.is(html.Element.tag('thead')), VoidTobool$()));
      check('track', dart.fn(() => html.TrackElement.is(html.TrackElement.new()), VoidTobool$()), html.TrackElement[dartx.supported]);
    }, VoidTovoid()));
  };
  dart.fn(element_types_constructors5_test.main, VoidTodynamic());
  // Exports:
  exports.element_types_constructors5_test = element_types_constructors5_test;
});

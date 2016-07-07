dart_library.library('lib/html/element_types_constructors1_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_types_constructors1_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unittest$ = unittest.unittest;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const src__matcher__expect = unittest.src__matcher__expect;
  const element_types_constructors1_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFn__Todynamic = () => (StringAndFn__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, VoidTobool()], [core.bool])))();
  let VoidTobool$ = () => (VoidTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  element_types_constructors1_test.main = function() {
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
      check('a', dart.fn(() => html.AnchorElement.is(html.AnchorElement.new()), VoidTobool$()));
      check('area', dart.fn(() => html.AreaElement.is(html.AreaElement.new()), VoidTobool$()));
      check('audio', dart.fn(() => html.AudioElement.is(html.AudioElement.new()), VoidTobool$()));
      check('body', dart.fn(() => html.BodyElement.is(html.BodyElement.new()), VoidTobool$()));
      check('br', dart.fn(() => html.BRElement.is(html.BRElement.new()), VoidTobool$()));
      check('base', dart.fn(() => html.BaseElement.is(html.BaseElement.new()), VoidTobool$()));
      check('button', dart.fn(() => html.ButtonElement.is(html.ButtonElement.new()), VoidTobool$()));
      check('canvas', dart.fn(() => html.CanvasElement.is(html.CanvasElement.new()), VoidTobool$()));
      check('caption', dart.fn(() => html.TableCaptionElement.is(html.TableCaptionElement.new()), VoidTobool$()));
      check('content', dart.fn(() => html.ContentElement.is(html.ContentElement.new()), VoidTobool$()), html.ContentElement[dartx.supported]);
      check('details', dart.fn(() => html.DetailsElement.is(html.DetailsElement.new()), VoidTobool$()), html.DetailsElement[dartx.supported]);
      check('datalist', dart.fn(() => html.DataListElement.is(html.DataListElement.new()), VoidTobool$()), html.DataListElement[dartx.supported]);
      check('dl', dart.fn(() => html.DListElement.is(html.DListElement.new()), VoidTobool$()));
      check('div', dart.fn(() => html.DivElement.is(html.DivElement.new()), VoidTobool$()));
      check('embed', dart.fn(() => html.EmbedElement.is(html.EmbedElement.new()), VoidTobool$()), html.EmbedElement[dartx.supported]);
    }, VoidTovoid()));
  };
  dart.fn(element_types_constructors1_test.main, VoidTodynamic());
  // Exports:
  exports.element_types_constructors1_test = element_types_constructors1_test;
});

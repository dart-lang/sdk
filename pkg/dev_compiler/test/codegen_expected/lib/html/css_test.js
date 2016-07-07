dart_library.library('lib/html/css_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__css_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const css_test = Object.create(null);
  let PointOfnum = () => (PointOfnum = dart.constFn(math.Point$(core.num)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicAndPointOfnumTovoid = () => (dynamicAnddynamicAndPointOfnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, PointOfnum()])))();
  css_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supportsPointConversions', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Window[dartx.supportsPointConversions], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('DomPoint', dart.fn(() => {
        let expectation = dart.test(html.Window[dartx.supportsPointConversions]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let element = html.Element.tag('div');
          element[dartx.attributes][dartx.set]('style', '          position: absolute;\n          width: 60px;\n          height: 100px;\n          left: 0px;\n          top: 0px;\n          background-color: red;\n          -webkit-transform: translate3d(250px, 100px, 0px);\n          -moz-transform: translate3d(250px, 100px, 0px);\n          ');
          html.document[dartx.body][dartx.append](element);
          let elemRect = element[dartx.getBoundingClientRect]();
          css_test.checkPoint(250, 100, new (PointOfnum())(elemRect[dartx.left], elemRect[dartx.top]));
          css_test.checkPoint(310, 200, new (PointOfnum())(elemRect[dartx.right], elemRect[dartx.bottom]));
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(css_test.main, VoidTodynamic());
  css_test.checkPoint = function(expectedX, expectedY, point) {
    src__matcher__expect.expect(point.x[dartx.round](), src__matcher__core_matchers.equals(expectedX), {reason: 'Wrong point.x'});
    src__matcher__expect.expect(point.y[dartx.round](), src__matcher__core_matchers.equals(expectedY), {reason: 'Wrong point.y'});
  };
  dart.fn(css_test.checkPoint, dynamicAnddynamicAndPointOfnumTovoid());
  // Exports:
  exports.css_test = css_test;
});

dart_library.library('lib/html/svg_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__svg_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const svg = dart_sdk.svg;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const svg_test = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToElement = () => (VoidToElement = dart.constFn(dart.definiteFunctionType(html.Element, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  svg_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('svgPresence', dart.fn(() => {
      let isSvgElement = src__matcher__core_matchers.predicate(dart.fn(x => svg.SvgElement.is(x), dynamicTobool()), 'is a SvgElement');
      unittest$.test('simpleRect', dart.fn(() => {
        let div = html.Element.tag('div');
        html.document[dartx.body][dartx.append](div);
        div[dartx.setInnerHtml]('<svg id=\'svg1\' width=\'200\' height=\'100\'>\n<rect id=\'rect1\' x=\'10\' y=\'20\' width=\'130\' height=\'40\' rx=\'5\'fill=\'blue\'></rect>\n</svg>\n', {validator: (() => {
            let _ = new html.NodeValidatorBuilder();
            _.allowSvg();
            return _;
          })()});
        let e = html.document[dartx.query]('#svg1');
        src__matcher__expect.expect(e, src__matcher__core_matchers.isNotNull);
        let r = svg.RectElement._check(html.document[dartx.query]('#rect1'));
        src__matcher__expect.expect(r[dartx.x][dartx.baseVal][dartx.value], 10);
        src__matcher__expect.expect(r[dartx.y][dartx.baseVal][dartx.value], 20);
        src__matcher__expect.expect(r[dartx.height][dartx.baseVal][dartx.value], 40);
        src__matcher__expect.expect(r[dartx.width][dartx.baseVal][dartx.value], 130);
        src__matcher__expect.expect(r[dartx.rx][dartx.baseVal][dartx.value], 5);
      }, VoidTodynamic()));
      unittest$.test('trailing newline', dart.fn(() => {
        let logo = svg.SvgElement.svg("        <svg xmlns='http://www.w3.org/2000/svg' version='1.1'>\n          <path/>\n        </svg>\n        ");
        src__matcher__expect.expect(logo, isSvgElement);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('svgInterfaceMatch', dart.fn(() => {
      function insertTestDiv() {
        let element = html.Element.tag('div');
        element[dartx.setInnerHtml]('<svg id=\'svg1\' width=\'200\' height=\'100\'>\n<rect id=\'rect1\' x=\'10\' y=\'20\' width=\'130\' height=\'40\' rx=\'5\'fill=\'blue\'></rect>\n</svg>\n', {validator: (() => {
            let _ = new html.NodeValidatorBuilder();
            _.allowSvg();
            return _;
          })()});
        html.document[dartx.body][dartx.append](element);
        return element;
      }
      dart.fn(insertTestDiv, VoidToElement());
      let isElement = src__matcher__core_matchers.predicate(dart.fn(x => html.Element.is(x), dynamicTobool()), 'is an Element');
      let isSvgElement = src__matcher__core_matchers.predicate(dart.fn(x => svg.SvgElement.is(x), dynamicTobool()), 'is a SvgElement');
      let isSvgSvgElement = src__matcher__core_matchers.predicate(dart.fn(x => svg.SvgSvgElement.is(x), dynamicTobool()), 'is a SvgSvgElement');
      let isNode = src__matcher__core_matchers.predicate(dart.fn(x => html.Node.is(x), dynamicTobool()), 'is a Node');
      let isSvgNumber = src__matcher__core_matchers.predicate(dart.fn(x => svg.Number.is(x), dynamicTobool()), 'is a svg.Number');
      let isSvgRect = src__matcher__core_matchers.predicate(dart.fn(x => svg.Rect.is(x), dynamicTobool()), 'is a svg.Rect');
      unittest$.test('rect_isChecks', dart.fn(() => {
        let div = insertTestDiv();
        let r = html.document[dartx.query]('#rect1');
        src__matcher__expect.expect(r, isSvgElement);
        src__matcher__expect.expect(r, isElement);
        src__matcher__expect.expect(r, isNode);
        src__matcher__expect.expect(r, src__matcher__operator_matchers.isNot(isSvgNumber));
        src__matcher__expect.expect(r, src__matcher__operator_matchers.isNot(isSvgRect));
        src__matcher__expect.expect(r, src__matcher__operator_matchers.isNot(isSvgSvgElement));
        div[dartx.remove]();
      }, VoidTodynamic()));
    }, VoidTovoid()));
    function insertTestDiv() {
      let element = html.Element.tag('div');
      element[dartx.innerHtml] = '<svg id=\'svg1\' width=\'200\' height=\'100\'>\n<rect id=\'rect1\' x=\'10\' y=\'20\' width=\'130\' height=\'40\' rx=\'5\'fill=\'blue\'></rect>\n</svg>\n';
      html.document[dartx.body][dartx.append](element);
      return element;
    }
    dart.fn(insertTestDiv, VoidToElement());
    unittest$.group('svgBehavioral', dart.fn(() => {
      let isString = src__matcher__core_matchers.predicate(dart.fn(x => typeof x == 'string', dynamicTobool()), 'is a String');
      let isStringList = src__matcher__core_matchers.predicate(dart.fn(x => ListOfString().is(x), dynamicTobool()), 'is a List<String>');
      let isSvgMatrix = src__matcher__core_matchers.predicate(dart.fn(x => svg.Matrix.is(x), dynamicTobool()), 'is a svg.Matrix');
      let isSvgAnimatedBoolean = src__matcher__core_matchers.predicate(dart.fn(x => svg.AnimatedBoolean.is(x), dynamicTobool()), 'is an svg.AnimatedBoolean');
      let isSvgAnimatedString = src__matcher__core_matchers.predicate(dart.fn(x => svg.AnimatedString.is(x), dynamicTobool()), 'is an svg.AnimatedString');
      let isSvgRect = src__matcher__core_matchers.predicate(dart.fn(x => svg.Rect.is(x), dynamicTobool()), 'is a svg.Rect');
      let isSvgAnimatedTransformList = src__matcher__core_matchers.predicate(dart.fn(x => svg.AnimatedTransformList.is(x), dynamicTobool()), 'is an svg.AnimatedTransformList');
      let isCssStyleDeclaration = src__matcher__core_matchers.predicate(dart.fn(x => html.CssStyleDeclaration.is(x), dynamicTobool()), 'is a CssStyleDeclaration');
      function testRect(name, checker) {
        unittest$.test(core.String._check(name), dart.fn(() => {
          let div = insertTestDiv();
          let r = html.document[dartx.query]('#rect1');
          dart.dcall(checker, r);
          div[dartx.remove]();
        }, VoidTodynamic()));
      }
      dart.fn(testRect, dynamicAnddynamicTodynamic());
    }, VoidTovoid()));
  };
  dart.fn(svg_test.main, VoidTodynamic());
  // Exports:
  exports.svg_test = svg_test;
});

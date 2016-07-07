dart_library.library('lib/html/svgelement_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__svgelement_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const svg = dart_sdk.svg;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const src__matcher__throws_matchers = unittest.src__matcher__throws_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const src__matcher__numeric_matchers = unittest.src__matcher__numeric_matchers;
  const svgelement_test = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let IterableOfNode = () => (IterableOfNode = dart.constFn(core.Iterable$(html.Node)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfGeometryElement = () => (JSArrayOfGeometryElement = dart.constFn(_interceptors.JSArray$(svg.GeometryElement)))();
  let JSArrayOfElement = () => (JSArrayOfElement = dart.constFn(_interceptors.JSArray$(html.Element)))();
  let RectangleOfnum = () => (RectangleOfnum = dart.constFn(math.Rectangle$(core.num)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let IterableOfNodeToListOfString = () => (IterableOfNodeToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [IterableOfNode()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndFunction__Todynamic = () => (StringAndFunction__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.Function], [core.bool, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToSvgElement = () => (VoidToSvgElement = dart.constFn(dart.definiteFunctionType(svg.SvgElement, [])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  svgelement_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    let isSvgSvgElement = src__matcher__core_matchers.predicate(dart.fn(x => svg.SvgSvgElement.is(x), dynamicTobool()), 'is a SvgSvgElement');
    function _nodeStrings(input) {
      let out = ListOfString().new();
      for (let n of input) {
        if (html.Element.is(n)) {
          let e = n;
          out[dartx.add](e[dartx.tagName]);
        } else {
          out[dartx.add](n[dartx.text]);
        }
      }
      return out;
    }
    dart.fn(_nodeStrings, IterableOfNodeToListOfString());
    ;
    function testConstructor(tagName, isExpectedClass, expectation, allowsInnerHtml) {
      if (expectation === void 0) expectation = true;
      if (allowsInnerHtml === void 0) allowsInnerHtml = true;
      unittest$.test(tagName, dart.fn(() => {
        src__matcher__expect.expect(dart.dcall(isExpectedClass, svg.SvgElement.tag(tagName)), expectation);
        if (dart.test(allowsInnerHtml)) {
          src__matcher__expect.expect(dart.dcall(isExpectedClass, svg.SvgElement.svg(dart.str`<${tagName}></${tagName}>`)), dart.test(expectation) && dart.test(allowsInnerHtml));
        }
      }, VoidTodynamic()));
    }
    dart.fn(testConstructor, StringAndFunction__Todynamic());
    unittest$.group('additionalConstructors', dart.fn(() => {
      unittest$.test('valid', dart.fn(() => {
        let svgContent = "<svg version=\"1.1\">\n" + "  <circle></circle>\n" + "  <path></path>\n" + "</svg>";
        let el = svg.SvgElement.svg(svgContent);
        src__matcher__expect.expect(el, isSvgSvgElement);
        src__matcher__expect.expect(el[dartx.innerHtml], src__matcher__operator_matchers.anyOf("<circle></circle><path></path>", '<circle ' + 'xmlns="http://www.w3.org/2000/svg" /><path ' + 'xmlns="http://www.w3.org/2000/svg" />'));
        src__matcher__expect.expect(el[dartx.outerHtml], src__matcher__operator_matchers.anyOf(svgContent, '<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n  ' + '<circle />\n  <path />\n</svg>'));
      }, VoidTodynamic()));
      unittest$.test('has no parent', dart.fn(() => src__matcher__expect.expect(svg.SvgElement.svg('<circle/>')[dartx.parent], src__matcher__core_matchers.isNull), VoidTovoid()));
      unittest$.test('empty', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => svg.SvgElement.svg(""), VoidToSvgElement()), src__matcher__throws_matchers.throwsStateError);
      }, VoidTodynamic()));
      unittest$.test('too many elements', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => svg.SvgElement.svg("<circle></circle><path></path>"), VoidToSvgElement()), src__matcher__throws_matchers.throwsStateError);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_animate', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.AnimateElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_animateMotion', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.AnimateMotionElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_animateTransform', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.AnimateTransformElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feBlend', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEBlendElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feColorMatrix', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEColorMatrixElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feComponentTransfer', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEComponentTransferElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feConvolveMatrix', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEConvolveMatrixElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feDiffuseLighting', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEDiffuseLightingElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feDisplacementMap', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEDisplacementMapElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feDistantLight', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEDistantLightElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feFlood', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEFloodElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feFuncA', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEFuncAElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feFuncB', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEFuncBElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feFuncG', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEFuncGElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feFuncR', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEFuncRElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feGaussianBlur', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEGaussianBlurElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feImage', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEImageElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feMerge', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEMergeElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feMergeNode', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEMergeNodeElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feOffset', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEOffsetElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feComponentTransfer', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FEPointLightElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feSpecularLighting', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FESpecularLightingElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feComponentTransfer', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FESpotLightElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feTile', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FETileElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_feTurbulence', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FETurbulenceElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_filter', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.FilterElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_foreignObject', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.ForeignObjectElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_set', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(svg.SetElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('constructors', dart.fn(() => {
      testConstructor('a', dart.fn(e => svg.AElement.is(e), dynamicTobool()));
      testConstructor('circle', dart.fn(e => svg.CircleElement.is(e), dynamicTobool()));
      testConstructor('clipPath', dart.fn(e => svg.ClipPathElement.is(e), dynamicTobool()));
      testConstructor('defs', dart.fn(e => svg.DefsElement.is(e), dynamicTobool()));
      testConstructor('desc', dart.fn(e => svg.DescElement.is(e), dynamicTobool()));
      testConstructor('ellipse', dart.fn(e => svg.EllipseElement.is(e), dynamicTobool()));
      testConstructor('g', dart.fn(e => svg.GElement.is(e), dynamicTobool()));
      testConstructor('image', dart.fn(e => svg.ImageElement.is(e), dynamicTobool()));
      testConstructor('line', dart.fn(e => svg.LineElement.is(e), dynamicTobool()));
      testConstructor('linearGradient', dart.fn(e => svg.LinearGradientElement.is(e), dynamicTobool()));
      testConstructor('marker', dart.fn(e => svg.MarkerElement.is(e), dynamicTobool()));
      testConstructor('mask', dart.fn(e => svg.MaskElement.is(e), dynamicTobool()));
      testConstructor('path', dart.fn(e => svg.PathElement.is(e), dynamicTobool()));
      testConstructor('pattern', dart.fn(e => svg.PatternElement.is(e), dynamicTobool()));
      testConstructor('polygon', dart.fn(e => svg.PolygonElement.is(e), dynamicTobool()));
      testConstructor('polyline', dart.fn(e => svg.PolylineElement.is(e), dynamicTobool()));
      testConstructor('radialGradient', dart.fn(e => svg.RadialGradientElement.is(e), dynamicTobool()));
      testConstructor('rect', dart.fn(e => svg.RectElement.is(e), dynamicTobool()));
      unittest$.test('script', dart.fn(() => {
        src__matcher__expect.expect(svg.ScriptElement.is(svg.SvgElement.tag('script')), src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
      testConstructor('stop', dart.fn(e => svg.StopElement.is(e), dynamicTobool()));
      testConstructor('style', dart.fn(e => svg.StyleElement.is(e), dynamicTobool()));
      testConstructor('switch', dart.fn(e => svg.SwitchElement.is(e), dynamicTobool()));
      testConstructor('symbol', dart.fn(e => svg.SymbolElement.is(e), dynamicTobool()));
      testConstructor('tspan', dart.fn(e => svg.TSpanElement.is(e), dynamicTobool()));
      testConstructor('text', dart.fn(e => svg.TextElement.is(e), dynamicTobool()));
      testConstructor('textPath', dart.fn(e => svg.TextPathElement.is(e), dynamicTobool()));
      testConstructor('title', dart.fn(e => svg.TitleElement.is(e), dynamicTobool()));
      testConstructor('use', dart.fn(e => svg.UseElement.is(e), dynamicTobool()));
      testConstructor('view', dart.fn(e => svg.ViewElement.is(e), dynamicTobool()));
      testConstructor('animate', dart.fn(e => svg.AnimateElement.is(e), dynamicTobool()), svg.AnimateElement[dartx.supported]);
      testConstructor('animateMotion', dart.fn(e => svg.AnimateMotionElement.is(e), dynamicTobool()), svg.AnimateMotionElement[dartx.supported]);
      testConstructor('animateTransform', dart.fn(e => svg.AnimateTransformElement.is(e), dynamicTobool()), svg.AnimateTransformElement[dartx.supported]);
      testConstructor('feBlend', dart.fn(e => svg.FEBlendElement.is(e), dynamicTobool()), svg.FEBlendElement[dartx.supported]);
      testConstructor('feColorMatrix', dart.fn(e => svg.FEColorMatrixElement.is(e), dynamicTobool()), svg.FEColorMatrixElement[dartx.supported]);
      testConstructor('feComponentTransfer', dart.fn(e => svg.FEComponentTransferElement.is(e), dynamicTobool()), svg.FEComponentTransferElement[dartx.supported]);
      testConstructor('feConvolveMatrix', dart.fn(e => svg.FEConvolveMatrixElement.is(e), dynamicTobool()), svg.FEConvolveMatrixElement[dartx.supported]);
      testConstructor('feDiffuseLighting', dart.fn(e => svg.FEDiffuseLightingElement.is(e), dynamicTobool()), svg.FEDiffuseLightingElement[dartx.supported]);
      testConstructor('feDisplacementMap', dart.fn(e => svg.FEDisplacementMapElement.is(e), dynamicTobool()), svg.FEDisplacementMapElement[dartx.supported]);
      testConstructor('feDistantLight', dart.fn(e => svg.FEDistantLightElement.is(e), dynamicTobool()), svg.FEDistantLightElement[dartx.supported]);
      testConstructor('feFlood', dart.fn(e => svg.FEFloodElement.is(e), dynamicTobool()), svg.FEFloodElement[dartx.supported]);
      testConstructor('feFuncA', dart.fn(e => svg.FEFuncAElement.is(e), dynamicTobool()), svg.FEFuncAElement[dartx.supported]);
      testConstructor('feFuncB', dart.fn(e => svg.FEFuncBElement.is(e), dynamicTobool()), svg.FEFuncBElement[dartx.supported]);
      testConstructor('feFuncG', dart.fn(e => svg.FEFuncGElement.is(e), dynamicTobool()), svg.FEFuncGElement[dartx.supported]);
      testConstructor('feFuncR', dart.fn(e => svg.FEFuncRElement.is(e), dynamicTobool()), svg.FEFuncRElement[dartx.supported]);
      testConstructor('feGaussianBlur', dart.fn(e => svg.FEGaussianBlurElement.is(e), dynamicTobool()), svg.FEGaussianBlurElement[dartx.supported]);
      testConstructor('feImage', dart.fn(e => svg.FEImageElement.is(e), dynamicTobool()), svg.FEImageElement[dartx.supported]);
      testConstructor('feMerge', dart.fn(e => svg.FEMergeElement.is(e), dynamicTobool()), svg.FEMergeElement[dartx.supported]);
      testConstructor('feMergeNode', dart.fn(e => svg.FEMergeNodeElement.is(e), dynamicTobool()), svg.FEMergeNodeElement[dartx.supported]);
      testConstructor('feOffset', dart.fn(e => svg.FEOffsetElement.is(e), dynamicTobool()), svg.FEOffsetElement[dartx.supported]);
      testConstructor('fePointLight', dart.fn(e => svg.FEPointLightElement.is(e), dynamicTobool()), svg.FEPointLightElement[dartx.supported]);
      testConstructor('feSpecularLighting', dart.fn(e => svg.FESpecularLightingElement.is(e), dynamicTobool()), svg.FESpecularLightingElement[dartx.supported]);
      testConstructor('feSpotLight', dart.fn(e => svg.FESpotLightElement.is(e), dynamicTobool()), svg.FESpotLightElement[dartx.supported]);
      testConstructor('feTile', dart.fn(e => svg.FETileElement.is(e), dynamicTobool()), svg.FETileElement[dartx.supported]);
      testConstructor('feTurbulence', dart.fn(e => svg.FETurbulenceElement.is(e), dynamicTobool()), svg.FETurbulenceElement[dartx.supported]);
      testConstructor('filter', dart.fn(e => svg.FilterElement.is(e), dynamicTobool()), svg.FilterElement[dartx.supported]);
      testConstructor('foreignObject', dart.fn(e => svg.ForeignObjectElement.is(e), dynamicTobool()), svg.ForeignObjectElement[dartx.supported], false);
      testConstructor('metadata', dart.fn(e => svg.MetadataElement.is(e), dynamicTobool()));
      testConstructor('set', dart.fn(e => svg.SetElement.is(e), dynamicTobool()), svg.SetElement[dartx.supported]);
    }, VoidTovoid()));
    unittest$.group('outerHtml', dart.fn(() => {
      unittest$.test('outerHtml', dart.fn(() => {
        let el = svg.SvgSvgElement.new();
        el[dartx.children][dartx.add](svg.CircleElement.new());
        el[dartx.children][dartx.add](svg.PathElement.new());
        src__matcher__expect.expect(JSArrayOfString().of(['<svg version="1.1"><circle></circle><path></path></svg>', '<svg xmlns="http://www.w3.org/2000/svg" version="1.1">' + '<circle /><path /></svg>'])[dartx.contains](el[dartx.outerHtml]), true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('innerHtml', dart.fn(() => {
      unittest$.test('get', dart.fn(() => {
        let el = svg.SvgSvgElement.new();
        el[dartx.children][dartx.add](svg.CircleElement.new());
        el[dartx.children][dartx.add](svg.PathElement.new());
        src__matcher__expect.expect(JSArrayOfString().of(['<circle></circle><path></path>', '<circle xmlns="http://www.w3.org/2000/svg" />' + '<path xmlns="http://www.w3.org/2000/svg" />'])[dartx.contains](el[dartx.innerHtml]), true);
      }, VoidTodynamic()));
      unittest$.test('set', dart.fn(() => {
        let el = svg.SvgSvgElement.new();
        el[dartx.children][dartx.add](svg.CircleElement.new());
        el[dartx.children][dartx.add](svg.PathElement.new());
        el[dartx.innerHtml] = '<rect></rect><a></a>';
        src__matcher__expect.expect(_nodeStrings(el[dartx.children]), JSArrayOfString().of(["rect", "a"]));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('elementget', dart.fn(() => {
      unittest$.test('get', dart.fn(() => {
        let el = svg.SvgElement.svg("<svg version=\"1.1\">\n  <circle></circle>\n  <path></path>\n  text\n</svg>");
        src__matcher__expect.expect(_nodeStrings(el[dartx.children]), JSArrayOfString().of(["circle", "path"]));
      }, VoidTodynamic()));
      unittest$.test('resize', dart.fn(() => {
        let el = svg.SvgSvgElement.new();
        let items = JSArrayOfGeometryElement().of([svg.CircleElement.new(), svg.RectElement.new()]);
        el[dartx.children] = items;
        src__matcher__expect.expect(el[dartx.children][dartx.length], 2);
        el[dartx.children][dartx.length] = 1;
        src__matcher__expect.expect(el[dartx.children][dartx.length], 1);
        src__matcher__expect.expect(el[dartx.children][dartx.contains](items[dartx.get](0)), true);
        src__matcher__expect.expect(el[dartx.children][dartx.contains](items[dartx.get](1)), false);
        el[dartx.children][dartx.length] = 0;
        src__matcher__expect.expect(el[dartx.children][dartx.contains](items[dartx.get](0)), false);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('elementset', dart.fn(() => {
      unittest$.test('set', dart.fn(() => {
        let el = svg.SvgSvgElement.new();
        el[dartx.children] = JSArrayOfElement().of([svg.SvgElement.tag("circle"), svg.SvgElement.tag("path")]);
        src__matcher__expect.expect(el[dartx.nodes][dartx.length], 2);
        src__matcher__expect.expect(svg.CircleElement.is(el[dartx.nodes][dartx.get](0)), true);
        src__matcher__expect.expect(svg.PathElement.is(el[dartx.nodes][dartx.get](1)), true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('css', dart.fn(() => {
      unittest$.test('classes', dart.fn(() => {
        let el = svg.CircleElement.new();
        let classes = el[dartx.classes];
        src__matcher__expect.expect(el[dartx.classes].length, 0);
        classes.toggle('foo');
        src__matcher__expect.expect(el[dartx.classes].length, 1);
        classes.toggle('foo');
        src__matcher__expect.expect(el[dartx.classes].length, 0);
      }, VoidTodynamic()));
      unittest$.test('classes-add-bad', dart.fn(() => {
        let el = svg.CircleElement.new();
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].add(''), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].add('foo bar'), VoidTobool()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
      unittest$.test('classes-remove-bad', dart.fn(() => {
        let el = svg.CircleElement.new();
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].remove(''), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].remove('foo bar'), VoidTobool()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
      unittest$.test('classes-toggle-token', dart.fn(() => {
        let el = svg.CircleElement.new();
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].toggle(''), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].toggle('', true), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].toggle('', false), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].toggle('foo bar'), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].toggle('foo bar', true), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].toggle('foo bar', false), VoidTobool()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
      unittest$.test('classes-contains-bad', dart.fn(() => {
        let el = svg.CircleElement.new();
        src__matcher__expect.expect(el[dartx.classes].contains(1), src__matcher__core_matchers.isFalse);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].contains(''), VoidTobool()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => el[dartx.classes].contains('foo bar'), VoidTobool()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('getBoundingClientRect', dart.fn(() => {
      unittest$.test('is a Rectangle', dart.fn(() => {
        let element = svg.RectElement.new();
        element[dartx.attributes][dartx.set]('width', '100');
        element[dartx.attributes][dartx.set]('height', '100');
        let root = svg.SvgSvgElement.new();
        root[dartx.append](element);
        html.document[dartx.body][dartx.append](root);
        let rect = element[dartx.getBoundingClientRect]();
        src__matcher__expect.expect(RectangleOfnum().is(rect), src__matcher__core_matchers.isTrue);
        src__matcher__expect.expect(rect[dartx.width], src__matcher__numeric_matchers.closeTo(100, 1));
        src__matcher__expect.expect(rect[dartx.height], src__matcher__numeric_matchers.closeTo(100, 1));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('PathElement', dart.fn(() => {
      unittest$.test('pathSegList', dart.fn(() => {
        let path = svg.PathElement._check(svg.SvgElement.svg('<path d="M 100 100 L 300 100 L 200 300 z"/>'));
        for (let seg of path[dartx.pathSegList]) {
          src__matcher__expect.expect(svg.PathSeg.is(seg), src__matcher__core_matchers.isTrue);
        }
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(svgelement_test.main, VoidTodynamic());
  // Exports:
  exports.svgelement_test = svgelement_test;
});

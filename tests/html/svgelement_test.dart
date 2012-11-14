// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library SVGElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:svg';

main() {
  useHtmlIndividualConfiguration();

  var isSVGSVGElement =
      predicate((x) => x is SVGSVGElement, 'is a SVGSVGElement');

  Collection<String> _nodeStrings(Collection<Node> input) {
    final out = new List<String>();
    for (Node n in input) {
      if (n is Element) {
        Element e = n;
        out.add(e.tagName);
      } else {
        out.add(n.text);
      }
    }
    return out;
  };

  testConstructor(String tagName, Function isExpectedClass) {
    test(tagName, () {
      expect(isExpectedClass(new SVGElement.tag(tagName)), isTrue);
      expect(isExpectedClass(
          new SVGElement.svg('<$tagName></$tagName>')), isTrue);
    });
  }
  group('additionalConstructors', () {
    group('svg', () {
      test('valid', () {
        final svg = """
<svg version="1.1">
  <circle></circle>
  <path></path>
</svg>""";
        final el = new SVGElement.svg(svg);
        expect(el, isSVGSVGElement);
        expect(el.innerHTML, "<circle></circle><path></path>");
        expect(el.outerHTML, svg);
      });

      test('has no parent', () =>
        expect(new SVGElement.svg('<circle/>').parent, isNull)
      );

      test('empty', () {
        expect(() => new SVGElement.svg(""), throwsArgumentError);
      });

      test('too many elements', () {
        expect(() => new SVGElement.svg("<circle></circle><path></path>"),
            throwsArgumentError);
      });
    });
    testConstructor('altGlyphDef', (e) => e is SVGAltGlyphDefElement);
    testConstructor('altGlyph', (e) => e is SVGAltGlyphElement);
    testConstructor('animateColor', (e) => e is SVGAnimateColorElement);
    testConstructor('animate', (e) => e is SVGAnimateElement);
    // WebKit doesn't recognize animateMotion
    // testConstructor('animateMotion', (e) => e is SVGAnimateMotionElement);
    testConstructor('animateTransform', (e) => e is SVGAnimateTransformElement);
    testConstructor('cursor', (e) => e is SVGCursorElement);
    testConstructor('feBlend', (e) => e is SVGFEBlendElement);
    testConstructor('feColorMatrix', (e) => e is SVGFEColorMatrixElement);
    testConstructor('feComponentTransfer',
        (e) => e is SVGFEComponentTransferElement);
    testConstructor('feConvolveMatrix', (e) => e is SVGFEConvolveMatrixElement);
    testConstructor('feDiffuseLighting',
        (e) => e is SVGFEDiffuseLightingElement);
    testConstructor('feDisplacementMap',
        (e) => e is SVGFEDisplacementMapElement);
    testConstructor('feDistantLight', (e) => e is SVGFEDistantLightElement);
    testConstructor('feDropShadow', (e) => e is SVGFEDropShadowElement);
    testConstructor('feFlood', (e) => e is SVGFEFloodElement);
    testConstructor('feFuncA', (e) => e is SVGFEFuncAElement);
    testConstructor('feFuncB', (e) => e is SVGFEFuncBElement);
    testConstructor('feFuncG', (e) => e is SVGFEFuncGElement);
    testConstructor('feFuncR', (e) => e is SVGFEFuncRElement);
    testConstructor('feGaussianBlur', (e) => e is SVGFEGaussianBlurElement);
    testConstructor('feImage', (e) => e is SVGFEImageElement);
    testConstructor('feMerge', (e) => e is SVGFEMergeElement);
    testConstructor('feMergeNode', (e) => e is SVGFEMergeNodeElement);
    testConstructor('feOffset', (e) => e is SVGFEOffsetElement);
    testConstructor('fePointLight', (e) => e is SVGFEPointLightElement);
    testConstructor('feSpecularLighting',
        (e) => e is SVGFESpecularLightingElement);
    testConstructor('feSpotLight', (e) => e is SVGFESpotLightElement);
    testConstructor('feTile', (e) => e is SVGFETileElement);
    testConstructor('feTurbulence', (e) => e is SVGFETurbulenceElement);
    testConstructor('filter', (e) => e is SVGFilterElement);
    testConstructor('font', (e) => e is SVGFontElement);
    testConstructor('font-face', (e) => e is SVGFontFaceElement);
    testConstructor('font-face-format', (e) => e is SVGFontFaceFormatElement);
    testConstructor('font-face-name', (e) => e is SVGFontFaceNameElement);
    testConstructor('font-face-src', (e) => e is SVGFontFaceSrcElement);
    testConstructor('font-face-uri', (e) => e is SVGFontFaceUriElement);
    testConstructor('foreignObject', (e) => e is SVGForeignObjectElement);
    testConstructor('glyph', (e) => e is SVGGlyphElement);
    testConstructor('glyphRef', (e) => e is SVGGlyphRefElement);
    testConstructor('metadata', (e) => e is SVGMetadataElement);
    testConstructor('missing-glyph', (e) => e is SVGMissingGlyphElement);
    testConstructor('set', (e) => e is SVGSetElement);
    testConstructor('tref', (e) => e is SVGTRefElement);
    testConstructor('vkern', (e) => e is SVGVKernElement);
  });

  group('constructors', () {
    testConstructor('a', (e) => e is SVGAElement);
    testConstructor('circle', (e) => e is SVGCircleElement);
    testConstructor('clipPath', (e) => e is SVGClipPathElement);
    testConstructor('defs', (e) => e is SVGDefsElement);
    testConstructor('desc', (e) => e is SVGDescElement);
    testConstructor('ellipse', (e) => e is SVGEllipseElement);
    testConstructor('g', (e) => e is SVGGElement);
    // WebKit doesn't recognize hkern
    // testConstructor('hkern', (e) => e is SVGHKernElement);
    testConstructor('image', (e) => e is SVGImageElement);
    testConstructor('line', (e) => e is SVGLineElement);
    testConstructor('linearGradient', (e) => e is SVGLinearGradientElement);
    // WebKit doesn't recognize mpath
    // testConstructor('mpath', (e) => e is SVGMPathElement);
    testConstructor('marker', (e) => e is SVGMarkerElement);
    testConstructor('mask', (e) => e is SVGMaskElement);
    testConstructor('path', (e) => e is SVGPathElement);
    testConstructor('pattern', (e) => e is SVGPatternElement);
    testConstructor('polygon', (e) => e is SVGPolygonElement);
    testConstructor('polyline', (e) => e is SVGPolylineElement);
    testConstructor('radialGradient', (e) => e is SVGRadialGradientElement);
    testConstructor('rect', (e) => e is SVGRectElement);
    testConstructor('script', (e) => e is SVGScriptElement);
    testConstructor('stop', (e) => e is SVGStopElement);
    testConstructor('style', (e) => e is SVGStyleElement);
    testConstructor('switch', (e) => e is SVGSwitchElement);
    testConstructor('symbol', (e) => e is SVGSymbolElement);
    testConstructor('tspan', (e) => e is SVGTSpanElement);
    testConstructor('text', (e) => e is SVGTextElement);
    testConstructor('textPath', (e) => e is SVGTextPathElement);
    testConstructor('title', (e) => e is SVGTitleElement);
    testConstructor('use', (e) => e is SVGUseElement);
    testConstructor('view', (e) => e is SVGViewElement);
  });

  group('outerHTML', () {
    test('outerHTML', () {
      final el = new SVGSVGElement();
      el.elements.add(new SVGElement.tag("circle"));
      el.elements.add(new SVGElement.tag("path"));
      expect(el.outerHTML,
          '<svg version="1.1"><circle></circle><path></path></svg>');
    });
  });

  group('innerHTML', () {
    test('get', () {
      final el = new SVGSVGElement();
      el.elements.add(new SVGElement.tag("circle"));
      el.elements.add(new SVGElement.tag("path"));
      expect(el.innerHTML, '<circle></circle><path></path>');
    });

    test('set', () {
      final el = new SVGSVGElement();
      el.elements.add(new SVGElement.tag("circle"));
      el.elements.add(new SVGElement.tag("path"));
      el.innerHTML = '<rect></rect><a></a>';
      expect(_nodeStrings(el.elements), ["rect", "a"]);
    });
  });

  group('elementget', () {
    test('get', () {
      final el = new SVGElement.svg("""
<svg version="1.1">
  <circle></circle>
  <path></path>
  text
</svg>""");
      expect(_nodeStrings(el.elements), ["circle", "path"]);
    });
  });

  group('elementset', () {
    test('set', () {
      final el = new SVGSVGElement();
      el.elements = [new SVGElement.tag("circle"), new SVGElement.tag("path")];
      expect(el.innerHTML, '<circle></circle><path></path>');
    });
  });

  group('css', () {
    test('classes', () {
      var el = new SVGElement.tag("circle");
      var classes = el.classes;
      expect(el.classes.length, 0);
      classes.toggle('foo');
      expect(el.classes.length, 1);
      classes.toggle('foo');
      expect(el.classes.length, 0);
    });
  });
}

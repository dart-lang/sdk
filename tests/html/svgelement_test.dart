// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library SvgElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:svg' as svg;

main() {
  useHtmlIndividualConfiguration();

  var isSvgSvgElement =
      predicate((x) => x is svg.SvgSvgElement, 'is a SvgSvgElement');

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
      expect(isExpectedClass(new svg.SvgElement.tag(tagName)), isTrue);
      expect(isExpectedClass(
          new svg.SvgElement.svg('<$tagName></$tagName>')), isTrue);
    });
  }
  group('additionalConstructors', () {
    group('svg', () {
      test('valid', () {
        final svgContent = """
<svg version="1.1">
  <circle></circle>
  <path></path>
</svg>""";
        final el = new svg.SvgElement.svg(svgContent);
        expect(el, isSvgSvgElement);
        expect(el.innerHTML, "<circle></circle><path></path>");
        expect(el.outerHTML, svgContent);
      });

      test('has no parent', () =>
        expect(new svg.SvgElement.svg('<circle/>').parent, isNull)
      );

      test('empty', () {
        expect(() => new svg.SvgElement.svg(""), throwsArgumentError);
      });

      test('too many elements', () {
        expect(() => new svg.SvgElement.svg("<circle></circle><path></path>"),
            throwsArgumentError);
      });
    });
    testConstructor('altGlyphDef', (e) => e is svg.AltGlyphDefElement);
    testConstructor('altGlyph', (e) => e is svg.AltGlyphElement);
    testConstructor('animateColor', (e) => e is svg.AnimateColorElement);
    testConstructor('animate', (e) => e is svg.AnimateElement);
    // WebKit doesn't recognize animateMotion
    // testConstructor('animateMotion', (e) => e is svg.AnimateMotionElement);
    testConstructor('animateTransform', (e) => e is svg.AnimateTransformElement);
    testConstructor('cursor', (e) => e is svg.CursorElement);
    testConstructor('feBlend', (e) => e is svg.FEBlendElement);
    testConstructor('feColorMatrix', (e) => e is svg.FEColorMatrixElement);
    testConstructor('feComponentTransfer',
        (e) => e is svg.FEComponentTransferElement);
    testConstructor('feConvolveMatrix', (e) => e is svg.FEConvolveMatrixElement);
    testConstructor('feDiffuseLighting',
        (e) => e is svg.FEDiffuseLightingElement);
    testConstructor('feDisplacementMap',
        (e) => e is svg.FEDisplacementMapElement);
    testConstructor('feDistantLight', (e) => e is svg.FEDistantLightElement);
    testConstructor('feDropShadow', (e) => e is svg.FEDropShadowElement);
    testConstructor('feFlood', (e) => e is svg.FEFloodElement);
    testConstructor('feFuncA', (e) => e is svg.FEFuncAElement);
    testConstructor('feFuncB', (e) => e is svg.FEFuncBElement);
    testConstructor('feFuncG', (e) => e is svg.FEFuncGElement);
    testConstructor('feFuncR', (e) => e is svg.FEFuncRElement);
    testConstructor('feGaussianBlur', (e) => e is svg.FEGaussianBlurElement);
    testConstructor('feImage', (e) => e is svg.FEImageElement);
    testConstructor('feMerge', (e) => e is svg.FEMergeElement);
    testConstructor('feMergeNode', (e) => e is svg.FEMergeNodeElement);
    testConstructor('feOffset', (e) => e is svg.FEOffsetElement);
    testConstructor('fePointLight', (e) => e is svg.FEPointLightElement);
    testConstructor('feSpecularLighting',
        (e) => e is svg.FESpecularLightingElement);
    testConstructor('feSpotLight', (e) => e is svg.FESpotLightElement);
    testConstructor('feTile', (e) => e is svg.FETileElement);
    testConstructor('feTurbulence', (e) => e is svg.FETurbulenceElement);
    testConstructor('filter', (e) => e is svg.FilterElement);
    testConstructor('font', (e) => e is svg.FontElement);
    testConstructor('font-face', (e) => e is svg.FontFaceElement);
    testConstructor('font-face-format', (e) => e is svg.FontFaceFormatElement);
    testConstructor('font-face-name', (e) => e is svg.FontFaceNameElement);
    testConstructor('font-face-src', (e) => e is svg.FontFaceSrcElement);
    testConstructor('font-face-uri', (e) => e is svg.FontFaceUriElement);
    testConstructor('foreignObject', (e) => e is svg.ForeignObjectElement);
    testConstructor('glyph', (e) => e is svg.GlyphElement);
    testConstructor('glyphRef', (e) => e is svg.GlyphRefElement);
    testConstructor('metadata', (e) => e is svg.MetadataElement);
    testConstructor('missing-glyph', (e) => e is svg.MissingGlyphElement);
    testConstructor('set', (e) => e is svg.SetElement);
    testConstructor('tref', (e) => e is svg.TRefElement);
    testConstructor('vkern', (e) => e is svg.VKernElement);
  });

  group('constructors', () {
    testConstructor('a', (e) => e is svg.AElement);
    testConstructor('circle', (e) => e is svg.CircleElement);
    testConstructor('clipPath', (e) => e is svg.ClipPathElement);
    testConstructor('defs', (e) => e is svg.DefsElement);
    testConstructor('desc', (e) => e is svg.DescElement);
    testConstructor('ellipse', (e) => e is svg.EllipseElement);
    testConstructor('g', (e) => e is svg.GElement);
    // WebKit doesn't recognize hkern
    // testConstructor('hkern', (e) => e is svg.HKernElement);
    testConstructor('image', (e) => e is svg.ImageElement);
    testConstructor('line', (e) => e is svg.LineElement);
    testConstructor('linearGradient', (e) => e is svg.LinearGradientElement);
    // WebKit doesn't recognize mpath
    // testConstructor('mpath', (e) => e is svg.MPathElement);
    testConstructor('marker', (e) => e is svg.MarkerElement);
    testConstructor('mask', (e) => e is svg.MaskElement);
    testConstructor('path', (e) => e is svg.PathElement);
    testConstructor('pattern', (e) => e is svg.PatternElement);
    testConstructor('polygon', (e) => e is svg.PolygonElement);
    testConstructor('polyline', (e) => e is svg.PolylineElement);
    testConstructor('radialGradient', (e) => e is svg.RadialGradientElement);
    testConstructor('rect', (e) => e is svg.RectElement);
    testConstructor('script', (e) => e is svg.ScriptElement);
    testConstructor('stop', (e) => e is svg.StopElement);
    testConstructor('style', (e) => e is svg.StyleElement);
    testConstructor('switch', (e) => e is svg.SwitchElement);
    testConstructor('symbol', (e) => e is svg.SymbolElement);
    testConstructor('tspan', (e) => e is svg.TSpanElement);
    testConstructor('text', (e) => e is svg.TextElement);
    testConstructor('textPath', (e) => e is svg.TextPathElement);
    testConstructor('title', (e) => e is svg.TitleElement);
    testConstructor('use', (e) => e is svg.UseElement);
    testConstructor('view', (e) => e is svg.ViewElement);
  });

  group('outerHTML', () {
    test('outerHTML', () {
      final el = new svg.SvgSvgElement();
      el.elements.add(new svg.CircleElement());
      el.elements.add(new svg.PathElement());
      expect(el.outerHTML,
          '<svg version="1.1"><circle></circle><path></path></svg>');
    });
  });

  group('innerHTML', () {
    test('get', () {
      final el = new svg.SvgSvgElement();
      el.elements.add(new svg.CircleElement());
      el.elements.add(new svg.PathElement());
      expect(el.innerHTML, '<circle></circle><path></path>');
    });

    test('set', () {
      final el = new svg.SvgSvgElement();
      el.elements.add(new svg.CircleElement());
      el.elements.add(new svg.PathElement());
      el.innerHTML = '<rect></rect><a></a>';
      expect(_nodeStrings(el.elements), ["rect", "a"]);
    });
  });

  group('elementget', () {
    test('get', () {
      final el = new svg.SvgElement.svg("""
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
      final el = new svg.SvgSvgElement();
      el.elements = [new svg.SvgElement.tag("circle"), new svg.SvgElement.tag("path")];
      expect(el.innerHTML, '<circle></circle><path></path>');
    });
  });

  group('css', () {
    test('classes', () {
      var el = new svg.CircleElement();
      var classes = el.classes;
      expect(el.classes.length, 0);
      classes.toggle('foo');
      expect(el.classes.length, 1);
      classes.toggle('foo');
      expect(el.classes.length, 0);
    });
  });
}

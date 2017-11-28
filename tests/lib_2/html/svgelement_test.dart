// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:svg' as svg;

import 'package:expect/minitest.dart';

main() {
  var isSvgSvgElement =
      predicate((x) => x is svg.SvgSvgElement, 'is a SvgSvgElement');

  List<String> _nodeStrings(Iterable<Node> input) {
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
  }

  ;

  testConstructor(String tagName, Function isExpectedClass,
      [bool expectation = true, allowsInnerHtml = true]) {
    test(tagName, () {
      expect(isExpectedClass(new svg.SvgElement.tag(tagName)), expectation);
      if (allowsInnerHtml) {
        expect(isExpectedClass(new svg.SvgElement.svg('<$tagName></$tagName>')),
            expectation && allowsInnerHtml);
      }
    });
  }

  group('additionalConstructors', () {
    test('valid', () {
      final svgContent = "<svg version=\"1.1\">\n"
          "  <circle></circle>\n"
          "  <path></path>\n"
          "</svg>";
      final el = new svg.SvgElement.svg(svgContent);
      expect(el, isSvgSvgElement);
      expect(
          el.innerHtml,
          anyOf([
            "<circle></circle><path></path>",
            '<circle '
                'xmlns="http://www.w3.org/2000/svg" /><path '
                'xmlns="http://www.w3.org/2000/svg" />'
          ]));
      expect(
          el.outerHtml,
          anyOf([
            svgContent,
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n  '
                '<circle />\n  <path />\n</svg>'
          ]));
    });

    test('has no parent',
        () => expect(new svg.SvgElement.svg('<circle/>').parent, isNull));

    test('empty', () {
      expect(() => new svg.SvgElement.svg(""), throwsStateError);
    });

    test('too many elements', () {
      expect(() => new svg.SvgElement.svg("<circle></circle><path></path>"),
          throwsStateError);
    });
  });

  // Unfortunately, because the filtering mechanism in unittest is a regex done
  group('supported_animate', () {
    test('supported', () {
      expect(svg.AnimateElement.supported, true);
    });
  });

  group('supported_animateMotion', () {
    test('supported', () {
      expect(svg.AnimateMotionElement.supported, true);
    });
  });

  group('supported_animateTransform', () {
    test('supported', () {
      expect(svg.AnimateTransformElement.supported, true);
    });
  });

  group('supported_feBlend', () {
    test('supported', () {
      expect(svg.FEBlendElement.supported, true);
    });
  });

  group('supported_feColorMatrix', () {
    test('supported', () {
      expect(svg.FEColorMatrixElement.supported, true);
    });
  });

  group('supported_feComponentTransfer', () {
    test('supported', () {
      expect(svg.FEComponentTransferElement.supported, true);
    });
  });

  group('supported_feConvolveMatrix', () {
    test('supported', () {
      expect(svg.FEConvolveMatrixElement.supported, true);
    });
  });

  group('supported_feDiffuseLighting', () {
    test('supported', () {
      expect(svg.FEDiffuseLightingElement.supported, true);
    });
  });

  group('supported_feDisplacementMap', () {
    test('supported', () {
      expect(svg.FEDisplacementMapElement.supported, true);
    });
  });

  group('supported_feDistantLight', () {
    test('supported', () {
      expect(svg.FEDistantLightElement.supported, true);
    });
  });

  group('supported_feFlood', () {
    test('supported', () {
      expect(svg.FEFloodElement.supported, true);
    });
  });

  group('supported_feFuncA', () {
    test('supported', () {
      expect(svg.FEFuncAElement.supported, true);
    });
  });

  group('supported_feFuncB', () {
    test('supported', () {
      expect(svg.FEFuncBElement.supported, true);
    });
  });

  group('supported_feFuncG', () {
    test('supported', () {
      expect(svg.FEFuncGElement.supported, true);
    });
  });

  group('supported_feFuncR', () {
    test('supported', () {
      expect(svg.FEFuncRElement.supported, true);
    });
  });

  group('supported_feGaussianBlur', () {
    test('supported', () {
      expect(svg.FEGaussianBlurElement.supported, true);
    });
  });

  group('supported_feImage', () {
    test('supported', () {
      expect(svg.FEImageElement.supported, true);
    });
  });

  group('supported_feMerge', () {
    test('supported', () {
      expect(svg.FEMergeElement.supported, true);
    });
  });

  group('supported_feMergeNode', () {
    test('supported', () {
      expect(svg.FEMergeNodeElement.supported, true);
    });
  });

  group('supported_feOffset', () {
    test('supported', () {
      expect(svg.FEOffsetElement.supported, true);
    });
  });

  group('supported_feComponentTransfer', () {
    test('supported', () {
      expect(svg.FEPointLightElement.supported, true);
    });
  });

  group('supported_feSpecularLighting', () {
    test('supported', () {
      expect(svg.FESpecularLightingElement.supported, true);
    });
  });

  group('supported_feComponentTransfer', () {
    test('supported', () {
      expect(svg.FESpotLightElement.supported, true);
    });
  });

  group('supported_feTile', () {
    test('supported', () {
      expect(svg.FETileElement.supported, true);
    });
  });

  group('supported_feTurbulence', () {
    test('supported', () {
      expect(svg.FETurbulenceElement.supported, true);
    });
  });

  group('supported_filter', () {
    test('supported', () {
      expect(svg.FilterElement.supported, true);
    });
  });

  group('supported_foreignObject', () {
    test('supported', () {
      expect(svg.ForeignObjectElement.supported, true);
    });
  });

  group('supported_set', () {
    test('supported', () {
      expect(svg.SetElement.supported, true);
    });
  });

  group('constructors', () {
    testConstructor('a', (e) => e is svg.AElement);
    testConstructor('circle', (e) => e is svg.CircleElement);
    testConstructor('clipPath', (e) => e is svg.ClipPathElement);
    testConstructor('defs', (e) => e is svg.DefsElement);
    testConstructor('desc', (e) => e is svg.DescElement);
    testConstructor('ellipse', (e) => e is svg.EllipseElement);
    testConstructor('g', (e) => e is svg.GElement);
    testConstructor('image', (e) => e is svg.ImageElement);
    testConstructor('line', (e) => e is svg.LineElement);
    testConstructor('linearGradient', (e) => e is svg.LinearGradientElement);
    testConstructor('marker', (e) => e is svg.MarkerElement);
    testConstructor('mask', (e) => e is svg.MaskElement);
    testConstructor('path', (e) => e is svg.PathElement);
    testConstructor('pattern', (e) => e is svg.PatternElement);
    testConstructor('polygon', (e) => e is svg.PolygonElement);
    testConstructor('polyline', (e) => e is svg.PolylineElement);
    testConstructor('radialGradient', (e) => e is svg.RadialGradientElement);
    testConstructor('rect', (e) => e is svg.RectElement);
    test('script', () {
      expect(new svg.SvgElement.tag('script') is svg.ScriptElement, isTrue);
    });
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
    // TODO(alanknight): Issue 23144
    testConstructor('animate', (e) => e is svg.AnimateElement,
        svg.AnimateElement.supported);
    testConstructor('animateMotion', (e) => e is svg.AnimateMotionElement,
        svg.AnimateMotionElement.supported);
    testConstructor('animateTransform', (e) => e is svg.AnimateTransformElement,
        svg.AnimateTransformElement.supported);
    testConstructor('feBlend', (e) => e is svg.FEBlendElement,
        svg.FEBlendElement.supported);
    testConstructor('feColorMatrix', (e) => e is svg.FEColorMatrixElement,
        svg.FEColorMatrixElement.supported);
    testConstructor(
        'feComponentTransfer',
        (e) => e is svg.FEComponentTransferElement,
        svg.FEComponentTransferElement.supported);
    testConstructor('feConvolveMatrix', (e) => e is svg.FEConvolveMatrixElement,
        svg.FEConvolveMatrixElement.supported);
    testConstructor(
        'feDiffuseLighting',
        (e) => e is svg.FEDiffuseLightingElement,
        svg.FEDiffuseLightingElement.supported);
    testConstructor(
        'feDisplacementMap',
        (e) => e is svg.FEDisplacementMapElement,
        svg.FEDisplacementMapElement.supported);
    testConstructor('feDistantLight', (e) => e is svg.FEDistantLightElement,
        svg.FEDistantLightElement.supported);
    testConstructor('feFlood', (e) => e is svg.FEFloodElement,
        svg.FEFloodElement.supported);
    testConstructor('feFuncA', (e) => e is svg.FEFuncAElement,
        svg.FEFuncAElement.supported);
    testConstructor('feFuncB', (e) => e is svg.FEFuncBElement,
        svg.FEFuncBElement.supported);
    testConstructor('feFuncG', (e) => e is svg.FEFuncGElement,
        svg.FEFuncGElement.supported);
    testConstructor('feFuncR', (e) => e is svg.FEFuncRElement,
        svg.FEFuncRElement.supported);
    testConstructor('feGaussianBlur', (e) => e is svg.FEGaussianBlurElement,
        svg.FEGaussianBlurElement.supported);
    testConstructor('feImage', (e) => e is svg.FEImageElement,
        svg.FEImageElement.supported);
    testConstructor('feMerge', (e) => e is svg.FEMergeElement,
        svg.FEMergeElement.supported);
    testConstructor('feMergeNode', (e) => e is svg.FEMergeNodeElement,
        svg.FEMergeNodeElement.supported);
    testConstructor('feOffset', (e) => e is svg.FEOffsetElement,
        svg.FEOffsetElement.supported);
    testConstructor('fePointLight', (e) => e is svg.FEPointLightElement,
        svg.FEPointLightElement.supported);
    testConstructor(
        'feSpecularLighting',
        (e) => e is svg.FESpecularLightingElement,
        svg.FESpecularLightingElement.supported);
    testConstructor('feSpotLight', (e) => e is svg.FESpotLightElement,
        svg.FESpotLightElement.supported);
    testConstructor(
        'feTile', (e) => e is svg.FETileElement, svg.FETileElement.supported);
    testConstructor('feTurbulence', (e) => e is svg.FETurbulenceElement,
        svg.FETurbulenceElement.supported);
    testConstructor(
        'filter', (e) => e is svg.FilterElement, svg.FilterElement.supported);
    testConstructor('foreignObject', (e) => e is svg.ForeignObjectElement,
        svg.ForeignObjectElement.supported, false);
    testConstructor('metadata', (e) => e is svg.MetadataElement);
    testConstructor(
        'set', (e) => e is svg.SetElement, svg.SetElement.supported);
  });

  group('outerHtml', () {
    test('outerHtml', () {
      final el = new svg.SvgSvgElement();
      el.children.add(new svg.CircleElement());
      el.children.add(new svg.PathElement());
      expect(
          [
            '<svg version="1.1"><circle></circle><path></path></svg>',
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1">'
                '<circle /><path /></svg>',
          ].contains(el.outerHtml),
          true);
    });
  });

  group('innerHtml', () {
    test('get', () {
      final el = new svg.SvgSvgElement();
      el.children.add(new svg.CircleElement());
      el.children.add(new svg.PathElement());
      // Allow for odd IE serialization.
      expect(
          [
            '<circle></circle><path></path>',
            '<circle xmlns="http://www.w3.org/2000/svg" />'
                '<path xmlns="http://www.w3.org/2000/svg" />'
          ].contains(el.innerHtml),
          true);
    });

    test('set', () {
      final el = new svg.SvgSvgElement();
      el.children.add(new svg.CircleElement());
      el.children.add(new svg.PathElement());
      el.innerHtml = '<rect></rect><a></a>';
      expect(_nodeStrings(el.children), ["rect", "a"]);
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
      expect(_nodeStrings(el.children), ["circle", "path"]);
    });

    test('resize', () {
      var el = new svg.SvgSvgElement();
      var items = [new svg.CircleElement(), new svg.RectElement()];
      el.children = items;
      expect(el.children.length, 2);
      el.children.length = 1;
      expect(el.children.length, 1);
      expect(el.children.contains(items[0]), true);
      expect(el.children.contains(items[1]), false);

      el.children.length = 0;
      expect(el.children.contains(items[0]), false);
    });
  });

  group('elementset', () {
    test('set', () {
      final el = new svg.SvgSvgElement();
      el.children = [
        new svg.SvgElement.tag("circle"),
        new svg.SvgElement.tag("path")
      ];
      expect(el.nodes.length, 2);
      expect(el.nodes[0] is svg.CircleElement, true);
      expect(el.nodes[1] is svg.PathElement, true);
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

    test('classes-add-bad', () {
      var el = new svg.CircleElement();
      expect(() => el.classes.add(''), throws);
      expect(() => el.classes.add('foo bar'), throws);
    });
    test('classes-remove-bad', () {
      var el = new svg.CircleElement();
      expect(() => el.classes.remove(''), throws);
      expect(() => el.classes.remove('foo bar'), throws);
    });
    test('classes-toggle-token', () {
      var el = new svg.CircleElement();
      expect(() => el.classes.toggle(''), throws);
      expect(() => el.classes.toggle('', true), throws);
      expect(() => el.classes.toggle('', false), throws);
      expect(() => el.classes.toggle('foo bar'), throws);
      expect(() => el.classes.toggle('foo bar', true), throws);
      expect(() => el.classes.toggle('foo bar', false), throws);
    });
    test('classes-contains-bad', () {
      var el = new svg.CircleElement();
      // Non-strings => false, strings must be valid tokens.
      expect(el.classes.contains(1), isFalse);
      expect(() => el.classes.contains(''), throws);
      expect(() => el.classes.contains('foo bar'), throws);
    });
  });

  group('getBoundingClientRect', () {
    test('is a Rectangle', () {
      var element = new svg.RectElement();
      element.attributes['width'] = '100';
      element.attributes['height'] = '100';
      var root = new svg.SvgSvgElement();
      root.append(element);

      document.body.append(root);

      var rect = element.getBoundingClientRect();
      expect(rect is Rectangle, isTrue);
      expect(rect.width, closeTo(100, 1));
      expect(rect.height, closeTo(100, 1));
    });
  });
}

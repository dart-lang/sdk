// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library validator_test;

import 'dart:async';
import 'dart:html';
import 'dart:svg' as svg;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'utils.dart';


var nullSanitizer = new NullTreeSanitizer();

void validateHtml(String html, String reference, NodeValidator validator) {
  var a = document.body.createFragment(html, validator: validator);
  var b = document.body.createFragment(reference,
      treeSanitizer: nullSanitizer);

  validateNodeTree(a, b);
}

class RecordingUriValidator implements UriPolicy {
  final List<String> calls = <String>[];

  bool allowsUri(String uri) {
    calls.add('$uri');
    return false;
  }

  void reset() {
    calls.clear();
  }
}

void testHtml(String name, NodeValidator validator, String html,
  [String reference]) {
  test(name, () {
    if (reference == null) {
      reference = html;
    }

    validateHtml(html, reference, validator);
  });
}

main() {
  useHtmlConfiguration();

  group('DOM sanitization', () {
    var validator = new NodeValidatorBuilder.common();

    testHtml('allows simple constructs',
        validator,
        '<div class="baz">something</div>');

    testHtml('blocks unknown attributes',
        validator,
        '<div foo="baz">something</div>',
        '<div>something</div>');

    testHtml('blocks custom element',
        validator,
        '<x-my-element>something</x-my-element>',
        '');

    testHtml('blocks custom is element',
        validator,
        '<div is="x-my-element">something</div>',
        '');

    testHtml('blocks body elements',
        validator,
        '<body background="s"></body>',
        '');

    testHtml('allows select elements',
        validator,
        '<select>'
          '<option>a</option>'
        '</select>');

    testHtml('blocks sequential script elements',
        validator,
        '<div><script></script><script></script></div>',
        '<div></div>');

    testHtml('blocks namespaced attributes',
        validator,
        '<div ns:foo="foo"></div>',
        '<div></div>');

    testHtml('blocks namespaced common attributes',
        validator,
        '<div ns:class="foo"></div>',
        '<div></div>');

    testHtml('blocks namespaced common elements',
        validator,
        '<ns:div></ns:div>',
        '');

    testHtml('allows CDATA sections',
        validator,
        '<span>![CDATA[ some text ]]></span>');

    test('sanitizes template contents', () {
      var html = '<template>'
          '<div></div>'
          '<script></script>'
          '<img src="http://example.com/foo"/>'
        '</template>';

      var fragment = document.body.createFragment(html, validator: validator);
      var template = fragment.nodes.single;

      var expectedContent = document.body.createFragment(
          '<div></div>'
          '<img/>');

      validateNodeTree(template.content, expectedContent);
    });
  });

  group('URI sanitization', () {
    var recorder = new RecordingUriValidator();
    var validator = new NodeValidatorBuilder()..allowHtml5(uriPolicy: recorder);

    checkUriPolicyCalls(String name, String html, String reference,
        List<String> expectedCalls) {

      test(name, () {
        recorder.reset();

        validateHtml(html, reference, validator);
        expect(recorder.calls, expectedCalls);
      });
    }

    checkUriPolicyCalls('a::href',
        '<a href="s"></a>',
        '<a></a>',
        ['s']);

    checkUriPolicyCalls('area::href',
        '<area href="s"></area>',
        '<area></area>',
        ['s']);

    checkUriPolicyCalls('blockquote::cite',
        '<blockquote cite="s"></blockquote>',
        '<blockquote></blockquote>',
        ['s']);
    checkUriPolicyCalls('command::icon',
        '<command icon="s"/>',
        '<command/>',
        ['s']);
    checkUriPolicyCalls('img::src',
        '<img src="s"/>',
        '<img/>',
        ['s']);
    checkUriPolicyCalls('input::src',
        '<input src="s"/>',
        '<input/>',
        ['s']);
    checkUriPolicyCalls('ins::cite',
        '<ins cite="s"></ins>',
        '<ins></ins>',
        ['s']);
    checkUriPolicyCalls('q::cite',
        '<q cite="s"></q>',
        '<q></q>',
        ['s']);
    checkUriPolicyCalls('video::poster',
        '<video poster="s"/>',
        '<video/>',
        ['s']);
  });

  group('NodeValidationPolicy', () {

    group('allowNavigation', () {
      var validator = new NodeValidatorBuilder()..allowNavigation();

      testHtml('allows anchor tags',
          validator,
          '<a href="#foo">foo</a>');

      testHtml('allows form elements',
          validator,
          '<form method="post" action="/foo"></form>');

      testHtml('disallows script navigation',
          validator,
          '<a href="javascript:foo = 1">foo</a>',
          '<a>foo</a>');

      testHtml('disallows cross-site navigation',
          validator,
          '<a href="http://example.com">example.com</a>',
          '<a>example.com</a>');

      testHtml('blocks other elements',
          validator,
          '<a href="#foo"><b>foo</b></a>',
          '<a href="#foo"></a>');

      testHtml('blocks tag extension',
          validator,
          '<a is="x-foo"></a>',
          '');
    });

    group('allowImages', () {
      var validator = new NodeValidatorBuilder()..allowImages();

      testHtml('allows images',
          validator,
          '<img src="/foo.jpg" alt="something" width="100" height="100"/>');

      testHtml('blocks onerror',
          validator,
          '<img src="/foo.jpg" onerror="something"/>',
          '<img src="/foo.jpg"/>');

      testHtml('enforces same-origin',
          validator,
          '<img src="http://example.com/foo.jpg"/>',
          '<img/>');
    });

    group('allowCustomElement', () {
      var validator = new NodeValidatorBuilder()
        ..allowCustomElement(
            'x-foo',
            attributes: ['bar'],
            uriAttributes: ['baz'])
        ..allowHtml5();

      testHtml('allows custom elements',
          validator,
          '<x-foo bar="something" baz="/foo.jpg"></x-foo>');


      testHtml('validates custom tag URIs',
          validator,
          '<x-foo baz="http://example.com/foo.jpg"></x-foo>',
          '<x-foo></x-foo>');

      testHtml('blocks type extensions',
          validator,
          '<div is="x-foo"></div>',
          '');

      testHtml('blocks tags on non-matching elements',
          validator,
          '<div bar="foo"></div>',
          '<div></div>');
    });

    group('allowTagExtension', () {
       var validator = new NodeValidatorBuilder()
        ..allowTagExtension(
            'x-foo',
            'div',
            attributes: ['bar'],
            uriAttributes: ['baz'])
        ..allowHtml5();

      testHtml('allows tag extensions',
          validator,
          '<div is="x-foo" bar="something" baz="/foo.jpg"></div>');

      testHtml('blocks custom elements',
            validator,
            '<x-foo></x-foo>',
            '');

      testHtml('validates tag extension URIs',
          validator,
          '<div is="x-foo" baz="http://example.com/foo.jpg"></div>',
          '<div is="x-foo"></div>');

      testHtml('blocks tags on non-matching elements',
          validator,
          '<div bar="foo"></div>',
          '<div></div>');

      testHtml('blocks non-matching tags',
          validator,
          '<span is="x-foo">something</span>',
          '');

      validator = new NodeValidatorBuilder()
        ..allowTagExtension(
            'x-foo',
            'div',
            attributes: ['bar'],
            uriAttributes: ['baz'])
        ..allowTagExtension(
            'x-else',
            'div');

      testHtml('blocks tags on non-matching custom elements',
          validator,
          '<div bar="foo" is="x-else"></div>',
          '<div is="x-else"></div>');
    });

    group('allowTemplating', () {
      var validator = new NodeValidatorBuilder()
        ..allowTemplating()
        ..allowHtml5();

      testHtml('allows templates',
          validator,
          '<template bind="{{a}}"></template>');

      testHtml('allows template attributes',
          validator,
          '<template bind="{{a}}" ref="foo" repeat="{{}}" if="{{}}" syntax="foo"></template>');

      testHtml('allows template attribute',
          validator,
          '<div template repeat="{{}}"></div>');

      testHtml('blocks illegal template attribute',
          validator,
          '<div template="foo" repeat="{{}}"></div>',
          '<div></div>');
    });

    group('allowSvg', () {
      var validator = new NodeValidatorBuilder()..allowSvg();

      testHtml('allows basic SVG',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
          '<image xlink:href="foo" data-foo="bar"/>'
        '</svg>');

      testHtml('blocks script elements',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg>'
          '<script></script>'
        '</svg>',
        '<svg xmlns="http://www.w3.org/2000/svg></svg>');

      testHtml('blocks script handlers',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
          '<image xlink:href="foo" onerror="something"/>'
        '</svg>',
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
          '<image xlink:href="foo"/>'
        '</svg>');

      testHtml('blocks foreignObject content',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg>'
          '<foreignobject width="100" height="150">'
            '<body xmlns="http://www.w3.org/1999/xhtml">'
              '<div>Some content</div>'
            '</body>'
          '</foreignobject>'
        '</svg>',
        '<svg xmlns="http://www.w3.org/2000/svg>'
          '<foreignobject width="100" height="150"></foreignobject>'
        '</svg>');
    });
  });

  group('throws', () {
    var validator = new NodeValidator.throws(new NodeValidatorBuilder.common());

    var validationError = throwsArgumentError;

    test('does not throw on valid syntax', () {
      expect(() {
        document.body.createFragment('<div></div>', validator: validator);
      }, returnsNormally);
    });

    test('throws on invalid elements', () {
      expect(() {
        document.body.createFragment('<foo></foo>', validator: validator);
      }, validationError);
    });

    test('throws on invalid attributes', () {
      expect(() {
        document.body.createFragment('<div foo="bar"></div>',
            validator: validator);
      }, validationError);
    });

    test('throws on invalid attribute values', () {
      expect(() {
        document.body.createFragment('<img src="http://example.com/foo.jpg"/>',
            validator: validator);
      }, validationError);
    });
  });

  group('svg', () {
    test('parsing', () {
      var svgText =
        '<svg xmlns="http://www.w3.org/2000/svg'
            'xmlns:xlink="http://www.w3.org/1999/xlink">'
          '<image xlink:href="foo" data-foo="bar"/>'
        '</svg>';

      var fragment = new DocumentFragment.svg(svgText);
      var element = fragment.nodes.first;
      expect(element is svg.SvgSvgElement, isTrue);
      expect(element.children[0] is svg.ImageElement, isTrue);
    });
  });
}

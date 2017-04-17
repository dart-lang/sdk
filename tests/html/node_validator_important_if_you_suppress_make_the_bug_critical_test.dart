// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tests HTML validation and sanitization, which is very important
/// for prevent XSS or other attacks. If you suppress this, or parts of it
/// please make it a critical bug and bring it to the attention of the
/// dart:html maintainers.
library node_validator_test;

import 'dart:html';
import 'dart:svg' as svg;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'utils.dart';

void validateHtml(String html, String reference, NodeValidator validator) {
  var a = document.body.createFragment(html, validator: validator);
  var b = document.body
      .createFragment(reference, treeSanitizer: NodeTreeSanitizer.trusted);

  // Prevent a false pass when both the html and the reference both get entirely
  // deleted, which is technically a match, but unlikely to be what we meant.
  if (reference != '') {
    expect(b.childNodes.length > 0, isTrue);
  }
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
  useHtmlIndividualConfiguration();

  group('DOM_sanitization', () {
    var validator = new NodeValidatorBuilder.common();

    testHtml('allows simple constructs', validator,
        '<div class="baz">something</div>');

    testHtml('blocks unknown attributes', validator,
        '<div foo="baz">something</div>', '<div>something</div>');

    testHtml('blocks custom element', validator,
        '<x-my-element>something</x-my-element>', '');

    testHtml('blocks custom is element', validator,
        '<div is="x-my-element">something</div>', '');

    testHtml(
        'blocks body elements', validator, '<body background="s"></body>', '');

    testHtml(
        'allows select elements',
        validator,
        '<select>'
        '<option>a</option>'
        '</select>');

    testHtml('blocks sequential script elements', validator,
        '<div><script></script><script></script></div>', '<div></div>');

    testHtml('blocks inline styles', validator,
        '<div style="background: red"></div>', '<div></div>');

    testHtml('blocks namespaced attributes', validator,
        '<div ns:foo="foo"></div>', '<div></div>');

    testHtml('blocks namespaced common attributes', validator,
        '<div ns:class="foo"></div>', '<div></div>');

    testHtml('blocks namespaced common elements', validator,
        '<ns:div></ns:div>', '');

    testHtml('allows CDATA sections', validator,
        '<span>![CDATA[ some text ]]></span>');

    testHtml('backquotes not removed', validator,
        '<img src="dice.png" alt="``onload=xss()" />');

    testHtml('0x3000 not removed', validator,
        '<a href="&#x3000;javascript:alert(1)">CLICKME</a>');

    test('sanitizes template contents', () {
      if (!TemplateElement.supported) return;

      var html = '<template>'
          '<div></div>'
          '<script></script>'
          '<img src="http://example.com/foo"/>'
          '</template>';

      var fragment = document.body.createFragment(html, validator: validator);
      var template = fragment.nodes.single;

      var expectedContent = document.body.createFragment('<div></div>'
          '<img/>');

      validateNodeTree(template.content, expectedContent);
    });

    test("appendHtml is sanitized", () {
      var html = '<body background="s"></body><div></div>';
      document.body.appendHtml('<div id="stuff"></div>');
      var stuff = document.querySelector("#stuff");
      stuff.appendHtml(html);
      expect(stuff.childNodes.length, 1);
      stuff.remove();
    });

    test("documentFragment.appendHtml is sanitized", () {
      var html = '<div id="things></div>';
      var fragment = new DocumentFragment.html(html);
      fragment.appendHtml('<div id="bad"><script></script></div>');
      expect(fragment.childNodes.length, 1);
      expect(fragment.childNodes[0].id, "bad");
      expect(fragment.childNodes[0].childNodes.length, 0);
    });

    testHtml(
        "sanitizes embed",
        validator,
        "<div><embed src='' type='application/x-shockwave-flash'></embed></div>",
        "<div></div>");
  });

  group('URI_sanitization', () {
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

    checkUriPolicyCalls('a::href', '<a href="s"></a>', '<a></a>', ['s']);

    checkUriPolicyCalls(
        'area::href', '<area href="s"></area>', '<area></area>', ['s']);

    checkUriPolicyCalls(
        'blockquote::cite',
        '<blockquote cite="s"></blockquote>',
        '<blockquote></blockquote>',
        ['s']);
    checkUriPolicyCalls(
        'command::icon', '<command icon="s"/>', '<command/>', ['s']);
    checkUriPolicyCalls('img::src', '<img src="s"/>', '<img/>', ['s']);
    checkUriPolicyCalls('input::src', '<input src="s"/>', '<input/>', ['s']);
    checkUriPolicyCalls(
        'ins::cite', '<ins cite="s"></ins>', '<ins></ins>', ['s']);
    checkUriPolicyCalls('q::cite', '<q cite="s"></q>', '<q></q>', ['s']);
    checkUriPolicyCalls(
        'video::poster', '<video poster="s"/>', '<video/>', ['s']);
  });

  group('allowNavigation', () {
    var validator = new NodeValidatorBuilder()..allowNavigation();

    testHtml('allows anchor tags', validator, '<a href="#foo">foo</a>');

    testHtml('allows form elements', validator,
        '<form method="post" action="/foo"></form>');

    testHtml('disallows script navigation', validator,
        '<a href="javascript:foo = 1">foo</a>', '<a>foo</a>');

    testHtml('disallows cross-site navigation', validator,
        '<a href="http://example.com">example.com</a>', '<a>example.com</a>');

    testHtml('blocks other elements', validator,
        '<a href="#foo"><b>foo</b></a>', '<a href="#foo"></a>');

    testHtml('blocks tag extension', validator, '<a is="x-foo"></a>', '');
  });

  group('allowImages', () {
    var validator = new NodeValidatorBuilder()..allowImages();

    testHtml('allows images', validator,
        '<img src="/foo.jpg" alt="something" width="100" height="100"/>');

    testHtml('blocks onerror', validator,
        '<img src="/foo.jpg" onerror="something"/>', '<img src="/foo.jpg"/>');

    testHtml('enforces same-origin', validator,
        '<img src="http://example.com/foo.jpg"/>', '<img/>');
  });

  group('allowCustomElement', () {
    var validator = new NodeValidatorBuilder()
      ..allowCustomElement('x-foo', attributes: ['bar'], uriAttributes: ['baz'])
      ..allowHtml5();

    testHtml('allows custom elements', validator,
        '<x-foo bar="something" baz="/foo.jpg"></x-foo>');

    testHtml('validates custom tag URIs', validator,
        '<x-foo baz="http://example.com/foo.jpg"></x-foo>', '<x-foo></x-foo>');

    testHtml('blocks type extensions', validator, '<div is="x-foo"></div>', '');

    testHtml('blocks tags on non-matching elements', validator,
        '<div bar="foo"></div>', '<div></div>');
  });

  group('identify Uri attributes listed as attributes', () {
    var validator = new NodeValidatorBuilder()
      ..allowElement('a', attributes: ['href']);

    testHtml(
        'reject different-origin link',
        validator,
        '<a href="http://www.google.com/foo">Google-Foo</a>',
        '<a>Google-Foo</a>');
  });

  group('allowTagExtension', () {
    var validator = new NodeValidatorBuilder()
      ..allowTagExtension('x-foo', 'div',
          attributes: ['bar'], uriAttributes: ['baz'])
      ..allowHtml5();

    testHtml('allows tag extensions', validator,
        '<div is="x-foo" bar="something" baz="/foo.jpg"></div>');

    testHtml('blocks custom elements', validator, '<x-foo></x-foo>', '');

    testHtml(
        'validates tag extension URIs',
        validator,
        '<div is="x-foo" baz="http://example.com/foo.jpg"></div>',
        '<div is="x-foo"></div>');

    testHtml('blocks tags on non-matching elements', validator,
        '<div bar="foo"></div>', '<div></div>');

    testHtml('blocks non-matching tags', validator,
        '<span is="x-foo">something</span>', '');

    validator = new NodeValidatorBuilder()
      ..allowTagExtension('x-foo', 'div',
          attributes: ['bar'], uriAttributes: ['baz'])
      ..allowTagExtension('x-else', 'div');

    testHtml('blocks tags on non-matching custom elements', validator,
        '<div bar="foo" is="x-else"></div>', '<div is="x-else"></div>');
  });

  group('allowTemplating', () {
    var validator = new NodeValidatorBuilder()
      ..allowTemplating()
      ..allowHtml5();

    testHtml(
        'allows templates', validator, '<template bind="{{a}}"></template>');

    testHtml('allows template attributes', validator,
        '<template bind="{{a}}" ref="foo" repeat="{{}}" if="{{}}" syntax="foo"></template>');

    testHtml('allows template attribute', validator,
        '<div template repeat="{{}}"></div>');

    testHtml('blocks illegal template attribute', validator,
        '<div template="foo" repeat="{{}}"></div>', '<div></div>');
  });

  group('allowSvg', () {
    var validator = new NodeValidatorBuilder()
      ..allowSvg()
      ..allowTextElements();

    testHtml(
        'allows basic SVG',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg'
        'xmlns:xlink="http://www.w3.org/1999/xlink">'
        '<image xlink:href="foo" data-foo="bar"/>'
        '</svg>');

    testHtml(
        'blocks script elements',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg>'
        '<script></script>'
        '</svg>',
        '');

    testHtml(
        'blocks script elements but allows other',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg>'
        '<script></script><ellipse cx="200" cy="80" rx="100" ry="50"></ellipse>'
        '</svg>',
        '<svg xmlns="http://www.w3.org/2000/svg>'
        '<ellipse cx="200" cy="80" rx="100" ry="50"></ellipse>'
        '</svg>');

    testHtml(
        'blocks script handlers',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg'
        'xmlns:xlink="http://www.w3.org/1999/xlink">'
        '<image xlink:href="foo" onerror="something"/>'
        '</svg>',
        '<svg xmlns="http://www.w3.org/2000/svg'
        'xmlns:xlink="http://www.w3.org/1999/xlink">'
        '<image xlink:href="foo"/>'
        '</svg>');

    testHtml(
        'blocks foreignObject content',
        validator,
        '<svg xmlns="http://www.w3.org/2000/svg">'
        '<foreignobject width="100" height="150">'
        '<body xmlns="http://www.w3.org/1999/xhtml">'
        '<div>Some content</div>'
        '</body>'
        '</foreignobject>'
        '<b>42</b>'
        '</svg>',
        '<svg xmlns="http://www.w3.org/2000/svg">'
        '<b>42</b>'
        '</svg>');
  });

  group('allowInlineStyles', () {
    var validator = new NodeValidatorBuilder()
      ..allowTextElements()
      ..allowInlineStyles();

    testHtml('allows inline styles', validator,
        '<span style="background-color:red">text</span>');

    testHtml('blocks other attributes', validator,
        '<span class="red-span"></span>', '<span></span>');

    validator = new NodeValidatorBuilder()
      ..allowTextElements()
      ..allowInlineStyles(tagName: 'span');

    testHtml('scoped allows inline styles on spans', validator,
        '<span style="background-color:red">text</span>');

    testHtml('scoped blocks inline styles on LIs', validator,
        '<li style="background-color:red">text</li>', '<li>text</li>');
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
        document.body
            .createFragment('<div foo="bar"></div>', validator: validator);
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
      var svgText = '<svg xmlns="http://www.w3.org/2000/svg'
          'xmlns:xlink="http://www.w3.org/1999/xlink">'
          '<image xlink:href="foo" data-foo="bar"/>'
          '</svg>';

      var fragment = new DocumentFragment.svg(svgText);
      var element = fragment.nodes.first;
      expect(element is svg.SvgSvgElement, isTrue);
      expect(element.children[0] is svg.ImageElement, isTrue);
    });
  });

  group('dom_clobbering', () {
    var validator = new NodeValidatorBuilder.common();

    testHtml(
        'DOM clobbering of attributes with single node',
        validator,
        "<form id='single_node_clobbering' onmouseover='alert(1)'><input name='attributes'>",
        "");

    testHtml(
        'DOM clobbering of attributes with multiple nodes',
        validator,
        "<form onmouseover='alert(1)'><input name='attributes'>"
        "<input name='attributes'>",
        "");

    testHtml('DOM clobbering of lastChild', validator,
        "<form><input name='lastChild'><input onmouseover='alert(1)'>", "");

    testHtml(
        'DOM clobbering of both children and lastChild',
        validator,
        "<form><input name='lastChild'><input name='children'>"
        "<input id='children'><input onmouseover='alert(1)'>",
        "");

    testHtml(
        'DOM clobbering of both children and lastChild, different order',
        validator,
        "<form><input name='children'><input name='children'>"
        "<input id='children' name='lastChild'>"
        "<input id='bad' onmouseover='alert(1)'>",
        "");

    test('tagName makes containing form invalid', () {
      var fragment = document.body.createFragment(
          "<form onmouseover='alert(2)'><input name='tagName'>",
          validator: validator);
      var form = fragment.lastChild;
      // If the tagName was clobbered, the sanitizer should have removed
      // the whole thing and form is null.
      // If the tagName was not clobbered, then there will be content,
      // but the tagName should be the normal value. IE11 has started
      // doing this.
      if (form != null) {
        expect(form.tagName, 'FORM');
      }
    });

    test('tagName without mouseover', () {
      var fragment = document.body
          .createFragment("<form><input name='tagName'>", validator: validator);
      var form = fragment.lastChild;
      // If the tagName was clobbered, the sanitizer should have removed
      // the whole thing and form is null.
      // If the tagName was not clobbered, then there will be content,
      // but the tagName should be the normal value.
      if (form != null) {
        expect(form.tagName, 'FORM');
      }
    });
  });
}

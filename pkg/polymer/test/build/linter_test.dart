// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.linter_test;

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/linter.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  _testLinter('nothing to report', {
      'a|lib/test.html': '<!DOCTYPE html><html></html>',
    }, []);

  group('must have Dart code to invoke initPolymer, dart.js, not boot.js', () {
    _testLinter('nothing to report', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, []);

    _testLinter('missing Dart code and dart.js', {
        'a|web/test.html': '<!DOCTYPE html><html></html>',
      }, [
        'error: $USE_INIT_DART',
      ]);

    _testLinter('using deprecated boot.js', {
        'a|web/test.html': '<!DOCTYPE html><html>\n'
            '<script src="packages/polymer/boot.js"></script>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: $BOOT_JS_DEPRECATED (web/test.html 1 0)',
      ]);
  });
  group('single script tag per document', () {
    _testLinter('two top-level tags', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<script type="application/dart" src="a.dart">'
            '</script>\n'
            '<script type="application/dart" src="b.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
      }, [
        'warning: Only one "application/dart" script tag per document is'
        ' allowed. (web/test.html 1 0)',
      ]);

    _testLinter('two top-level tags, non entrypoint', {
        'a|lib/test.html': '<!DOCTYPE html><html>'
            '<script type="application/dart" src="a.dart">'
            '</script>\n'
            '<script type="application/dart" src="b.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
      }, [
        'warning: Only one "application/dart" script tag per document is'
        ' allowed. (lib/test.html 1 0)',
      ]);

    _testLinter('tags inside elements', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<polymer-element name="x-a">'
            '<script type="application/dart" src="a.dart">'
            '</script>'
            '</polymer-element>\n'
            '<script type="application/dart" src="b.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
      }, [
        'warning: Only one "application/dart" script tag per document is'
        ' allowed. (web/test.html 1 0)',
      ]);
  });

  group('doctype warning', () {
    _testLinter('in web', {
        'a|web/test.html': '<html></html>',
      }, [
        'warning: Unexpected start tag (html). Expected DOCTYPE. '
        '(web/test.html 0 0)',
        'error: $USE_INIT_DART',
      ]);

    _testLinter('in lib', {
        'a|lib/test.html': '<html></html>',
      }, []);
  });

  group('duplicate polymer-elements,', () {
    _testLinter('same file', {
        'a|lib/test.html': '''<html>
            <polymer-element name="x-a"></polymer-element>
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: duplicate definition for custom tag "x-a". '
        '(lib/test.html 1 0)',
        'warning: duplicate definition for custom tag "x-a"  '
        '(second definition). (lib/test.html 2 0)'
      ]);

    _testLinter('other file', {
        'a|lib/b.html': '''<html>
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
        'a|lib/test.html': '''<html>
            <link rel="import" href="b.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: duplicate definition for custom tag "x-a". '
        '(lib/b.html 1 0)',
        'warning: duplicate definition for custom tag "x-a"  '
        '(second definition). (lib/test.html 2 0)'
      ]);

    _testLinter('non existing file', {
        'a|lib/test.html': '''<html>
            <link rel="import" href="b.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'error: couldn\'t find imported asset "lib/b.html" in package '
        '"a". (lib/test.html 1 0)'
      ]);

    _testLinter('other package', {
        'b|lib/b.html': '''<html>
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
        'a|lib/test.html': '''<html>
            <link rel="import" href="../../packages/b/b.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: duplicate definition for custom tag "x-a". '
        '(package:b/b.html 1 0)',
        'warning: duplicate definition for custom tag "x-a"  '
        '(second definition). (lib/test.html 2 0)'
      ]);
  });

  _testLinter('bad link-rel tag (href missing)', {
      'a|lib/test.html': '''<html>
          <link rel="import">
          <link rel="stylesheet">
          <link rel="foo">
          <link rel="import" href="">
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: link rel="import" missing href. (lib/test.html 1 0)',
      'warning: link rel="stylesheet" missing href. (lib/test.html 2 0)',
      'warning: link rel="import" missing href. (lib/test.html 4 0)'
    ]);

  _testLinter('<element> is not supported', {
      'a|lib/test.html': '''<html>
          <element name="x-a"></element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: <element> elements are not supported, use <polymer-element>'
      ' instead (lib/test.html 1 0)'
    ]);

  _testLinter('do not nest <polymer-element>', {
      'a|lib/test.html': '''<html>
          <polymer-element name="x-a">
            <template><div>
              <polymer-element name="b"></polymer-element>
            </div></template>
          </polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: Nested polymer element definitions are not allowed.'
      ' (lib/test.html 3 4)'
    ]);

  _testLinter('need a name for <polymer-element>', {
      'a|lib/test.html': '''<html>
          <polymer-element></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: Missing tag name of the custom element. Please include an '
      'attribute like \'name="your-tag-name"\'. (lib/test.html 1 0)'
    ]);

  _testLinter('name for <polymer-element> should have dashes', {
      'a|lib/test.html': '''<html>
          <polymer-element name="a"></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: Invalid name "a". Custom element names must have at least one'
      ' dash and can\'t be any of the following names: annotation-xml, '
      'color-profile, font-face, font-face-src, font-face-uri, '
      'font-face-format, font-face-name, missing-glyph. (lib/test.html 1 0)'
    ]);

  _testLinter('extend is a valid element or existing tag', {
      'a|lib/test.html': '''<html>
          <polymer-element name="x-a" extends="li"></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, []);

  _testLinter('extend is a valid element or existing tag', {
      'a|lib/test.html': '''<html>
          <polymer-element name="x-a" extends="x-b"></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: custom element with name "x-b" not found. (lib/test.html 1 0)'
    ]);


  group('script type matches code', () {
    _testLinter('top-level, .dart url', {
        'a|lib/test.html': '''<html>
            <script src="foo.dart"></script>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: Wrong script type, expected type="application/dart".'
        ' (lib/test.html 1 0)'
      ]);

    _testLinter('in polymer-element, .dart url', {
        'a|lib/test.html': '''<html>
            <polymer-element name="x-a">
            <script src="foo.dart"></script>
            </polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: Wrong script type, expected type="application/dart".'
        ' (lib/test.html 2 0)'
      ]);

    _testLinter('in polymer-element, .js url', {
        'a|lib/test.html': '''<html>
            <polymer-element name="x-a">
            <script src="foo.js"></script>
            </polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, []);

    _testLinter('in polymer-element, inlined', {
        'a|lib/test.html': '''<html>
            <polymer-element name="x-a">
            <script>foo...</script>
            </polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: script tag in polymer element with no type will '
        'be treated as JavaScript. Did you forget type="application/dart"?'
        ' (lib/test.html 2 0)'
      ]);

    _testLinter('top-level, dart type & .dart url', {
        'a|lib/test.html': '''<html>
            <script type="application/dart" src="foo.dart"></script>
            </html>'''.replaceAll('            ', ''),
      }, []);

    _testLinter('top-level, dart type & .js url', {
        'a|lib/test.html': '''<html>
            <script type="application/dart" src="foo.js"></script>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: "application/dart" scripts should use the .dart file '
        'extension. (lib/test.html 1 0)'
      ]);
  });

  _testLinter('script tags should have only src url or inline code', {
      'a|lib/test.html': '''<html>
          <script type="application/dart" src="foo.dart">more</script>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: script tag has "src" attribute and also has script text. '
      '(lib/test.html 1 0)'
    ]);

  group('event handlers', () {
    _testLinter('onfoo is not polymer', {
        'a|lib/test.html': '''<html><body>
            <div onfoo="something"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: Event handler "onfoo" will be interpreted as an inline '
        'JavaScript event handler. Use the form '
        'on-event-name="handlerName" if you want a Dart handler '
        'that will automatically update the UI based on model changes. '
        '(lib/test.html 1 5)'
      ]);

    _testLinter('on-foo is only supported in polymer elements', {
        'a|lib/test.html': '''<html><body>
            <div on-foo="something"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: Inline event handlers are only supported inside '
        'declarations of <polymer-element>. '
        '(lib/test.html 1 5)'
      ]);

    _testLinter('on-foo is not an expression', {
        'a|lib/test.html': '''<html><body>
            <polymer-element name="x-a"><div on-foo="bar()"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: Invalid event handler body "bar()". Declare a method '
        'in your custom element "void handlerName(event, detail, target)" '
        'and use the form on-foo="handlerName". '
        '(lib/test.html 1 33)'
      ]);

    _testLinter('on-foo-bar is supported as a custom event name', {
        'a|lib/test.html': '''<html><body>
            <polymer-element name="x-a"><div on-foo-bar="quux"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, []);
  });

  group('using custom tags', () {
    _testLinter('tag exists (x-tag)', {
        'a|lib/test.html': '<x-foo></x-foo>',
      }, [
        'warning: definition for Polymer element with tag name "x-foo" not '
        'found. (lib/test.html 0 0)'
      ]);

    _testLinter('tag exists (type extension)', {
        'a|lib/test.html': '<div is="x-foo"></div>',
      }, [
        'warning: definition for Polymer element with tag name "x-foo" not '
        'found. (lib/test.html 0 0)'
      ]);

    _testLinter('used correctly (no base tag)', {
        'a|lib/test.html': '''
            <polymer-element name="x-a"></polymer-element>
            <x-a></x-a>
            '''.replaceAll('            ', ''),
      }, []);

    _testLinter('used incorrectly (no base tag)', {
        'a|lib/test.html': '''
            <polymer-element name="x-a"></polymer-element>
            <div is="x-a"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: custom element "x-a" doesn\'t declare any type '
        'extensions. To fix this, either rewrite this tag as '
        '<x-a> or add \'extends="div"\' to '
        'the custom element declaration. (lib/test.html 1 0)'
      ]);

    _testLinter('used incorrectly, imported def (no base tag)', {
        'a|lib/b.html': '<polymer-element name="x-a"></polymer-element>',
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <div is="x-a"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: custom element "x-a" doesn\'t declare any type '
        'extensions. To fix this, either rewrite this tag as '
        '<x-a> or add \'extends="div"\' to '
        'the custom element declaration. (lib/test.html 1 0)'
      ]);

    _testLinter('used correctly (base tag)', {
        'a|lib/b.html': '''
            <polymer-element name="x-a" extends="div">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <div is="x-a"></div>
            '''.replaceAll('            ', ''),
      }, []);

    _testLinter('used incorrectly (missing base tag)', {
        'a|lib/b.html': '''
            <polymer-element name="x-a" extends="div">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <x-a></x-a>
            '''.replaceAll('            ', ''),
      }, [
        'warning: custom element "x-a" extends from "div", but this tag '
        'will not include the default properties of "div". To fix this, '
        'either write this tag as <div is="x-a"> or remove the "extends" '
        'attribute from the custom element declaration. (lib/test.html 1 0)'
      ]);

    _testLinter('used incorrectly (wrong base tag)', {
        'a|lib/b.html': '''
            <polymer-element name="x-a" extends="div">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <span is="x-a"></span>
            '''.replaceAll('            ', ''),
      }, [
        'warning: custom element "x-a" extends from "div". Did you mean '
        'to write <div is="x-a">? (lib/test.html 1 0)'
      ]);

    _testLinter('used incorrectly (wrong base tag, transitive)', {
        'a|lib/c.html': '''
            <polymer-element name="x-c" extends="li">
            </polymer-element>
            <polymer-element name="x-b" extends="x-c">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/b.html': '''
            <link rel="import" href="c.html">
            <polymer-element name="x-a" extends="x-b">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <span is="x-a"></span>
            '''.replaceAll('            ', ''),
      }, [
        'warning: custom element "x-a" extends from "li". Did you mean '
        'to write <li is="x-a">? (lib/test.html 1 0)'
      ]);
  });

  group('custom attributes', () {
    _testLinter('foo-bar is no longer supported in attributes', {
        'a|lib/test.html': '''<html><body>
            <polymer-element name="x-a" attributes="foo-bar">
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: PolymerElement no longer recognizes attribute names with '
        'dashes such as "foo-bar". Use "fooBar" or "foobar" instead (both '
        'forms are equivalent in HTML). (lib/test.html 1 28)'
      ]);
  });

  _testLinter("namespaced attributes don't cause an internal error", {
      'a|lib/test.html': '''<html><body>
          <svg xmlns="http://www.w3.org/2000/svg" width="520" height="350">
          </svg>
          '''.replaceAll('            ', ''),
    }, []);
}

_testLinter(String name, Map inputFiles, List outputMessages) {
  var linter = new Linter(new TransformOptions());
  var outputFiles = {};
  inputFiles.forEach((k, v) => outputFiles[k] = v);
  testPhases(name, [[linter]], inputFiles, outputFiles, outputMessages);
}

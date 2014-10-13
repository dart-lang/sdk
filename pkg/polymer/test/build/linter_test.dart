// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.linter_test;

import 'dart:convert';

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/linter.dart';
import 'package:polymer/src/build/messages.dart';
import 'package:unittest/unittest.dart';

import 'common.dart';

void main() {
  _testLinter('nothing to report', {
      'a|lib/test.html': '<!DOCTYPE html><html></html>',
    }, []);

  group('must have proper initialization imports', () {
    _testLinter('nothing to report (no polymer use)', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, []);

    _testLinter('nothing to report (no polymer use with import)', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="packages/polymer/polymer.html">'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, []);

    _testLinter('nothing to report (polymer used)', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="packages/polymer/polymer.html">'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, []);

    _testLinter('nothing to report (polymer imported transitively)', {
        'a|lib/lib.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="../../packages/polymer/polymer.html">',
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="packages/a/lib.html">'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, []);

    test('usePolymerHtmlMessage looks right', () {
      _check(int i, String url) {
        expect(_usePolymerHtmlMessage(i),
            contains('<link rel="import" href="$url">'));
      }
      _check(0, 'packages/polymer/polymer.html');
      _check(1, '../packages/polymer/polymer.html');
      _check(2, '../../packages/polymer/polymer.html');
      _check(3, '../../../packages/polymer/polymer.html');
    });

    _testLinter('missing polymer.html in web', {
        'a|web/test.html': '<!DOCTYPE html><html>\n'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${_usePolymerHtmlMessage(0)} '
        '(web/test.html 1 0)',
      ]);

    _testLinter('missing polymer.html in web/foo', {
        'a|web/foo/test.html': '<!DOCTYPE html><html>\n'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${_usePolymerHtmlMessage(1)} '
        '(web/foo/test.html 1 0)',
      ]);

    _testLinter('missing polymer.html in lib', {
        'a|lib/test.html': '<!DOCTYPE html><html>\n'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${_usePolymerHtmlMessage(2)} '
        '(lib/test.html 1 0)',
      ]);

    _testLinter('missing polymer.html in lib/foo/bar', {
        'a|lib/foo/bar/test.html': '<!DOCTYPE html><html>\n'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${_usePolymerHtmlMessage(4)} '
        '(lib/foo/bar/test.html 1 0)',
      ]);

    _testLinter('missing Dart code', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="packages/polymer/polymer.html">'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${MISSING_INIT_POLYMER.snippet}',
      ]);

    _testLinter('nothing to report, experimental with no Dart code', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" '
            'href="packages/polymer/polymer_experimental.html">'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, []);

    _testLinter('experimental cannot have Dart code in main document', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" '
            'href="packages/polymer/polymer_experimental.html">\n'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${NO_DART_SCRIPT_AND_EXPERIMENTAL.snippet} '
        '(web/test.html 1 0)',
      ]);

    _testLinter('missing Dart code and polymer.html', {
        'a|web/test.html': '<!DOCTYPE html><html></html>',
      }, [
        'warning: ${MISSING_INIT_POLYMER.snippet}',
      ]);

    _testLinter('dart_support unnecessary', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<script src="packages/web_components/dart_support.js"></script>'
            '<link rel="import" href="../../packages/polymer/polymer.html">'
            '<polymer-element name="x-a"></polymer-element>'
            '<script type="application/dart" src="foo.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
            '</html>',
      }, [
        'warning: ${DART_SUPPORT_NO_LONGER_REQUIRED.snippet} '
        '(web/test.html 0 21)'
      ]);

  });

  group('single script tag per document', () {
    _testLinter('two top-level tags', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="packages/polymer/polymer.html">'
            '<script type="application/dart" src="a.dart">'
            '</script>\n'
            '<script type="application/dart" src="b.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>',
      }, [
        'warning: ${ONLY_ONE_TAG.snippet} (web/test.html 1 0)',
      ]);

    _testLinter('two top-level tags, non entrypoint', {
        'a|lib/test.html': '<!DOCTYPE html><html>'
            '<script type="application/dart" src="a.dart">'
            '</script>\n'
            '<script type="application/dart" src="b.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>'
      }, [
        'warning: ${ONLY_ONE_TAG.snippet} (lib/test.html 1 0)',
      ]);

    _testLinter('tags inside elements', {
        'a|web/test.html': '<!DOCTYPE html><html>'
            '<link rel="import" href="packages/polymer/polymer.html">'
            '<polymer-element name="x-a">'
            '<script type="application/dart" src="a.dart">'
            '</script>'
            '</polymer-element>\n'
            '<script type="application/dart" src="b.dart">'
            '</script>'
            '<script src="packages/browser/dart.js"></script>',
      }, [
        'warning: ${ONLY_ONE_TAG.snippet} (web/test.html 1 0)',
      ]);
  });

  group('doctype warning', () {
    _testLinter('in web', {
        'a|web/test.html': '<html></html>',
      }, [
        'warning: (from html5lib) Unexpected start tag (html). '
            'Expected DOCTYPE. (web/test.html 0 0)',
        'warning: ${MISSING_INIT_POLYMER.snippet}',
      ]);

    _testLinter('in lib', {
        'a|lib/test.html': '<html></html>',
      }, []);
  });

  group('duplicate polymer-elements,', () {
    _testLinter('same file', {
        'a|lib/test.html': '''<html>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"></polymer-element>
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: ${DUPLICATE_DEFINITION.create(
            {'name': 'x-a', 'second': ''}).snippet} (lib/test.html 2 0)',
        'warning: ${DUPLICATE_DEFINITION.create(
            {'name': 'x-a', 'second': ' (second definition).'}).snippet} '
            '(lib/test.html 3 0)',
      ]);

    _testLinter('other file', {
        'a|lib/b.html': '''<html>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
        'a|lib/test.html': '''<html>
            <link rel="import" href="b.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: ${DUPLICATE_DEFINITION.create(
            {'name': 'x-a', 'second': ''}).snippet} (lib/b.html 2 0)',
        'warning: ${DUPLICATE_DEFINITION.create(
            {'name': 'x-a', 'second': ' (second definition).'}).snippet} '
            '(lib/test.html 2 0)',
      ]);

    _testLinter('non existing file', {
        'a|lib/test.html': '''<html>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <link rel="import" href="b.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: ${IMPORT_NOT_FOUND.create(
            {'path': 'lib/b.html', 'package': 'a'}).snippet} '
            '(lib/test.html 2 0)'
      ]);

    _testLinter('other package', {
        'b|lib/b.html': '''<html>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
        'a|lib/test.html': '''<html>
            <link rel="import" href="../../packages/b/b.html">
            <polymer-element name="x-a"></polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: ${DUPLICATE_DEFINITION.create(
            {'name': 'x-a', 'second': ''}).snippet} (package:b/b.html 2 0)',
        'warning: ${DUPLICATE_DEFINITION.create(
            {'name': 'x-a', 'second': ' (second definition).'}).snippet} '
            '(lib/test.html 2 0)',
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
      'warning: ${MISSING_HREF.create({'rel': 'import'}).snippet} '
          '(lib/test.html 1 0)',
      'warning: ${MISSING_HREF.create({'rel': 'stylesheet'}).snippet} '
          '(lib/test.html 2 0)',
      'warning: ${MISSING_HREF.create({'rel': 'import'}).snippet} '
          '(lib/test.html 4 0)',
    ]);

  _testLinter('<element> is not supported', {
      'a|lib/test.html': '''<html>
          <element name="x-a"></element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: ${ELEMENT_DEPRECATED_EONS_AGO.snippet} (lib/test.html 1 0)'
    ]);

  _testLinter('do not nest <polymer-element>', {
      'a|lib/test.html': '''<html>
          <link rel="import" href="../../packages/polymer/polymer.html">
          <polymer-element name="x-a">
            <template><div>
              <polymer-element name="b"></polymer-element>
            </div></template>
          </polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: ${NESTED_POLYMER_ELEMENT.snippet} (lib/test.html 4 4)'
    ]);

  _testLinter('do put import inside <polymer-element>', {
      'a|lib/b.html': '<html></html>',
      'a|lib/test.html': '''<html>
          <link rel="import" href="../../packages/polymer/polymer.html">
          <polymer-element name="x-a">
            <link rel="import" href="b.html">
            <template><div>
            </div></template>
          </polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: ${NO_IMPORT_WITHIN_ELEMENT.snippet} (lib/test.html 3 2)'
    ]);

  _testLinter('need a name for <polymer-element>', {
      'a|lib/test.html': '''<html>
          <link rel="import" href="../../packages/polymer/polymer.html">
          <polymer-element></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: ${MISSING_TAG_NAME.snippet} (lib/test.html 2 0)'
    ]);

  _testLinter('name for <polymer-element> should have dashes', {
      'a|lib/test.html': '''<html>
          <link rel="import" href="../../packages/polymer/polymer.html">
          <polymer-element name="a"></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'error: ${INVALID_TAG_NAME.create({'name': 'a'}).snippet} '
          '(lib/test.html 2 0)'
    ]);

  _testLinter('extend is a valid element or existing tag', {
      'a|lib/test.html': '''<html>
          <link rel="import" href="../../packages/polymer/polymer.html">
          <polymer-element name="x-a" extends="li"></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, []);

  _testLinter('extend is a valid element or existing tag', {
      'a|lib/test.html': '''<html>
          <link rel="import" href="../../packages/polymer/polymer.html">
          <polymer-element name="x-a" extends="x-b"></polymer-element>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: ${CUSTOM_ELEMENT_NOT_FOUND.create({'tag': 'x-b'}).snippet} '
          '(lib/test.html 2 0)'
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
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a">
            <script src="foo.dart"></script>
            </polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, [
        'warning: ${EXPECTED_DART_MIME_TYPE.snippet} (lib/test.html 3 0)'
      ]);

    _testLinter('in polymer-element, .js url', {
        'a|lib/test.html': '''<html>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a">
            <script src="foo.js"></script>
            </polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, []);

    _testLinter('in polymer-element, inlined', {
        'a|lib/test.html': '''<html>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a">
            <script>foo...</script>
            </polymer-element>
            </html>'''.replaceAll('            ', ''),
      }, []);

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
        'warning: ${EXPECTED_DART_EXTENSION.snippet} (lib/test.html 1 0)'
      ]);
  });

  _testLinter('script tags should have at least src url or inline code', {
      'a|lib/test.html': '''<html>
          <script type="application/dart"></script>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: ${SCRIPT_TAG_SEEMS_EMPTY.snippet} (lib/test.html 1 0)'
    ]);

  _testLinter('script tags should have only src url or inline code', {
      'a|lib/test.html': '''<html>
          <script type="application/dart" src="foo.dart">more</script>
          </html>'''.replaceAll('          ', ''),
    }, [
      'warning: ${FOUND_BOTH_SCRIPT_SRC_AND_TEXT.snippet} (lib/test.html 1 0)'
    ]);

  group('event handlers', () {
    _testLinter('no longer warn about inline onfoo (Javascript)', {
        'a|lib/test.html': '''<html><body>
            <div onfoo="something"></div>
            '''.replaceAll('            ', ''),
      }, []);

    _testLinter('no longer warn about on-foo for auto-binding templates', {
        'a|lib/test.html': '''<html><body>
            <template is="auto-binding-dart">
              <div on-foo="{{something}}"></div>
            </template>
            '''.replaceAll('            ', ''),
      }, []);

    _testLinter('on-foo is only supported in polymer elements', {
        'a|lib/test.html': '''<html><body>
            <div on-foo="something"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${EVENT_HANDLERS_ONLY_WITHIN_POLYMER.snippet} '
            '(lib/test.html 1 5)'
      ]);

    _testLinter('on-foo uses the {{ binding }} syntax', {
        'a|lib/test.html': '''<html><body>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"><div on-foo="bar"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${INVALID_EVENT_HANDLER_BODY.create(
            {'value': 'bar', 'name': 'on-foo'}).snippet} (lib/test.html 2 33)'
      ]);

    _testLinter('on-foo is not an expression', {
        'a|lib/test.html': '''<html><body>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"><div on-foo="{{bar()}}"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${INVALID_EVENT_HANDLER_BODY.create(
            {'value': '{{bar()}}', 'name': 'on-foo'}).snippet} '
            '(lib/test.html 2 33)'
      ]);

    _testLinter('on-foo can\'t be empty', {
        'a|lib/test.html': '''<html><body>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"><div on-foo="{{}}"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${INVALID_EVENT_HANDLER_BODY.create(
            {'value': '{{}}', 'name': 'on-foo'}).snippet} (lib/test.html 2 33)'
      ]);

    _testLinter('on-foo can\'t be just space', {
        'a|lib/test.html': '''<html><body>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"><div on-foo="{{ }}"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${INVALID_EVENT_HANDLER_BODY.create(
            {'value': '{{ }}', 'name': 'on-foo'}).snippet} (lib/test.html 2 33)'
      ]);

    _testLinter('on-foo-bar is supported as a custom event name', {
        'a|lib/test.html': '''<html><body>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"><div on-foo-bar="{{quux}}"></div>
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, []);
  });

  group('using custom tags', () {
    _testLinter('tag exists (x-tag)', {
        'a|lib/test.html': '<x-foo></x-foo>',
      }, [
        'warning: ${CUSTOM_ELEMENT_NOT_FOUND.create({'tag': 'x-foo'}).snippet} '
            '(lib/test.html 0 0)'
      ]);

    _testLinter('tag exists (type extension)', {
        'a|lib/test.html': '<div is="x-foo"></div>',
      }, [
        'warning: ${CUSTOM_ELEMENT_NOT_FOUND.create({'tag': 'x-foo'}).snippet} '
            '(lib/test.html 0 0)'
      ]);
    
    _testLinter('tag exists (internally defined in code)', {
      'a|lib/test.html': '<div is="auto-binding-dart"></div>',
      }, []);

    _testLinter('used correctly (no base tag)', {
        'a|lib/test.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"></polymer-element>
            <x-a></x-a>
            '''.replaceAll('            ', ''),
      }, []);

    _testLinter('used incorrectly (no base tag)', {
        'a|lib/test.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"></polymer-element>
            <div is="x-a"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${BAD_INSTANTIATION_BOGUS_BASE_TAG.create(
            {'tag': 'x-a', 'base': 'div'}).snippet} (lib/test.html 2 0)'
      ]);

    _testLinter('used incorrectly, imported def (no base tag)', {
        'a|lib/b.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a"></polymer-element>''',
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <div is="x-a"></div>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${BAD_INSTANTIATION_BOGUS_BASE_TAG.create(
            {'tag': 'x-a', 'base': 'div'}).snippet} (lib/test.html 1 0)'
      ]);

    _testLinter('used correctly (base tag)', {
        'a|lib/b.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
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
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a" extends="div">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <x-a></x-a>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${BAD_INSTANTIATION_MISSING_BASE_TAG.create(
            {'tag': 'x-a', 'base': 'div'}).snippet} (lib/test.html 1 0)'
      ]);

    _testLinter('used incorrectly (wrong base tag)', {
        'a|lib/b.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a" extends="div">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="b.html">
            <span is="x-a"></span>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${BAD_INSTANTIATION_WRONG_BASE_TAG.create(
            {'tag': 'x-a', 'base': 'div'}).snippet} (lib/test.html 1 0)'
      ]);

    _testLinter('used incorrectly (wrong base tag, transitive)', {
        'a|lib/c.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-c" extends="li">
            </polymer-element>
            <polymer-element name="x-b" extends="x-c">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/b.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <link rel="import" href="c.html">
            <polymer-element name="x-a" extends="x-b">
            </polymer-element>
            '''.replaceAll('            ', ''),
        'a|lib/test.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <link rel="import" href="b.html">
            <span is="x-a"></span>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${BAD_INSTANTIATION_WRONG_BASE_TAG.create(
            {'tag': 'x-a', 'base': 'li'}).snippet} (lib/test.html 2 0)'
      ]);

    _testLinter('FOUC warning works', {
        'a|web/a.html': '''
            <!DOCTYPE html>
            <html><body>
              <link rel="import" href="../../packages/polymer/polymer.html">
              <polymer-element name="my-element" noscript></polymer-element>
              <my-element>hello!</my-element>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            ''',
        'a|web/b.html': '''
            <!DOCTYPE html>
            <html><body>
              <link rel="import" href="../../packages/polymer/polymer.html">
              <polymer-element name="my-element" noscript></polymer-element>
              <div><my-element>hello!</my-element></div>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            ''',
        'a|web/c.html': '''
            <!DOCTYPE html>
            <html unresolved><body>
              <link rel="import" href="../../packages/polymer/polymer.html">
              <polymer-element name="my-element" noscript></polymer-element>
              <my-element>hello!</my-element>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            '''
      }, [
        'warning: ${POSSIBLE_FUOC.snippet} (web/a.html 4 14)',
        'warning: ${POSSIBLE_FUOC.snippet} (web/b.html 4 19)',
        'warning: ${POSSIBLE_FUOC.snippet} (web/c.html 4 14)',
      ]);

    _testLinter('FOUC, no false positives.', {
        // Parent has unresolved attribute.
        'a|web/a.html': '''
            <!DOCTYPE html>
            <html><body>
              <div unresolved>
                <link rel="import" href="../../packages/polymer/polymer.html">
                <polymer-element name="my-element" noscript></polymer-element>
                <my-element>hello!</my-element>
              </div>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            ''',
        // Body has unresolved attribute.
        'a|web/b.html': '''
            <!DOCTYPE html>
            <html><body unresolved>
              <link rel="import" href="../../packages/polymer/polymer.html">
              <polymer-element name="my-element" noscript></polymer-element>
              <my-element>hello!</my-element>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            ''',
        // Inside polymer-element tags its fine.
        'a|web/c.html': '''
            <!DOCTYPE html>
            <html><body>
              <link rel="import" href="../../packages/polymer/polymer.html">
              <polymer-element name="my-element" noscript></polymer-element>
              <polymer-element name="foo-element">
                <template><my-element>hello!</my-element></template>
              </polymer-element>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            ''',
        // Empty custom elements are fine.
        'a|web/d.html': '''
            <!DOCTYPE html>
            <html><body>
              <link rel="import" href="../../packages/polymer/polymer.html">
              <polymer-element name="my-element" noscript></polymer-element>
              <my-element></my-element>
              <script type="application/dart">
                export "package:polymer/init.dart";
              </script>
            </body></html>
            ''',
        // Entry points only!
        'a|lib/a.html': '''
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="my-element" noscript></polymer-element>
            <my-element>hello!</my-element>
            ''',
      }, []);
  });

  group('custom attributes', () {
    _testLinter('foo-bar is no longer supported in attributes', {
        'a|lib/test.html': '''<html><body>
            <link rel="import" href="../../packages/polymer/polymer.html">
            <polymer-element name="x-a" attributes="foo-bar">
            </polymer-element>
            '''.replaceAll('            ', ''),
      }, [
        'warning: ${NO_DASHES_IN_CUSTOM_ATTRIBUTES.create(
            {'name': 'foo-bar', 'alternative': '"fooBar" or "foobar"'})
                .snippet} (lib/test.html 2 28)'
      ]);
  });

  _testLinter("namespaced attributes don't cause an internal error", {
      'a|lib/test.html': '''<html><body>
          <svg xmlns="http://www.w3.org/2000/svg" width="520" height="350">
          </svg>
          '''.replaceAll('            ', ''),
    }, []);

  group('output logs to file',  () {
    final outputLogsPhases = [[new Linter(
        new TransformOptions(injectBuildLogsInOutput: true,
            releaseMode: false))]];

    testPhases("logs are output to file", outputLogsPhases, {
        'a|web/test.html': '<!DOCTYPE html><html>\n'
          '<polymer-element name="x-a"></polymer-element>'
          '<script type="application/dart" src="foo.dart">'
          '</script>'
          '<script src="packages/browser/dart.js"></script>'
          '</html>',
      }, {
        'a|web/test.html._buildLogs.1':
          '{"polymer#3":[{'
            '"level":"Warning",'
            '"message":{'
               '"id":"polymer#3",'
               '"snippet":"${_usePolymerHtmlMessage(0).replaceAll('"','\\"')}"'
            '},'
            '"span":{'
              '"start":{'
                '"url":"web/test.html",'
                '"offset":22,'
                '"line":1,'
                '"column":0'
              '},'
              '"end":{'
                '"url":"web/test.html",'
                '"offset":50,'
                '"line":1,'
                '"column":28'
              '},'
              '"text":"<polymer-element name=\\"x-a\\">"'
            '}'
          '}]}',
    }, [
        // Logs should still make it to barback too.
        'warning: ${_usePolymerHtmlMessage(0)} (web/test.html 1 0)',
    ]);
  });
}

_usePolymerHtmlMessage(int i) {
  var prefix = '../' * i;
  return USE_POLYMER_HTML.create({'reachOutPrefix': prefix}).snippet;
}

_testLinter(String name, Map inputFiles, List outputMessages,
    [bool solo = false]) {
  var outputFiles = {};
  if (outputMessages.every((m) => m.startsWith('warning:'))) {
    inputFiles.forEach((k, v) => outputFiles[k] = v);
  }
  if (outputMessages.isEmpty) {
    var linter = new Linter(new TransformOptions());
    testPhases(name, [[linter]], inputFiles, outputFiles, outputMessages, solo);
  } else {
    testLogOutput(
        (options) => new Linter(options), name, inputFiles, outputFiles,
        outputMessages, solo);
  }
}

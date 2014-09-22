// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.import_inliner_test;

import 'dart:convert';
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/import_inliner.dart';
import 'package:polymer/src/build/messages.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'common.dart';

part 'code_extractor.dart';

final phases = [[new ImportInliner(new TransformOptions())]];

void main() {
  useCompactVMConfiguration();
  group('rel=import', importTests);
  group('rel=stylesheet', stylesheetTests);
  group('script type=dart', codeExtractorTests);
  group('url attributes', urlAttributeTests);
  group('deep entrypoints', entryPointTests);
}

void importTests() {
  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html._data': EMPTY_DATA,
    });

  testPhases('empty import', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="">' // empty href
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import">'         // no href
          '</head></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body></body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body></body></html>',
      'a|web/test2.html._data': EMPTY_DATA,
    });

  testPhases('shallow, no elements', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body></body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head></html>',
      'a|web/test2.html._data': EMPTY_DATA,
    });

  testPhases('shallow, elements, one import', phases,
    {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>2</polymer-element></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/test2.html._data': EMPTY_DATA,
    });

  testPhases('preserves order of scripts', phases,
    {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '<link rel="import" href="test2.html">'
          '<script>/*forth*/</script>'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head><script>/*third*/</script>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/second.js': '/*second*/'
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '</head><body>'
          '<div hidden="">'
          '<script>/*third*/</script>'
          '<polymer-element>2</polymer-element>'
          '<script>/*forth*/</script>'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.html':
          '<!DOCTYPE html><html><head><script>/*third*/</script>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/test2.html._data': EMPTY_DATA,
      'a|web/second.js': '/*second*/'
    });

  testPhases('preserves order of scripts, extract Dart scripts', phases,
    {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '<link rel="import" href="test2.html">'
          '<script type="application/dart">/*fifth*/</script>'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head><script>/*third*/</script>'
          '<script type="application/dart">/*forth*/</script>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/second.js': '/*second*/'
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '</head><body>'
          '<div hidden="">'
          '<script>/*third*/</script>'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': expectedData([
          'web/test.html.1.dart','web/test.html.0.dart']),
      'a|web/test.html.1.dart': 'library a.web.test2_html_0;\n/*forth*/',
      'a|web/test.html.0.dart': 'library a.web.test_html_0;\n/*fifth*/',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<script>/*third*/</script>'
          '</head><body>'
          '<polymer-element>2</polymer-element>'
          '</body></html>',
      'a|web/test2.html._data': expectedData(['web/test2.html.0.dart']),
      'a|web/test2.html.0.dart': 'library a.web.test2_html_0;\n/*forth*/',
      'a|web/second.js': '/*second*/'
    });

  final cspPhases = [[new ImportInliner(
      new TransformOptions(contentSecurityPolicy: true))]];
  testPhases('extract Js scripts in CSP mode', cspPhases,
    {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '<link rel="import" href="test2.html">'
          '<script type="application/dart">/*fifth*/</script>'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head><script>/*third*/</script>'
          '<script type="application/dart">/*forth*/</script>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/second.js': '/*second*/'
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="text/javascript" src="test.html.0.js"></script>'
          '<script src="second.js"></script>'
          '</head><body>'
          '<div hidden="">'
          '<script src="test.html.2.js"></script>'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': expectedData([
          'web/test.html.3.dart','web/test.html.1.dart']),
      'a|web/test.html.3.dart': 'library a.web.test2_html_0;\n/*forth*/',
      'a|web/test.html.1.dart': 'library a.web.test_html_0;\n/*fifth*/',
      'a|web/test.html.0.js': '/*first*/',
      'a|web/test.html.2.js': '/*third*/',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<script src="test2.html.0.js"></script>'
          '</head><body>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test2.html._data': expectedData(['web/test2.html.1.dart']),
      'a|web/test2.html.0.js': '/*third*/',
      'a|web/test2.html.1.dart': 'library a.web.test2_html_0;\n/*forth*/',
      'a|web/second.js': '/*second*/'
    });

  testPhases('Cleans library names generated from file paths.', phases,
      {
        'a|web/01_test.html':
            '<!DOCTYPE html><html><head>'
            '<script type="application/dart">/*1*/</script>'
            '</head></html>',
        'a|web/foo_02_test.html':
            '<!DOCTYPE html><html><head>'
            '<script type="application/dart">/*2*/</script>'
            '</head></html>',
        'a|web/test_03.html':
            '<!DOCTYPE html><html><head>'
            '<script type="application/dart">/*3*/</script>'
            '</head></html>',
        'a|web/*test_%foo_04!.html':
            '<!DOCTYPE html><html><head>'
            '<script type="application/dart">/*4*/</script>'
            '</head></html>',
        'a|web/%05_test.html':
            '<!DOCTYPE html><html><head>'
            '<script type="application/dart">/*5*/</script>'
            '</head></html>',
      }, {
        'a|web/01_test.html.0.dart':
            'library a.web._01_test_html_0;\n/*1*/',        // Appends an _ if it starts with a number.
        'a|web/foo_02_test.html.0.dart':
            'library a.web.foo_02_test_html_0;\n/*2*/',     // Allows numbers in the middle.
        'a|web/test_03.html.0.dart':
            'library a.web.test_03_html_0;\n/*3*/',         // Allows numbers at the end.
        'a|web/*test_%foo_04!.html.0.dart':
            'library a.web._test__foo_04__html_0;\n/*4*/',  // Replaces invalid characters with _.
        'a|web/%05_test.html.0.dart':
            'library a.web._05_test_html_0;\n/*5*/',        // Replace invalid character followed by number.
      });

  testPhases('no transformation outside web/', phases,
    {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head></html>',
      'a|lib/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>2</polymer-element></html>',
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head></html>',
      'a|lib/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>2</polymer-element></html>',
    });

  testPhases('shallow, elements, many', phases,
    {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '<link rel="import" href="test3.html">'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/test3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>3</polymer-element></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/test3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>3</polymer-element></html>',
    });

  testPhases('deep, elements, one per file', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="assets/b/test3.html">'
          '</head><body><polymer-element>2</polymer-element></html>',
      'b|asset/test3.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="../../packages/c/test4.html">'
          '</head><body><polymer-element>3</polymer-element></html>',
      'c|lib/test4.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>4</polymer-element></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>4</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>4</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '</div>'
          '<polymer-element>2</polymer-element>'
          '</body></html>',
      'b|asset/test3.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="../../packages/c/test4.html">'
          '</head><body><polymer-element>3</polymer-element></html>',
      'c|lib/test4.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>4</polymer-element></html>',
    });

  testPhases('deep, elements, many imports', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2a.html">'
          '<link rel="import" href="test2b.html">'
          '</head></html>',
      'a|web/test2a.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test3a.html">'
          '<link rel="import" href="test3b.html">'
          '</head><body><polymer-element>2a</polymer-element></body></html>',
      'a|web/test2b.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test4a.html">'
          '<link rel="import" href="test4b.html">'
          '</head><body><polymer-element>2b</polymer-element></body></html>',
      'a|web/test3a.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>3a</polymer-element></body></html>',
      'a|web/test3b.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>3b</polymer-element></body></html>',
      'a|web/test4a.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>4a</polymer-element></body></html>',
      'a|web/test4b.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>4b</polymer-element></body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3a</polymer-element>'
          '<polymer-element>3b</polymer-element>'
          '<polymer-element>2a</polymer-element>'
          '<polymer-element>4a</polymer-element>'
          '<polymer-element>4b</polymer-element>'
          '<polymer-element>2b</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test2a.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3a</polymer-element>'
          '<polymer-element>3b</polymer-element>'
          '</div>'
          '<polymer-element>2a</polymer-element>'
          '</body></html>',
      'a|web/test2b.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>4a</polymer-element>'
          '<polymer-element>4b</polymer-element>'
          '</div>'
          '<polymer-element>2b</polymer-element>'
          '</body></html>',
      'a|web/test3a.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3a</polymer-element>'
          '</body></html>',
      'a|web/test3b.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3b</polymer-element>'
          '</body></html>',
      'a|web/test4a.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>4a</polymer-element>'
          '</body></html>',
      'a|web/test4b.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>4b</polymer-element>'
          '</body></html>',
    });

  testPhases('imports cycle, 1-step lasso', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_2.html">'
          '</head><body><polymer-element>1</polymer-element></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head><body><polymer-element>2</polymer-element></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '<polymer-element>2</polymer-element></body></html>',
    });

  testPhases('imports cycle, 1-step lasso, scripts too', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_2.html">'
          '</head><body><polymer-element>1</polymer-element>'
          '<script src="s1"></script></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head><body><polymer-element>2</polymer-element>'
          '<script src="s2"></script></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '<script src="s2"></script>'
          '<polymer-element>1</polymer-element>'
          '<script src="s1"></script>'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '<script src="s2"></script>'
          '</div>'
          '<polymer-element>1</polymer-element>'
          '<script src="s1"></script></body></html>',
      'a|web/test_1.html._data': EMPTY_DATA,
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>1</polymer-element>'
          '<script src="s1"></script>'
          '</div>'
          '<polymer-element>2</polymer-element>'
          '<script src="s2"></script></body></html>',
      'a|web/test_2.html._data': EMPTY_DATA,
    });

  testPhases('imports cycle, 1-step lasso, Dart scripts too', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_2.html">'
          '</head><body><polymer-element>1</polymer-element>'
          '<script type="application/dart" src="s1.dart">'
          '</script></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head><body><polymer-element>2'
          '<script type="application/dart" src="s2.dart"></script>'
          '</polymer-element>'
          '</html>',
      'a|web/s1.dart': '',
      'a|web/s2.dart': '',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': expectedData(['web/s2.dart', 'web/s1.dart']),
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '<polymer-element>1</polymer-element>'
          '</body></html>',
      'a|web/test_1.html._data': expectedData(['web/s2.dart', 'web/s1.dart']),
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '<polymer-element>2'
          '</polymer-element>'
          '</body></html>',
      'a|web/test_2.html._data': expectedData(['web/s1.dart', 'web/s2.dart']),
    });

  testPhases('imports with Dart script after JS script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head><body>'
          '<foo>42</foo><bar-baz></bar-baz>'
          '<polymer-element>1'
          '<script src="s1.js"></script>'
          '<script type="application/dart" src="s1.dart"></script>'
          '</polymer-element>'
          'FOO</body></html>',
      'a|web/s1.dart': '',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<foo>42</foo><bar-baz></bar-baz>'
          '<polymer-element>1'
          '<script src="s1.js"></script>'
          '</polymer-element>'
          'FOO'
          '</div>'
          '</body></html>',
      'a|web/test.html._data': expectedData(['web/s1.dart']),
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<foo>42</foo><bar-baz></bar-baz>'
          '<polymer-element>1'
          '<script src="s1.js"></script>'
          '</polymer-element>'
          'FOO</body></html>',
      'a|web/test_1.html._data': expectedData(['web/s1.dart']),
    });

  testPhases('imports cycle, 2-step lasso', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_2.html">'
          '</head><body><polymer-element>1</polymer-element></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_3.html">'
          '</head><body><polymer-element>2</polymer-element></html>',
      'a|web/test_3.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head><body><polymer-element>3</polymer-element></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>1</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '</div>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test_3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '<polymer-element>3</polymer-element></body></html>',
    });

  testPhases('imports cycle, self cycle', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '</head><body><polymer-element>1</polymer-element></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>1</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>1</polymer-element></body></html>',
    });

  testPhases('imports DAG', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_1.html">'
          '<link rel="import" href="test_2.html">'
          '</head></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_3.html">'
          '</head><body><polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test_3.html">'
          '</head><body><polymer-element>2</polymer-element></body></html>',
      'a|web/test_3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><polymer-element>3</polymer-element></body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '<polymer-element>2</polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3</polymer-element>'
          '</div>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<div hidden="">'
          '<polymer-element>3</polymer-element>'
          '</div>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test_3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3</polymer-element></body></html>',
    });

  testLogOutput(
      (options) => new ImportInliner(options),
      "missing styles don't throw errors and are not inlined", {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>'
            '<link rel="stylesheet" href="foo.css">'
            '</head></html>',
      }, {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>'
            '<link rel="stylesheet" href="foo.css">'
            '</head><body>'
            '</body></html>',
      }, [
        'warning: Failed to inline stylesheet: '
            'Could not find asset a|web/foo.css. (web/test.html 0 27)',
      ]);

  testLogOutput(
      (options) => new ImportInliner(options),
      "missing html imports throw errors", {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>'
            '<link rel="import" href="foo.html">'
            '</head></html>',
      }, {
        'a|web/test.html._buildLogs.1':
          '{"polymer#25":[{'
            '"level":"Error",'
            '"message":{'
               '"id":"polymer#25",'
               '"snippet":"Failed to inline HTML import: '
                'Could not find asset a|web/foo.html."'
            '},'
            '"span":{'
              '"start":{'
                '"url":"web/test.html",'
                '"offset":27,'
                '"line":0,'
                '"column":27'
              '},'
              '"end":{'
                '"url":"web/test.html",'
                '"offset":62,'
                '"line":0,'
                '"column":62'
              '},'
              '"text":"<link rel=\\"import\\" href=\\"foo.html\\">"'
            '}'
          '}]}',
      }, [
        'error: ${INLINE_IMPORT_FAIL.create({
            'error': 'Could not find asset a|web/foo.html.'}).snippet} '
            '(web/test.html 0 27)',
      ]);
}

void stylesheetTests() {

  testPhases('empty stylesheet', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet" href="">' // empty href
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet">'         // no href
          '</head></html>',
    }, {
      'a|web/test.html':
        '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="">' // empty href
        '</head></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.html':
        '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet">'         // no href
        '</head></html>',
      'a|web/test2.html._data': EMPTY_DATA,
    });

  testPhases('absolute uri', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet" href="/foo.css">'
          '</head></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet" href="http://example.com/bar.css">'
          '</head></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet" href="/foo.css">'
          '</head></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet" href="http://example.com/bar.css">'
          '</head></html>',
      'a|web/test2.html._data': EMPTY_DATA,
    });

  testPhases('shallow, inlines css', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="stylesheet" href="test2.css">'
          '</head></html>',
      'a|web/test2.css':
          'h1 { font-size: 70px; }',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<style>h1 { font-size: 70px; }</style>'
          '</head><body>'
          '</body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.css':
          'h1 { font-size: 70px; }',
    });

  testPhases('deep, inlines css', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head></html>',
      'a|web/test2.html':
          '<polymer-element>2'
          '<link rel="stylesheet" href="assets/b/test3.css">'
          '</polymer-element>',
      'b|asset/test3.css':
          'body {\n  background: #eaeaea url("../../assets/b/test4.png");\n}\n'
          '.foo {\n  background: url("../../packages/c/test5.png");\n}',
      'b|asset/test4.png': 'PNG',
      'c|lib/test5.png': 'PNG',
    }, {
      'a|web/test.html':
        '<!DOCTYPE html><html><head></head><body>'
        '<div hidden="">'
        '<polymer-element>2'
        '<style>'
        'body {\n  background: #eaeaea url(assets/b/test4.png);\n}\n'
        '.foo {\n  background: url(packages/c/test5.png);\n}'
        '</style>'
        '</polymer-element>'
        '</div>'
        '</body></html>',
      'a|web/test2.html':
          '<html><head></head><body>'
          '<polymer-element>2'
          '<style>'
          'body {\n  background: #eaeaea url(assets/b/test4.png);\n}\n'
          '.foo {\n  background: url(packages/c/test5.png);\n}'
          '</style>'
          '</polymer-element>'
          '</body></html>',
      'b|asset/test3.css':
          'body {\n  background: #eaeaea url("../../assets/b/test4.png");\n}\n'
          '.foo {\n  background: url("../../packages/c/test5.png");\n}',
      'b|asset/test4.png': 'PNG',
      'c|lib/test5.png': 'PNG',
    });

  testPhases('deep, inlines css, multiple nesting', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="foo/test2.html">'
          '</head></html>',
      'a|web/foo/test2.html':
          // When parsed, this is in the <head>.
          '<link rel="import" href="bar/test3.html">'
          // This is where the parsed <body> starts.
          '<polymer-element>2'
          '<link rel="stylesheet" href="test.css">'
          '</polymer-element>',
      'a|web/foo/bar/test3.html':
          '<img src="qux.png">',
      'a|web/foo/test.css':
          'body {\n  background: #eaeaea url("test4.png");\n}\n'
          '.foo {\n  background: url("test5.png");\n}',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<div hidden="">'
          '<img src="foo/bar/qux.png">'
          '<polymer-element>2'
          '<style>'
          'body {\n  background: #eaeaea url(foo/test4.png);\n}\n'
          '.foo {\n  background: url(foo/test5.png);\n}'
          '</style></polymer-element>'
          '</div>'
          '</body></html>',
      'a|web/foo/test2.html':
          '<html><head></head><body>'
          '<div hidden="">'
          '<img src="bar/qux.png">'
          '</div>'
          '<polymer-element>2'
          '<style>'
          'body {\n  background: #eaeaea url(test4.png);\n}\n'
          '.foo {\n  background: url(test5.png);\n}'
          '</style></polymer-element>'
          '</body></html>',
      'a|web/foo/bar/test3.html':
          '<img src="qux.png">',
      'a|web/foo/test.css':
          'body {\n  background: #eaeaea url("test4.png");\n}\n'
          '.foo {\n  background: url("test5.png");\n}',
    });

  testPhases('shallow, inlines css and preserves order', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<style>.first { color: black }</style>'
          '<link rel="stylesheet" href="test2.css">'
          '<style>.second { color: black }</style>'
          '</head></html>',
      'a|web/test2.css':
          'h1 { font-size: 70px; }',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<style>.first { color: black }</style>'
          '<style>h1 { font-size: 70px; }</style>'
          '<style>.second { color: black }</style>'
          '</head><body>'
          '</body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test2.css':
          'h1 { font-size: 70px; }',
    });

  testPhases('inlined tags keep original attributes', phases, {
       'a|web/test.html':
           '<!DOCTYPE html><html><head>'
           '<link rel="stylesheet" href="foo.css" no-shim>'
           '<link rel="stylesheet" href="bar.css" shim-shadow foo>'
           '</head></html>',
       'a|web/foo.css':
           'h1 { font-size: 70px; }',
       'a|web/bar.css':
           'h2 { font-size: 35px; }',
     }, {
       'a|web/test.html':
           '<!DOCTYPE html><html><head>'
           '<style no-shim="">h1 { font-size: 70px; }</style>'
           '<style shim-shadow="" foo="">h2 { font-size: 35px; }</style>'
           '</head><body>'
           '</body></html>',
       'a|web/foo.css':
           'h1 { font-size: 70px; }',
       'a|web/bar.css':
           'h2 { font-size: 35px; }',
     });

  testPhases(
      'can configure default stylesheet inlining',
      [[new ImportInliner(new TransformOptions(
          inlineStylesheets: {'default': false}))]], {
        'a|web/test.html':
            '<!DOCTYPE html><html><head></head><body>'
            '<link rel="stylesheet" href="foo.css">'
            '</body></html>',
        'a|web/foo.css':
            'h1 { font-size: 70px; }',
      }, {
        'a|web/test.html':
            '<!DOCTYPE html><html><head></head><body>'
            '<link rel="stylesheet" href="foo.css">'
            '</body></html>',
      });

  testPhases(
      'can override default stylesheet inlining',
      [[new ImportInliner(new TransformOptions(
          inlineStylesheets: {
              'default': false,
              'web/foo.css': true,
              'b|lib/baz.css': true,
          }))]],
      {
          'a|web/test.html':
            '<!DOCTYPE html><html><head></head><body>'
            '<link rel="stylesheet" href="bar.css">'
            '<link rel="stylesheet" href="foo.css">'
            '<link rel="stylesheet" href="packages/b/baz.css">'
            '<link rel="stylesheet" href="packages/c/buz.css">'
            '</body></html>',
          'a|web/foo.css':
            'h1 { font-size: 70px; }',
          'a|web/bar.css':
            'h1 { font-size: 35px; }',
          'b|lib/baz.css':
            'h1 { font-size: 20px; }',
          'c|lib/buz.css':
            'h1 { font-size: 10px; }',
      }, {
          'a|web/test.html':
            '<!DOCTYPE html><html><head></head><body>'
            '<link rel="stylesheet" href="bar.css">'
            '<style>h1 { font-size: 70px; }</style>'
            '<style>h1 { font-size: 20px; }</style>'
            '<link rel="stylesheet" href="packages/c/buz.css">'
            '</body></html>',
      });

  testLogOutput(
      (options) => new ImportInliner(options),
      'warns about multiple inlinings of the same css', {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>'
            '<link rel="stylesheet" href="packages/a/foo.css">'
            '<link rel="stylesheet" href="packages/a/foo.css">'
            '</head><body></body></html>',
        'a|web/test1.html':
            '<!DOCTYPE html><html><head>'
            '<link rel="stylesheet" href="packages/a/foo.css">'
            '<link rel="import" href="packages/a/import1.html">'
            '</head><body></body></html>',
        'a|web/test2.html':
            '<!DOCTYPE html><html><head>'
            '<link rel="import" href="packages/a/import1.html">'
            '<link rel="import" href="packages/a/import2.html">'
            '</head><body></body></html>',
        'a|lib/import1.html':
            '<link rel="stylesheet" href="foo.css">',
        'a|lib/import2.html':
            '<link rel="stylesheet" href="foo.css">',
        'a|lib/foo.css':
            'body {position: relative;}',
      }, {}, [
          'warning: ${CSS_FILE_INLINED_MULTIPLE_TIMES.create(
              {'url': 'lib/foo.css'}).snippet}'
              ' (web/test.html 0 76)',
          'warning: ${CSS_FILE_INLINED_MULTIPLE_TIMES.create(
              {'url': 'lib/foo.css'}).snippet}'
              ' (lib/import1.html 0 0)',
          'warning: ${CSS_FILE_INLINED_MULTIPLE_TIMES.create(
              {'url': 'lib/foo.css'}).snippet}'
              ' (lib/import2.html 0 0)',
      ]);

  testPhases(
        'doesn\'t warn about multiple css inlinings if overriden',
        [[new ImportInliner(new TransformOptions(
            inlineStylesheets: {'lib/foo.css': true}))]], {
            'a|web/test.html':
                '<!DOCTYPE html><html><head>'
                '<link rel="stylesheet" href="packages/a/foo.css">'
                '<link rel="stylesheet" href="packages/a/foo.css">'
                '</head><body></body></html>',
            'a|web/test1.html':
                '<!DOCTYPE html><html><head>'
                '<link rel="stylesheet" href="packages/a/foo.css">'
                '<link rel="import" href="packages/a/import1.html">'
                '</head><body></body></html>',
            'a|web/test2.html':
                '<!DOCTYPE html><html><head>'
                '<link rel="import" href="packages/a/import1.html">'
                '<link rel="import" href="packages/a/import2.html">'
                '</head><body></body></html>',
            'a|lib/import1.html':
                '<link rel="stylesheet" href="foo.css">',
            'a|lib/import2.html':
                '<link rel="stylesheet" href="foo.css">',
            'a|lib/foo.css':
                'body {position: relative;}',
          }, {}, []);
}

void urlAttributeTests() {

  testPhases('url attributes are normalized', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="foo/test_1.html">'
          '<link rel="import" href="foo/test_2.html">'
          '</head></html>',
      'a|web/foo/test_1.html':
          '<script src="baz.jpg"></script>',
      'a|web/foo/test_2.html':
          '<foo-element src="baz.jpg"></foo-element>'
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<div hidden="">'
          '<script src="foo/baz.jpg"></script>'        // normalized
          '<foo-element src="baz.jpg"></foo-element>'  // left alone (custom)
          '</div>'
          '</body></html>',
      'a|web/foo/test_1.html':
          '<script src="baz.jpg"></script>',
      'a|web/foo/test_2.html':
          '<foo-element src="baz.jpg"></foo-element>',
    });

  testPhases('paths with a binding prefix are not normalized', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="foo/test.html">'
          '</head></html>',
      'a|web/foo/test.html':
          '<img src="{{bar}}">'
          '<img src="[[bar]]">',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<div hidden="">'
          '<img src="{{bar}}">'
          '<img src="[[bar]]">'
          '</div>'
          '</body></html>',
      'a|web/foo/test.html':
          '<img src="{{bar}}">'
          '<img src="[[bar]]">',
    });

  testPhases('relative paths followed by bindings are normalized', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="foo/test.html">'
          '</head></html>',
      'a|web/foo/test.html':
          '<img src="baz/{{bar}}">'
          '<img src="./{{bar}}">',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<div hidden="">'
          '<img src="foo/baz/{{bar}}">'
          '<img src="foo/{{bar}}">'
          '</div>'
          '</body></html>',
    });

  testPhases('relative paths in _* attributes are normalized', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="foo/test.html">'
          '</head></html>',
      'a|web/foo/test.html':
          '<img _src="./{{bar}}">'
          '<a _href="./{{bar}}">test</a>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<div hidden="">'
          '<img _src="foo/{{bar}}">'
          '<a _href="foo/{{bar}}">test</a>'
          '</div>'
          '</body></html>',
    });


  testLogOutput(
      (options) => new ImportInliner(options),
      'warnings are given about _* attributes', {
        'a|web/test.html':
            '<!DOCTYPE html><html><head></head><body>'
            '<img src="foo/{{bar}}">'
            '<a _href="foo/bar">test</a>'
            '</body></html>',
      }, {}, [
          'warning: When using bindings with the "src" attribute you may '
              'experience errors in certain browsers. Please use the "_src" '
              'attribute instead. (web/test.html 0 40)',
          'warning: The "_href" attribute is only supported when using '
              'bindings. Please change to the "href" attribute. '
              '(web/test.html 0 63)',

      ]);

  testPhases('arbitrary bindings can exist in paths', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<img src="./{{(bar[2] + baz[\'foo\']) * 14 / foobar() - 0.5}}.jpg">'
          '<img src="./[[bar[2]]].jpg">'
          '</body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<img src="{{(bar[2] + baz[\'foo\']) * 14 / foobar() - 0.5}}.jpg">'
          '<img src="[[bar[2]]].jpg">'
          '</body></html>',
    });

  testPhases('multiple bindings can exist in paths', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<img src="./{{bar[0]}}/{{baz[1]}}.{{extension}}">'
          '</body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<img src="{{bar[0]}}/{{baz[1]}}.{{extension}}">'
          '</body></html>',
    });
}

void entryPointTests() {
  testPhases('one level deep entry points normalize correctly', phases, {
      'a|web/test/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="../../packages/a/foo/foo.html">'
          '</head></html>',
      'a|lib/foo/foo.html':
          '<script rel="import" href="../../../packages/b/bar/bar.js">'
          '</script>',
      'b|lib/bar/bar.js':
          'console.log("here");',
    }, {
      'a|web/test/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<div hidden="">'
          '<script rel="import" href="../packages/b/bar/bar.js"></script>'
          '</div>'
          '</body></html>',
    });

  testPhases('includes in entry points normalize correctly', phases, {
      'a|web/test/test.html':
          '<!DOCTYPE html><html><head>'
          '<script src="packages/a/foo/bar.js"></script>'
          '</head></html>',
      'a|lib/foo/bar.js':
          'console.log("here");',
    }, {
      'a|web/test/test.html':
          '<!DOCTYPE html><html><head>'
          '<script src="../packages/a/foo/bar.js"></script>'
          '</head><body>'
          '</body></html>',
    });

  testPhases('two level deep entry points normalize correctly', phases, {
    'a|web/test/well/test.html':
        '<!DOCTYPE html><html><head>'
        '<link rel="import" href="../../../packages/a/foo/foo.html">'
        '</head></html>',
    'a|lib/foo/foo.html':
        '<script rel="import" href="../../../packages/b/bar/bar.js"></script>',
    'b|lib/bar/bar.js':
        'console.log("here");',
  }, {
    'a|web/test/well/test.html':
        '<!DOCTYPE html><html><head></head><body>'
        '<div hidden="">'
        '<script rel="import" href="../../packages/b/bar/bar.js"></script>'
        '</div>'
        '</body></html>',
  });
}

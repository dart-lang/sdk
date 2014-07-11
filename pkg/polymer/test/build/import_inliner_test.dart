// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.import_inliner_test;

import 'dart:convert' show JSON;
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/import_inliner.dart';
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
          '<polymer-element>2</polymer-element>'
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
          '</head><body>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '<script>/*third*/</script>'
          '<polymer-element>2</polymer-element>'
          '<script>/*forth*/</script>'
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
          '</head><body>'
          '<script type="text/javascript">/*first*/</script>'
          '<script src="second.js"></script>'
          '<script>/*third*/</script>'
          '<polymer-element>2</polymer-element>'
          '</body></html>',
      'a|web/test.html._data': expectedData([
          'web/test.html.1.dart','web/test.html.0.dart']),
      'a|web/test.html.1.dart': 'library a.web.test2_html_0;\n/*forth*/',
      'a|web/test.html.0.dart': 'library a.web.test_html_0;\n/*fifth*/',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head></head><body><script>/*third*/</script>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test2.html._data': expectedData(['web/test2.html.0.dart']),
      'a|web/test2.html.0.dart': 'library a.web.test2_html_0;\n/*forth*/',
      'a|web/second.js': '/*second*/'
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
          '<polymer-element>2</polymer-element>'
          '<polymer-element>3</polymer-element>'
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
          '<polymer-element>4</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>4</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element></body></html>',
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
          '<polymer-element>3a</polymer-element>'
          '<polymer-element>3b</polymer-element>'
          '<polymer-element>2a</polymer-element>'
          '<polymer-element>4a</polymer-element>'
          '<polymer-element>4b</polymer-element>'
          '<polymer-element>2b</polymer-element>'
          '</body></html>',
      'a|web/test2a.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3a</polymer-element>'
          '<polymer-element>3b</polymer-element>'
          '<polymer-element>2a</polymer-element>'
          '</body></html>',
      'a|web/test2b.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>4a</polymer-element>'
          '<polymer-element>4b</polymer-element>'
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
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>1</polymer-element>'
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
          '<polymer-element>2</polymer-element>'
          '<script src="s2"></script>'
          '<polymer-element>1</polymer-element>'
          '<script src="s1"></script></body></html>',
      'a|web/test.html._data': EMPTY_DATA,
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>2</polymer-element>'
          '<script src="s2"></script>'
          '<polymer-element>1</polymer-element>'
          '<script src="s1"></script></body></html>',
      'a|web/test_1.html._data': EMPTY_DATA,
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>1</polymer-element>'
          '<script src="s1"></script>'
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
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '</body></html>',
      'a|web/test.html._data': expectedData(['web/s2.dart', 'web/s1.dart']),
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '</body></html>',
      'a|web/test_1.html._data': expectedData(['web/s2.dart', 'web/s1.dart']),
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>1</polymer-element>'
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
          '<foo>42</foo><bar-baz></bar-baz>'
          '<polymer-element>1'
          '<script src="s1.js"></script>'
          '</polymer-element>'
          'FOO</body></html>',
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
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>1</polymer-element>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test_3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>2</polymer-element>'
          '<polymer-element>1</polymer-element>'
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
          '<polymer-element>1</polymer-element></body></html>',
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
          '<polymer-element>3</polymer-element>'
          '<polymer-element>1</polymer-element>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test_1.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>1</polymer-element></body></html>',
      'a|web/test_2.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3</polymer-element>'
          '<polymer-element>2</polymer-element></body></html>',
      'a|web/test_3.html':
          '<!DOCTYPE html><html><head>'
          '</head><body>'
          '<polymer-element>3</polymer-element></body></html>',
    });
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
          '<!DOCTYPE html><html><head></head><body>'
          '<style>h1 { font-size: 70px; }</style>'
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
        '<polymer-element>2'
        '<style>'
        'body {\n  background: #eaeaea url(assets/b/test4.png);\n}\n'
        '.foo {\n  background: url(packages/c/test5.png);\n}'
        '</style>'
        '</polymer-element>'
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
          '<link rel="import" href="bar/test3.html">'
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
          '<img src="foo/bar/qux.png">'
          '<polymer-element>2'
          '<style>'
          'body {\n  background: #eaeaea url(foo/test4.png);\n}\n'
          '.foo {\n  background: url(foo/test5.png);\n}'
          '</style></polymer-element></body></html>',
      'a|web/foo/test2.html':
          '<html><head></head><body>'
          '<img src="bar/qux.png">'
          '<polymer-element>2'
          '<style>'
          'body {\n  background: #eaeaea url(test4.png);\n}\n'
          '.foo {\n  background: url(test5.png);\n}'
          '</style></polymer-element></body></html>',
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
          '<!DOCTYPE html><html><head></head><body>'
          '<style>.first { color: black }</style>'
          '<style>h1 { font-size: 70px; }</style>'
          '<style>.second { color: black }</style>'
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
           '<!DOCTYPE html><html><head></head><body>'
           '<style no-shim="">h1 { font-size: 70px; }</style>'
           '<style shim-shadow="" foo="">h2 { font-size: 35px; }</style>'
           '</body></html>',
       'a|web/foo.css':
           'h1 { font-size: 70px; }',
       'a|web/bar.css':
           'h2 { font-size: 35px; }',
     });
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
          '<script src="foo/baz.jpg"></script>'        // normalized
          '<foo-element src="baz.jpg"></foo-element>'  // left alone (custom)
          '</body></html>',
      'a|web/foo/test_1.html':
          '<script src="baz.jpg"></script>',
      'a|web/foo/test_2.html':
          '<foo-element src="baz.jpg"></foo-element>',
    }); 
}
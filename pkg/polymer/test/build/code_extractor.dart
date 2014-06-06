// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): merge into import_inliner_test.dart.
// Keeping here for now so it's easier to see the diff.
part of polymer.test.build.import_inliner_test;

void codeExtractorTests() {
  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('single script, no library in script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">main() { }</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '</body></html>',
      'a|web/test.html._data': expectedData(['web/test.html.0.dart']),
      'a|web/test.html.0.dart':
          'library a.web.test_html_0;\nmain() { }',
    });

  testPhases('single script, with library', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library f;\nmain() { }</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '</body></html>',
      'a|web/test.html._data': expectedData(['web/test.html.0.dart']),
      'a|web/test.html.0.dart':
          'library f;\nmain() { }',
    });

  testPhases('under lib/ directory not transformed', phases, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library f;\nmain() { }</script>',
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library f;\nmain() { }</script>'
    });

  testPhases('multiple scripts - removed', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library a1;\nmain1() { }</script>'
          '<script type="application/dart">library a2;\nmain2() { }</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '</body></html>',
      'a|web/test.html._data': expectedData(
          ['web/test.html.0.dart', 'web/test.html.1.dart']),
      'a|web/test.html.0.dart':
          'library a1;\nmain1() { }',
      'a|web/test.html.1.dart':
          'library a2;\nmain2() { }',
    });

  testPhases('multiple imported scripts', phases, {
      'a|web/test.html':
          '<link rel="import" href="test2.html">'
          '<link rel="import" href="bar/test.html">'
          '<link rel="import" href="packages/a/foo/test.html">'
          '<link rel="import" href="packages/b/test.html">',
      'a|web/test2.html':
          '<script type="application/dart">main1() { }',
      'a|web/bar/test.html':
          '<script type="application/dart">main2() { }',
      'a|lib/foo/test.html':
          '<script type="application/dart">main3() { }',
      'b|lib/test.html':
          '<script type="application/dart">main4() { }'
    }, {
      'a|web/test.html':
          '<html><head></head><body></body></html>',
      'a|web/test.html._data': expectedData(["web/test.html.0.dart",
          "web/test.html.1.dart", "web/test.html.2.dart",
          "web/test.html.3.dart"]),
      'a|web/test.html.0.dart': 'library a.web.test2_html_0;\nmain1() { }',
      'a|web/test.html.1.dart': 'library a.web.bar.test_html_0;\nmain2() { }',
      'a|web/test.html.2.dart': 'library a.foo.test_html_0;\nmain3() { }',
      'a|web/test.html.3.dart': 'library b.test_html_0;\nmain4() { }'
    });

  testPhases('experimental bootstrap', phases, {
      'a|web/test.html':
          '<link rel="import" '
          'href="packages/polymer/polymer_experimental.html">'
          '<link rel="import" href="test2.html">',
      'a|web/test2.html':
          '<script type="application/dart">main1() { }',
    }, {
      'a|web/test.html':
          '<html><head></head><body></body></html>',
      'a|web/test.html._data': expectedData(["web/test.html.0.dart"],
          experimental: true),
      'a|web/test.html.0.dart': 'library a.web.test2_html_0;\nmain1() { }',
    });

  group('fixes import/export/part URIs', dartUriTests);
  group('validates script-tag URIs', validateUriTests);
}

dartUriTests() {

  testPhases('from web folder', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2/foo.html">'
          '</head><body></body></html>',
      'a|web/test2/foo.html':
        '<!DOCTYPE html><html><head></head><body>'
        '<script type="application/dart">'
        "import 'package:qux/qux.dart';"
        "import 'foo.dart';"
        "export 'bar.dart';"
        "part 'baz.dart';"
        '</script>'
        '</body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body></body></html>',
      'a|web/test.html._data': expectedData(['web/test.html.0.dart']),
      'a|web/test.html.0.dart':
          "library a.web.test2.foo_html_0;\n"
          "import 'package:qux/qux.dart';"
          "import 'test2/foo.dart';"
          "export 'test2/bar.dart';"
          "part 'test2/baz.dart';",
      'a|web/test2/foo.html':
          '<!DOCTYPE html><html><head></head><body>'
          '</body></html>',
      'a|web/test2/foo.html._data': expectedData(['web/test2/foo.html.0.dart']),
      'a|web/test2/foo.html.0.dart':
          "library a.web.test2.foo_html_0;\n"
          "import 'package:qux/qux.dart';"
          "import 'foo.dart';"
          "export 'bar.dart';"
          "part 'baz.dart';",
    });

  testPhases('from lib folder', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/a/test2/foo.html">'
          '</head><body></body></html>',
      'a|lib/test2/foo.html':
        '<!DOCTYPE html><html><head></head><body>'
        '<script type="application/dart">'
        "import 'package:qux/qux.dart';"
        "import 'foo.dart';"
        "export 'bar.dart';"
        "part 'baz.dart';"
        '</script>'
        '</body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body></body></html>',
      'a|web/test.html._data': expectedData(['web/test.html.0.dart']),
      'a|web/test.html.0.dart':
          "library a.test2.foo_html_0;\n"
          "import 'package:qux/qux.dart';"
          "import 'package:a/test2/foo.dart';"
          "export 'package:a/test2/bar.dart';"
          "part 'package:a/test2/baz.dart';",
      'a|lib/test2/foo.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart">'
          "import 'package:qux/qux.dart';"
          "import 'foo.dart';"
          "export 'bar.dart';"
          "part 'baz.dart';"
          '</script>'
          '</body></html>',
    });

  testPhases('from another pkg', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/b/test2/foo.html">'
          '</head><body></body></html>',
      'b|lib/test2/foo.html':
        '<!DOCTYPE html><html><head></head><body>'
        '<script type="application/dart">'
        "import 'package:qux/qux.dart';"
        "import 'foo.dart';"
        "export 'bar.dart';"
        "part 'baz.dart';"
        '</script>'
        '</body></html>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body></body></html>',
      'a|web/test.html._data': expectedData(['web/test.html.0.dart']),
      'a|web/test.html.0.dart':
          "library b.test2.foo_html_0;\n"
          "import 'package:qux/qux.dart';"
          "import 'package:b/test2/foo.dart';"
          "export 'package:b/test2/bar.dart';"
          "part 'package:b/test2/baz.dart';",
      'b|lib/test2/foo.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart">'
          "import 'package:qux/qux.dart';"
          "import 'foo.dart';"
          "export 'bar.dart';"
          "part 'baz.dart';"
          '</script>'
          '</body></html>',
    });
}

validateUriTests() {

  testPhases('script is inline', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '<script type="application/dart">'
          'main(){}'
          '</script>'
          '</body></html>',
    }, {
      'a|web/test.html._data': expectedData(['web/test.html.0.dart']),
    }, []);

  testPhases('script src is valid', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '<script type="application/dart" src="a.dart"></script>'
          '</body></html>',
      'a|web/a.dart': 'main() {}',
    }, {
      'a|web/test.html._data': expectedData(['web/a.dart']),
    }, []);

  testPhases('script src is invalid', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>\n'
          '<script type="application/dart" src="a.dart"></script>'
          '</body></html>',
    }, {
      'a|web/test.html._data': EMPTY_DATA,
    }, [
      'warning: Script file at "a.dart" not found. (web/test.html 1 0)',
    ]);

  testPhases('many script src around, valid and invalid', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '<script type="application/dart" src="a.dart"></script>'
          '\n<script type="application/dart" src="b.dart"></script>'
          '\n<script type="application/dart" src="c.dart"></script>'
          '\n<script type="application/dart" src="d.dart"></script>'
          '</body></html>',
      'a|web/a.dart': 'main() {}',
      'a|web/c.dart': 'main() {}',
    }, {
      'a|web/test.html._data': expectedData(['web/a.dart', 'web/c.dart']),
    }, [
      'warning: Script file at "b.dart" not found. (web/test.html 1 0)',
      'warning: Script file at "d.dart" not found. (web/test.html 3 0)',
    ]);
}

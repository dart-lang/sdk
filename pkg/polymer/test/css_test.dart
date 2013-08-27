// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library css_test;

import 'package:path/path.dart' as path;
import 'package:polymer/src/messages.dart';
import 'package:polymer/src/utils.dart' as utils;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'testing.dart';

test_simple_var() {
  Map createFiles() {
    return {
      'index.html':
        '<!DOCTYPE html>'
        '<html lang="en">'
          '<head>'
            '<meta charset="utf-8">'
          '</head>'
          '<body>'
            '<style>'
              '@main_color: var(b);'
              '@b: var(c);'
              '@c: red;'
            '</style>'
            '<style>'
              '.test { color: var(main_color); }'
            '</style>'
            '<script type="application/dart">main() {}</script>'
          '</body>'
        '</html>',
    };
  }

  var messages = new Messages.silent();
  var compiler = createCompiler(createFiles(), messages, errors: true,
      scopedCss: true);

  compiler.run().then(expectAsync1((e) {
    MockFileSystem fs = compiler.fileSystem;
    expect(fs.readCount, equals({
      'index.html': 1,
    }), reason: 'Actual:\n  ${fs.readCount}');

    var htmlInfo = compiler.info['index.html'];
    expect(htmlInfo.styleSheets.length, 2);
    expect(prettyPrintCss(htmlInfo.styleSheets[0]), '');
    expect(prettyPrintCss(htmlInfo.styleSheets[1]), '.test { color: red; }');

    var outputs = compiler.output.map((o) => o.path);
    expect(outputs, equals([
      'out/index.html.dart',
      'out/index.html.dart.map',
      'out/index.html_bootstrap.dart',
      'out/index.html',
    ]));
  }));
}

test_var() {
  Map createFiles() {
    return {
      'index.html':
        '<!DOCTYPE html>'
        '<html lang="en">'
          '<head>'
            '<meta charset="utf-8">'
          '</head>'
          '<body>'
            '<style>'
              '@main-color: var(b);'
              '@b: var(c);'
              '@c: red;'
              '@d: var(main-color-1, green);'
              '@border-pen: solid;'
              '@inset: 5px;'
              '@frame-color: solid orange;'
              '@big-border: 2px 2px 2px;'
              '@border-stuff: 3px dashed var(main-color);'
              '@border-2: 3px var(big-border) dashed var(main-color-1, green);'
              '@blue-border: bold var(not-found, 1px 10px blue)'
            '</style>'
            '<style>'
              '.test-1 { color: var(main-color-1, blue); }'
              '.test-2 { color: var(main-color-1, var(main-color)); }'
              '.test-3 { color: var(d, yellow); }'
              '.test-4 { color: var(d-1, yellow); }'
              '.test-5 { color: var(d-1, var(d)); }'
              '.test-6 { border: var(inset) var(border-pen) var(d); }'
              '.test-7 { border: 10px var(border-pen) var(d); }'
              '.test-8 { border: 20px var(border-pen) yellow; }'
              '.test-9 { border: 30px dashed var(d); }'
              '.test-10 { border: 40px var(frame-color);}'
              '.test-11 { border: 40px var(frame-color-1, blue);}'
              '.test-12 { border: 40px var(frame-color-1, solid blue);}'
              '.test-13 {'
                 'border: 40px var(x1, var(x2, var(x3, var(frame-color)));'
              '}'
              '.test-14 { border: 40px var(x1, var(frame-color); }'
              '.test-15 { border: 40px var(x1, solid blue);}'
              '.test-16 { border: 1px 1px 2px 3px var(frame-color);}'
              '.test-17 { border: 1px 1px 2px 3px var(x1, solid blue);}'
              '.test-18 { border: 1px 1px 2px var(border-stuff);}'
              '.test-19 { border: var(big-border) var(border-stuff);}'
              '.test-20 { border: var(border-2);}'
              '.test-21 { border: var(blue-border);}'
            '</style>'
            '<script type="application/dart">main() {}</script>'
          '</body>'
        '</html>',
    };
  }

  var messages = new Messages.silent();
  var compiler = createCompiler(createFiles(), messages, errors: true,
    scopedCss: true);

  compiler.run().then(expectAsync1((e) {
    MockFileSystem fs = compiler.fileSystem;
    expect(fs.readCount, equals({
      'index.html': 1,
    }), reason: 'Actual:\n  ${fs.readCount}');

    var htmlInfo = compiler.info['index.html'];
    expect(htmlInfo.styleSheets.length, 2);
    expect(prettyPrintCss(htmlInfo.styleSheets[0]), '');
    expect(prettyPrintCss(htmlInfo.styleSheets[1]),
        '.test-1 { color: blue; } '
        '.test-2 { color: red; } '
        '.test-3 { color: green; } '
        '.test-4 { color: yellow; } '
        '.test-5 { color: green; } '
        '.test-6 { border: 5px solid green; } '
        '.test-7 { border: 10px solid green; } '
        '.test-8 { border: 20px solid yellow; } '
        '.test-9 { border: 30px dashed green; } '
        '.test-10 { border: 40px solid orange; } '
        '.test-11 { border: 40px blue; } '
        '.test-12 { border: 40px solid blue; } '
        '.test-13 { border: 40px solid orange; } '
        '.test-14 { border: 40px solid orange; } '
        '.test-15 { border: 40px solid blue; } '
        '.test-16 { border: 1px 1px 2px 3px solid orange; } '
        '.test-17 { border: 1px 1px 2px 3px solid blue; } '
        '.test-18 { border: 1px 1px 2px 3px dashed red; } '
        '.test-19 { border: 2px 2px 2px 3px dashed red; } '
        '.test-20 { border: 3px 2px 2px 2px dashed green; } '
        '.test-21 { border: bold 1px 10px blue; }');
    var outputs = compiler.output.map((o) => o.path);
    expect(outputs, equals([
      'out/index.html.dart',
      'out/index.html.dart.map',
      'out/index.html_bootstrap.dart',
      'out/index.html',
    ]));
  }));
}

test_simple_import() {
  Map createFiles() {
    return {
      'foo.css':  r'''@main_color: var(b);
        @b: var(c);
        @c: red;''',
      'index.html':
        '<!DOCTYPE html>'
        '<html lang="en">'
          '<head>'
             '<meta charset="utf-8">'
          '</head>'
          '<body>'
            '<style>'
              '@import "foo.css";'
              '.test { color: var(main_color); }'
            '</style>'
            '<script type="application/dart">main() {}</script>'
          '</body>'
        '</html>',
    };
  }

  var messages = new Messages.silent();
  var compiler = createCompiler(createFiles(), messages, errors: true,
      scopedCss: true);

  compiler.run().then(expectAsync1((e) {
    MockFileSystem fs = compiler.fileSystem;
    expect(fs.readCount, equals({
      'foo.css': 1,
      'index.html': 1,
    }), reason: 'Actual:\n  ${fs.readCount}');

    var cssInfo = compiler.info['foo.css'];
    expect(cssInfo.styleSheets.length, 1);
    expect(prettyPrintCss(cssInfo.styleSheets[0]), '');

    var htmlInfo = compiler.info['index.html'];
    expect(htmlInfo.styleSheets.length, 1);
    expect(prettyPrintCss(htmlInfo.styleSheets[0]),
        '@import url(foo.css); .test { color: red; }');

    var outputs = compiler.output.map((o) => o.path);
    expect(outputs, equals([
      'out/index.html.dart',
      'out/index.html.dart.map',
      'out/index.html_bootstrap.dart',
      'out/foo.css',
      'out/index.html',
    ]));
  }));
}

test_imports() {
  Map createFiles() {
    return {
      'first.css':
        '@import "third.css";'
        '@main-width: var(main-width-b);'
        '@main-width-b: var(main-width-c);'
        '@main-width-c: var(wide-width);',
      'second.css':
        '@import "fourth.css";'
        '@main-color: var(main-color-b);'
        '@main-color-b: var(main-color-c);'
        '@main-color-c: var(color-value);',
      'third.css':
        '@wide-width: var(wide-width-b);'
        '@wide-width-b: var(wide-width-c);'
        '@wide-width-c: 100px;',
      'fourth.css':
        '@color-value: var(color-value-b);'
        '@color-value-b: var(color-value-c);'
        '@color-value-c: red;',
      'index.html':
        '<!DOCTYPE html>'
        '<html lang="en">'
          '<head>'
            '<meta charset="utf-8">'
            '<link rel="stylesheet" href="first.css">'
          '</head>'
          '<body>'
            '<style>'
              '@import "first.css";'
              '@import "second.css";'
              '.test-1 { color: var(main-color); }'
              '.test-2 { width: var(main-width); }'
            '</style>'
            '<script type="application/dart">main() {}</script>'
          '</body>'
        '</html>',
    };
  }

  var messages = new Messages.silent();
  var compiler = createCompiler(createFiles(), messages, errors: true,
      scopedCss: true);

  compiler.run().then(expectAsync1((e) {
    MockFileSystem fs = compiler.fileSystem;
    expect(fs.readCount, equals({
      'first.css': 1,
      'second.css': 1,
      'third.css': 1,
      'fourth.css': 1,
      'index.html': 1,
    }), reason: 'Actual:\n  ${fs.readCount}');

    var firstInfo = compiler.info['first.css'];
    expect(firstInfo.styleSheets.length, 1);
    expect(prettyPrintCss(firstInfo.styleSheets[0]), '@import url(third.css);');

    var secondInfo = compiler.info['second.css'];
    expect(secondInfo.styleSheets.length, 1);
    expect(prettyPrintCss(secondInfo.styleSheets[0]),
        '@import url(fourth.css);');

    var thirdInfo = compiler.info['third.css'];
    expect(thirdInfo.styleSheets.length, 1);
    expect(prettyPrintCss(thirdInfo.styleSheets[0]), '');

    var fourthInfo = compiler.info['fourth.css'];
    expect(fourthInfo.styleSheets.length, 1);
    expect(prettyPrintCss(fourthInfo.styleSheets[0]), '');

    var htmlInfo = compiler.info['index.html'];
    expect(htmlInfo.styleSheets.length, 1);
    expect(prettyPrintCss(htmlInfo.styleSheets[0]),
        '@import url(first.css); '
        '@import url(second.css); '
        '.test-1 { color: red; } '
        '.test-2 { width: 100px; }');

    var outputs = compiler.output.map((o) => o.path);
    expect(outputs, equals([
      'out/index.html.dart',
      'out/index.html.dart.map',
      'out/index.html_bootstrap.dart',
      'out/first.css',
      'out/second.css',
      'out/third.css',
      'out/fourth.css',
      'out/index.html',
    ]));
  }));
}

test_component_var() {
  Map createFiles() {
    return {
      'index.html': '<!DOCTYPE html>'
                    '<html lang="en">'
                      '<head>'
                        '<meta charset="utf-8">'
                        '<link rel="import" href="foo.html">'
                      '</head>'
                      '<body>'
                        '<x-foo></x-foo>'
                        '<script type="application/dart">main() {}</script>'
                      '</body>'
                    '</html>',
      'foo.html': '<!DOCTYPE html>'
                  '<html lang="en">'
                    '<head>'
                      '<meta charset="utf-8">'
                    '</head>'
                    '<body>'
                      '<polymer-element name="x-foo" constructor="Foo">'
                        '<template>'
                          '<style scoped>'
                            '@import "foo.css";'
                            '.main { color: var(main_color); }'
                            '.test-background { '
                              'background:  url(http://www.foo.com/bar.png);'
                            '}'
                          '</style>'
                        '</template>'
                      '</polymer-element>'
                    '</body>'
                  '</html>',
      'foo.css':  r'''@main_color: var(b);
                      @b: var(c);
                      @c: red;

                      @one: var(two);
                      @two: var(one);

                      @four: var(five);
                      @five: var(six);
                      @six: var(four);

                      @def-1: var(def-2);
                      @def-2: var(def-3);
                      @def-3: var(def-2);''',
    };
  }

  test('var- and Less @define', () {
    var messages = new Messages.silent();
    var compiler = createCompiler(createFiles(), messages, errors: true,
      scopedCss: true);

    compiler.run().then(expectAsync1((e) {
      MockFileSystem fs = compiler.fileSystem;
      expect(fs.readCount, equals({
        'index.html': 1,
        'foo.html': 1,
        'foo.css': 1
      }), reason: 'Actual:\n  ${fs.readCount}');

      var cssInfo = compiler.info['foo.css'];
      expect(cssInfo.styleSheets.length, 1);
      var htmlInfo = compiler.info['foo.html'];
      expect(htmlInfo.styleSheets.length, 0);
      expect(htmlInfo.declaredComponents.length, 1);
      expect(htmlInfo.declaredComponents[0].styleSheets.length, 1);

      var outputs = compiler.output.map((o) => o.path);
      expect(outputs, equals([
        'out/foo.html.dart',
        'out/foo.html.dart.map',
        'out/index.html.dart',
        'out/index.html.dart.map',
        'out/index.html_bootstrap.dart',
        'out/foo.css',
        'out/index.html.css',
        'out/index.html',
      ]));

      for (var file in compiler.output) {
        if (file.path == 'out/index.html.css') {
          expect(file.contents,
              '/* Auto-generated from components style tags. */\n'
              '/* DO NOT EDIT. */\n\n'
              '/* ==================================================== \n'
              '   Component x-foo stylesheet \n'
              '   ==================================================== */\n'
              '@import "foo.css";\n'
              '[is="x-foo"] .main {\n'
              '  color: #f00;\n'
              '}\n'
              '[is="x-foo"] .test-background {\n'
              '  background: url("http://www.foo.com/bar.png");\n'
              '}\n\n');
        } else if (file.path == 'out/foo.css') {
          expect(file.contents,
              '/* Auto-generated from style sheet href = foo.css */\n'
              '/* DO NOT EDIT. */\n\n\n\n');
        }
      }

      // Check for warning messages about var- cycles in no expected order.
      expect(messages.messages.length, 8);
      int testBitMap = 0;
      for (var errorMessage in messages.messages) {
        var message = errorMessage.message;
        if (message.contains('var cycle detected var-def-1')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 11);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@def-1: var(def-2)');
          testBitMap |= 1 << 0;
        } else if (message.contains('var cycle detected var-five')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 8);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@five: var(six)');
          testBitMap |= 1 << 1;
        } else if (message.contains('var cycle detected var-six')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 9);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@six: var(four)');
          testBitMap |= 1 << 2;
        } else if (message.contains('var cycle detected var-def-3')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 13);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@def-3: var(def-2)');
          testBitMap |= 1 << 3;
        } else if (message.contains('var cycle detected var-two')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 5);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@two: var(one)');
          testBitMap |= 1 << 4;
        } else if (message.contains('var cycle detected var-def-2')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 12);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@def-2: var(def-3)');
          testBitMap |= 1 << 5;
        } else if (message.contains('var cycle detected var-one')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 4);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@one: var(two)');
          testBitMap |= 1 << 6;
        } else if (message.contains('var cycle detected var-four')) {
          expect(errorMessage.span, isNotNull);
          expect(errorMessage.span.start.line, 7);
          expect(errorMessage.span.start.column, 22);
          expect(errorMessage.span.text, '@four: var(five)');
          testBitMap |= 1 << 7;
        }
      }
      expect(testBitMap, equals((1 << 8) - 1));
    }));
  });
}

test_pseudo_element() {
  var messages = new Messages.silent();
  var compiler = createCompiler({
    'index.html': '<head>'
                  '<link rel="import" href="foo.html">'
                  '<style>'
                    '.test::x-foo { background-color: red; }'
                    '.test::x-foo1 { color: blue; }'
                    '.test::x-foo2 { color: green; }'
                  '</style>'
                  '<body>'
                    '<x-foo class=test></x-foo>'
                    '<x-foo></x-foo>'
                  '<script type="application/dart">main() {}</script>',
    'foo.html': '<head>'
                '<body><polymer-element name="x-foo" constructor="Foo">'
                '<template>'
                  '<div pseudo="x-foo">'
                    '<div>Test</div>'
                  '</div>'
                  '<div pseudo="x-foo1 x-foo2">'
                  '<div>Test</div>'
                  '</div>'
                '</template>',
    }, messages, scopedCss: true);

    compiler.run().then(expectAsync1((e) {
      MockFileSystem fs = compiler.fileSystem;
      expect(fs.readCount, equals({
        'index.html': 1,
        'foo.html': 1,
      }), reason: 'Actual:\n  ${fs.readCount}');

      var outputs = compiler.output.map((o) => o.path);
      expect(outputs, equals([
        'out/foo.html.dart',
        'out/foo.html.dart.map',
        'out/index.html.dart',
        'out/index.html.dart.map',
        'out/index.html_bootstrap.dart',
        'out/index.html',
      ]));
      expect(compiler.output.last.contents, contains(
          '<div pseudo="x-foo_0">'
            '<div>Test</div>'
          '</div>'
          '<div pseudo="x-foo1_1 x-foo2_2">'
          '<div>Test</div>'
          '</div>'));
      expect(compiler.output.last.contents, contains(
          '<style>.test > *[pseudo="x-foo_0"] {\n'
            '  background-color: #f00;\n'
          '}\n'
          '.test > *[pseudo="x-foo1_1"] {\n'
          '  color: #00f;\n'
          '}\n'
          '.test > *[pseudo="x-foo2_2"] {\n'
          '  color: #008000;\n'
          '}'
          '</style>'));
    }));
}

main() {
  useCompactVMConfiguration();

  group('css', () {
    setUp(() {
      utils.path = new path.Builder(style: path.Style.posix);
    });

    tearDown(() {
      utils.path = new path.Builder();
    });

    test('test_simple_var', test_simple_var);
    test('test_var', test_var);
    test('test_simple_import', test_simple_import);
    test('test_imports', test_imports);
    group('test_component_var', test_component_var);
    test('test_pseudo_element', test_pseudo_element);
  });
}

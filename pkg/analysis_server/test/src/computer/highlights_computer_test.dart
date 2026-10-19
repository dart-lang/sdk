// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_testing/src/abstract_context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Highlights2ComputerTest);
  });
}

@reflectiveTest
class Highlights2ComputerTest extends AbstractContextTest {
  late String sourcePath;
  late String content;
  late List<HighlightRegion> highlights;

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_comment() async {
    await _computeHighlights('''
// A trailing comment
''');
    _check(HighlightRegionType.COMMENT_END_OF_LINE, '// A trailing comment');
  }

  Future<void> test_comment_trailing() async {
    await _computeHighlights('''
class A {}
// A trailing comment
''');
    _check(HighlightRegionType.COMMENT_END_OF_LINE, '// A trailing comment');
  }

  Future<void> test_extension() async {
    await _computeHighlights('''
extension E on String {}
''');
    _check(HighlightRegionType.KEYWORD, 'extension');
    _check(HighlightRegionType.KEYWORD, 'on');
  }

  Future<void> test_function_callMethod_invocation() async {
    await _computeHighlights('''
f(void Function(int) x) {
  x.call(2);
}
''');
    _check(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'call');
  }

  Future<void> test_function_callMethod_tearOff() async {
    await _computeHighlights('''
f(void Function(int) x) {
  x.call;
}
''');
    _check(HighlightRegionType.INSTANCE_METHOD_TEAR_OFF, 'call');
  }

  Future<void> test_methodInvocation_ofExtensionOverride_unresolved() async {
    await _computeHighlights('''
extension E on int {}

void f() {
  E(0).foo();
}
''', hasErrors: true);
    _check(HighlightRegionType.IDENTIFIER_DEFAULT, 'foo');
  }

  Future<void> test_nullLiteral() async {
    await _computeHighlights('var x = null;');
    _check(HighlightRegionType.KEYWORD, 'null');
  }

  Future<void> test_range_comments() async {
    var code = '''
// Comment 1
class A {}
// Comment 2
// Comment 3
class B {}
''';
    var start = code.indexOf('// Comment 2');
    var end = start + '// Comment 2'.length;
    await _computeHighlights(code, range: SourceRange(start, end - start));
    _check(HighlightRegionType.COMMENT_END_OF_LINE, '// Comment 2');
    expect(
      highlights.any(
        (h) =>
            content.substring(h.offset, h.offset + h.length) == '// Comment 1',
      ),
      isFalse,
    );
    expect(
      highlights.any(
        (h) =>
            content.substring(h.offset, h.offset + h.length) == '// Comment 3',
      ),
      isFalse,
    );
    expect(
      highlights.any(
        (h) => content.substring(h.offset, h.offset + h.length) == 'A',
      ),
      isFalse,
    );
    expect(
      highlights.any(
        (h) => content.substring(h.offset, h.offset + h.length) == 'B',
      ),
      isFalse,
    );
  }

  Future<void> test_range_pruning() async {
    var code = '''
class A {
  void a() {}
}

class B {
  void b() {}
}

class C {
  void c() {}
}
''';
    var start = code.indexOf('class B');
    var end = code.indexOf('class C');
    await _computeHighlights(code, range: SourceRange(start, end - start));
    _check(HighlightRegionType.KEYWORD, 'class');
    _check(HighlightRegionType.CLASS, 'B');
    _check(HighlightRegionType.INSTANCE_METHOD_DECLARATION, 'b');
    expect(
      highlights.any(
        (h) => content.substring(h.offset, h.offset + h.length) == 'A',
      ),
      isFalse,
    );
    expect(
      highlights.any(
        (h) => content.substring(h.offset, h.offset + h.length) == 'C',
      ),
      isFalse,
    );
    expect(
      highlights.any(
        (h) => content.substring(h.offset, h.offset + h.length) == 'a',
      ),
      isFalse,
    );
    expect(
      highlights.any(
        (h) => content.substring(h.offset, h.offset + h.length) == 'c',
      ),
      isFalse,
    );
  }

  Future<void> test_string_interpolated() async {
    await _computeHighlights(r'''
class A {
  String b(String c) => c;
}
var foo = A();
var bar = A();
var s = 'test1 $foo test2 ${bar.b('test3')}';
''');
    _check(HighlightRegionType.LITERAL_STRING, "'test1 ");
    _check(HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE, 'foo');
    _check(HighlightRegionType.LITERAL_STRING, ' test2 ');
    _check(HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE, 'bar');
    _check(HighlightRegionType.INSTANCE_METHOD_REFERENCE, 'b');
    _check(HighlightRegionType.LITERAL_STRING, "'test3'");
  }

  Future<void> test_throwExpression() async {
    await _computeHighlights('''
void f() {
  throw 'foo';
}
  ''');
    _check(HighlightRegionType.KEYWORD, 'throw');
  }

  void _check(HighlightRegionType expectedType, String expectedText) {
    for (var region in highlights) {
      if (region.type == expectedType) {
        var startIndex = region.offset;
        var endIndex = startIndex + region.length;
        var highlightedText = content.substring(startIndex, endIndex);
        if (highlightedText == expectedText) {
          return;
        }
      }
    }
    fail('Expected region of type $expectedType with text "$expectedText"');
  }

  Future<void> _computeHighlights(
    String content, {
    bool hasErrors = false,
    SourceRange? range,
  }) async {
    this.content = content = normalizeSource(content);
    var file = newFile(sourcePath, content);
    var result = await getResolvedUnit(file);

    if (hasErrors) {
      expect(result.diagnostics, isNotEmpty);
    } else {
      expect(result.diagnostics, isEmpty);
    }

    var computer = DartUnitHighlightsComputer(result.unit, range: range);
    highlights = computer.compute();
  }
}

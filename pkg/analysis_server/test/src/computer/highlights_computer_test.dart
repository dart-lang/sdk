// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Highlights2ComputerTest);
  });
}

@reflectiveTest
class Highlights2ComputerTest extends AbstractContextTest {
  String sourcePath;
  String content;
  List<HighlightRegion> highlights;

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('/home/test/lib/test.dart');
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
    _check(HighlightRegionType.BUILT_IN, 'on');
  }

  Future<void> test_methodInvocation_ofExtensionOverride_unresolved() async {
    await _computeHighlights('''
extension E on int {}

main() {
  E(0).foo();
}
''', hasErrors: true);
    _check(HighlightRegionType.IDENTIFIER_DEFAULT, 'foo');
  }

  Future<void> test_nullLiteral() async {
    await _computeHighlights('var x = null;');
    _check(HighlightRegionType.KEYWORD, 'null');
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
void main() {
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
  }) async {
    this.content = content;
    newFile(sourcePath, content: content);
    var result = await session.getResolvedUnit(sourcePath);

    if (hasErrors) {
      expect(result.errors, isNotEmpty);
    } else {
      expect(result.errors, isEmpty);
    }

    var computer = DartUnitHighlightsComputer(result.unit);
    highlights = computer.compute();
  }
}

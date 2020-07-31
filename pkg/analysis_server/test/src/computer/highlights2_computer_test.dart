// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/computer/computer_highlights2.dart';
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

    var computer = DartUnitHighlightsComputer2(result.unit);
    highlights = computer.compute();
  }
}

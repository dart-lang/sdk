// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/cider/fixes.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderFixesComputerTest);
  });
}

@reflectiveTest
class CiderFixesComputerTest extends CiderServiceTest {
  _CorrectionContext _correctionContext;
  List<CiderErrorFixes> _errorsFixes;

  void assertHasFix(FixKind kind, String expected) {
    var fix = _getFix(kind);

    var fileEdits = fix.change.edits;
    expect(fileEdits, hasLength(1));

    var resultContent = SourceEdit.applySequence(
      _correctionContext.content,
      fileEdits.single.edits,
    );
    expect(resultContent, expected);
  }

  Future<void> test_createMethod() async {
    await _compute(r'''
class A {
}

void f(A a) {
  a.foo(0);^
}
''');

    assertHasFix(DartFixKind.CREATE_METHOD, r'''
class A {
  void foo(int i) {}
}

void f(A a) {
  a.foo(0);
}
''');
  }

  Future<void> test_insertSemicolon() async {
    await _compute(r'''
var v = 0^
''');

    assertHasFix(DartFixKind.INSERT_SEMICOLON, r'''
var v = 0;
''');
  }

  Future<void> _compute(String content) async {
    _updateFile(content);

    _errorsFixes = await CiderFixesComputer(
      logger,
      fileResolver,
    ).compute(
      convertPath(testPath),
      _correctionContext.offset,
    );
  }

  Fix _getFix(FixKind kind) {
    for (var errorFixes in _errorsFixes) {
      for (var fix in errorFixes.fixes) {
        if (fix.kind == kind) {
          return fix;
        }
      }
    }
    fail('No fix $kind');
  }

  void _updateFile(String content) {
    var offset = content.indexOf('^');
    expect(offset, isPositive, reason: 'Expected to find ^');
    expect(content.indexOf('^', offset + 1), -1, reason: 'Expected only one ^');

    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

    content = content.substring(0, offset) + content.substring(offset + 1);
    newFile(testPath, content: content);

    _correctionContext = _CorrectionContext(
      content,
      offset,
      location.lineNumber - 1,
      location.columnNumber - 1,
    );
  }
}

class _CorrectionContext {
  final String content;
  final int offset;
  final int line;
  final int character;

  _CorrectionContext(this.content, this.offset, this.line, this.character);
}

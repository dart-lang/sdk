// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/cider/fixes.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
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
  late _CorrectionContext _correctionContext;
  late List<CiderErrorFixes> _errorsFixes;

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

  Future<void> test_cachedResolvedFiles() async {
    await _compute(r'''
var a = 0^ var b = 1
''');

    // Only the first fix is applied.
    assertHasFix(DartFixKind.INSERT_SEMICOLON, r'''
var a = 0; var b = 1
''');

    // The file was resolved only once, even though we have 2 errors.
    expect(testData.resolvedLibraries, [convertPath(testPath)]);
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

  Future<void> test_importLibrary_withClass() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
class Test {}
''');
    await fileResolver.resolve(path: a.path);

    await _compute(r'''
void f(Test a) {}^
''');

    assertHasFix(DartFixKind.IMPORT_LIBRARY_PROJECT1, r'''
import 'a.dart';

void f(Test a) {}
''');
  }

  Future<void> test_importLibrary_withEnum() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
enum Test {a, b, c}
''');
    await fileResolver.resolve(path: a.path);

    await _compute(r'''
void f(Test a) {}^
''');

    assertHasFix(DartFixKind.IMPORT_LIBRARY_PROJECT1, r'''
import 'a.dart';

void f(Test a) {}
''');
  }

  Future<void> test_importLibrary_withExtension() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
extension E on int {
  void foo() {}
}
''');
    await fileResolver.resolve(path: a.path);

    await _compute(r'''
void f() {
  E(0).foo();^
}
''');

    assertHasFix(DartFixKind.IMPORT_LIBRARY_PROJECT1, r'''
import 'a.dart';

void f() {
  E(0).foo();
}
''');
  }

  Future<void> test_importLibrary_withFunction() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
void foo() {}
''');
    await fileResolver.resolve(path: a.path);

    await _compute(r'''
void f() {
  foo();^
}
''');

    assertHasFix(DartFixKind.IMPORT_LIBRARY_PROJECT1, r'''
import 'a.dart';

void f() {
  foo();
}
''');
  }

  Future<void> test_importLibrary_withMixin() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
mixin Test {}
''');
    await fileResolver.resolve(path: a.path);

    await _compute(r'''
void f(Test a) {}^
''');

    assertHasFix(DartFixKind.IMPORT_LIBRARY_PROJECT1, r'''
import 'a.dart';

void f(Test a) {}
''');
  }

  Future<void> test_importLibrary_withTopLevelVariable() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
var a = 0;
''');
    await fileResolver.resolve(path: a.path);

    await _compute(r'''
void f() {
  a;^
}
''');

    assertHasFix(DartFixKind.IMPORT_LIBRARY_PROJECT1, r'''
import 'a.dart';

void f() {
  a;
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
    ).compute(convertPath(testPath), _correctionContext.line);
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
    var code = TestCode.parse(content);
    content = code.code;

    var offset = code.position.offset;
    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

    newFile(testPath, content);

    _correctionContext = _CorrectionContext(
      content,
      offset,
      location.lineNumber,
      location.columnNumber,
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

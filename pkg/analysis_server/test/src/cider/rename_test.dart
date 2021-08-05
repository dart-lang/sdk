// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/cider/rename.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderRenameComputerTest);
  });
}

@reflectiveTest
class CiderRenameComputerTest extends CiderServiceTest {
  late _CorrectionContext _correctionContext;

  void test_canRename_field() {
    var refactor = _compute(r'''
class A {
 int ^bar;
 void foo() {
   bar = 5;
 }
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'bar');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_function() {
    var refactor = _compute(r'''
void ^foo() {
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'foo');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_label() {
    var refactor = _compute(r'''
main() {
  myLabel:
  while (true) {
    continue ^myLabel;
    break myLabel;
  }
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'myLabel');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_local() {
    var refactor = _compute(r'''
void foo() {
  var ^a = 0; var b = a + 1;
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'a');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_method() {
    var refactor = _compute(r'''
extension E on int {
  void ^foo() {}
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'foo');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_operator() {
    var refactor = _compute(r'''
class A{
  A operator ^+(A other) => this;
}
''');

    expect(refactor, isNull);
  }

  void test_canRename_parameter() {
    var refactor = _compute(r'''
void foo(int ^bar) {
  var a = bar + 1;
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'bar');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_checkName_function() {
    var result = _checkName(r'''
int ^foo() => 2;
''', 'bar');

    expect(result, isNotNull);
    expect(result?.status.problems.length, 0);
    expect(result?.oldName, 'foo');
  }

  void test_checkName_local() {
    var result = _checkName(r'''
void foo() {
  var ^a = 0; var b = a + 1;
}
''', 'bar');

    expect(result, isNotNull);
    expect(result?.status.problems.length, 0);
    expect(result?.oldName, 'a');
  }

  void test_checkName_local_invalid() {
    var result = _checkName(r'''
void foo() {
  var ^a = 0; var b = a + 1;
}
''', 'Aa');

    expect(result, isNotNull);
    expect(result?.status.problems.length, 1);
    expect(result?.oldName, 'a');
  }

  void test_checkName_parameter() {
    var result = _checkName(r'''
void foo(String ^a) {
  var b = a + 1;
}
''', 'bar');

    expect(result, isNotNull);
    expect(result?.status.problems.length, 0);
    expect(result?.oldName, 'a');
  }

  CheckNameResponse? _checkName(String content, String newName) {
    _updateFile(content);

    return CiderRenameComputer(
      fileResolver,
    ).checkNewName(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
      newName,
    );
  }

  CanRenameResponse? _compute(String content) {
    _updateFile(content);

    return CiderRenameComputer(
      fileResolver,
    ).canRename(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
    );
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

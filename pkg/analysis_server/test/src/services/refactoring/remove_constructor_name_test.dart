// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/services/refactoring/remove_constructor_name.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../lsp/request_helpers_mixin.dart';
import '../../../tool/lsp_spec/matchers.dart';
import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstructorNameInClassTest);
    defineReflectiveTests(RemoveConstructorNameInEnumTest);
    defineReflectiveTests(RemoveConstructorNameInExtensionTypeTest);
  });
}

@reflectiveTest
class RemoveConstructorNameInClassTest extends _RemoveConstructorNameTest {
  Future<void> test_primary_hasConflict() async {
    var originalSource = '''
class C.na^me() {
  C();
}
''';
    await _assertRefactoringFails(originalSource: originalSource);
  }

  Future<void> test_primary_onClassName() async {
    var originalSource = '''
class C^.name() {}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C() {}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_onConstructorName() async {
    var originalSource = '''
class C.na^me() {}

void f() {
  C.name();
  C.name;
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C() {}

void f() {
  C();
  C.new;
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_unnamed() async {
    var originalSource = '''
class C^() {}

void f() {
  C();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_factory_onKeyword() async {
    var originalSource = '''
class C {
  factory^ name() => C._()
  C._();
}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  factory() => C._()
  C._();
}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_factory_onName() async {
    var originalSource = '''
class C {
  factory nam^e() => C._()
  C._();
}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  factory() => C._()
  C._();
}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_factory_unnamed() async {
    var originalSource = '''
class C {
  factory^() => C._()
  C._();
}

void f() {
  C();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_new_onKeyword() async {
    var originalSource = '''
class C {
  new^ name();
}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  new();
}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_new_onName() async {
    var originalSource = '''
class C {
  new ^name();
}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  new();
}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_new_unnamed() async {
    var originalSource = '''
class C {
  new^();
}

void f() {
  C();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_simple_hasConflict_withPrimary() async {
    var originalSource = '''
class C() {
  C.na^me();
}
}
''';
    await _assertRefactoringFails(originalSource: originalSource);
  }

  Future<void> test_secondary_simple_hasConflict_withSecondary() async {
    var originalSource = '''
class C {
  C.na^me();
  C();
}
''';
    await _assertRefactoringFails(originalSource: originalSource);
  }

  Future<void> test_secondary_simple_onClassName() async {
    var originalSource = '''
class C {
  C^.name();
}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  C();
}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_simple_onConstructorName() async {
    var originalSource = '''
class C {
  C.na^me();
}

void f() {
  C.name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  C();
}

void f() {
  C();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }
}

@reflectiveTest
class RemoveConstructorNameInEnumTest extends _RemoveConstructorNameTest {
  Future<void> test_primary() async {
    var originalSource = '''
enum E.name^() {
  a.name()
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
enum E() {
  a()
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_unnamed() async {
    var originalSource = '''
enum E^() {
  a
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_new() async {
    var originalSource = '''
enum E {
  a.name();

  new ^name();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
enum E {
  a();

  new();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_simple() async {
    var originalSource = '''
enum E {
  a.named();

  E.n^amed();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
enum E {
  a();

  E();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }
}

@reflectiveTest
class RemoveConstructorNameInExtensionTypeTest
    extends _RemoveConstructorNameTest {
  Future<void> test_primary() async {
    var originalSource = '''
extension type E.name^(int x) {}

void f() {
  E.name(1);
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
extension type E(int x) {}

void f() {
  E(1);
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_unnamed() async {
    var originalSource = '''
extension type E^(int x) {}

void f() {
  E(1);
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }
}

abstract class _RemoveConstructorNameTest extends RefactoringTest
    with LspProgressNotificationsMixin {
  @override
  String get refactoringName => RemoveConstructorName.commandName;

  Future<void> _assertNoRefactoring({required String originalSource}) async {
    if (originalSource.contains('>>>>')) {
      throw 'File content must not include >>>>>';
    }
    addTestSource(originalSource);

    await initializeServer();

    await expectNoCodeActionWithTitle(RemoveConstructorName.constTitle);
  }

  Future<void> _assertRefactoring({
    required String originalSource,
    required String expected,
    String? otherFilePath,
    String? otherFileContent,
    ProgressToken? commandWorkDoneToken,
  }) async {
    if (originalSource.contains('>>>>') ||
        (otherFileContent?.contains('>>>>>') ?? false)) {
      throw 'File content must not include >>>>>';
    }
    addTestSource(originalSource);
    if (otherFilePath != null) {
      newFile(otherFilePath, otherFileContent!);
    }

    await initializeServer();

    var action = await expectCodeActionWithTitle(
      RemoveConstructorName.constTitle,
    );
    await verifyCommandEdits(
      action.command!,
      expected,
      workDoneToken: commandWorkDoneToken,
    );
  }

  Future<void> _assertRefactoringFails({required String originalSource}) async {
    var codeAction = await expectCodeActionLiteral(
      originalSource,
      command: refactoringName,
      title: RemoveConstructorName.constTitle,
    );
    await expectLater(
      executeCommand(codeAction.command!),
      throwsA(
        isResponseError(
          ServerErrorCodes.refactoringComputeStatusFailure,
          message: "There's already an unnamed constructor.",
        ),
      ),
    );
  }
}

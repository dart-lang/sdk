// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/services/refactoring/add_constructor_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../lsp/request_helpers_mixin.dart';
import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddConstructorNameInClassTest);
    defineReflectiveTests(AddConstructorNameInEnumTest);
    defineReflectiveTests(AddConstructorNameInExtensionTypeTest);
  });
}

@reflectiveTest
class AddConstructorNameInClassTest extends _AddConstructorNameTest {
  Future<void> test_primary() async {
    var originalSource = '''
class C^() {}

void f() {
  C();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C.name() {}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_named_onClassName() async {
    var originalSource = '''
class C^.name() {}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_primary_named_onConstructorName() async {
    var originalSource = '''
class C.n^ame() {}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_factory_named_onKeyword() async {
    var originalSource = '''
class C {
  factory^ name() => C._()
  C._();
}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_factory_named_onName() async {
    var originalSource = '''
class C {
  factory nam^e() => C._()
  C._();
}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_factory_noSpace() async {
    var originalSource = '''
class C {
  factory^() => C._()
  C._();
}

void f() {
  C();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  factory name() => C._()
  C._();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_factory_onKeyword() async {
    var originalSource = '''
class C {
  factory^ () => C._()
  C._();
}

void f() {
  C();
}
''';
    // Unfortunately, the refactor doesn't get the AST for the constructor
    // declaration, so it doesn't know about the space after `factory`.
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  factory name () => C._()
  C._();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_factory_onParameterList() async {
    var originalSource = '''
class C {
  factory ^() => C._()
  C._();
}

void f() {
  C();
}
''';
    // Unfortunately, the refactor doesn't get the AST for the constructor
    // declaration, so it doesn't know about the space after `factory`.
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  factory name () => C._()
  C._();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_new_named_onKeyword() async {
    var originalSource = '''
class C {
  new^ name();
}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_new_named_onName() async {
    var originalSource = '''
class C {
  new ^name();
}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_new_noSpace() async {
    var originalSource = '''
class C {
  new^();
}

void f() {
  C();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  new name();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_new_onKeyword() async {
    var originalSource = '''
class C {
  new^ ();
}

void f() {
  C();
}
''';
    // Unfortunately, the refactor doesn't get the AST for the constructor
    // declaration, so it doesn't know about the space after `new`.
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  new name ();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_new_onParameterList() async {
    var originalSource = '''
class C {
  new ^();
}

void f() {
  C();
}
''';
    // Unfortunately, the refactor doesn't get the AST for the constructor
    // declaration, so it doesn't know about the space after `new`.
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  new name ();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_simple() async {
    var originalSource = '''
class C {
  C^();
}

void f() {
  C();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  C.name();
}

void f() {
  C.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_simple_hasConflict() async {
    var originalSource = '''
class C {
  C^();

  String get name => '';
}

void f() {
  C();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
class C {
  C.name1();

  String get name => '';
}

void f() {
  C.name1();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_secondary_simple_named_onClassName() async {
    var originalSource = '''
class C {
  C^.name();
}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_simple_named_onConstructorName() async {
    var originalSource = '''
class C {
  C.na^me();
}

void f() {
  C.name();
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }
}

@reflectiveTest
class AddConstructorNameInEnumTest extends _AddConstructorNameTest {
  Future<void> test_primary() async {
    var originalSource = '''
enum E^() {
  a
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
enum E.name() {
  a.name()
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_named() async {
    var originalSource = '''
enum E.n^ame() {
  a
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_secondary_new() async {
    var originalSource = '''
enum E {
  a;

  new^();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
enum E {
  a.name();

  new name();
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
  a;

  E^();
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
enum E {
  a.name();

  E.name();
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }
}

@reflectiveTest
class AddConstructorNameInExtensionTypeTest extends _AddConstructorNameTest {
  Future<void> test_primary() async {
    var originalSource = '''
extension type E^(int x) {}

void f() {
  E(1);
}
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
extension type E.name(int x) {}

void f() {
  E.name(1);
}
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_primary_named() async {
    var originalSource = '''
extension type E.name^(int x) {}

void f() {
  E.name(1);
}
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }
}

abstract class _AddConstructorNameTest extends RefactoringTest
    with LspProgressNotificationsMixin {
  @override
  String get refactoringName => AddConstructorName.commandName;

  Future<void> _assertNoRefactoring({required String originalSource}) async {
    if (originalSource.contains('>>>>')) {
      throw 'File content must not include >>>>>';
    }
    addTestSource(originalSource);

    await initializeServer();

    await expectNoCodeActionWithTitle(AddConstructorName.constTitle);
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

    var action = await expectCodeActionWithTitle(AddConstructorName.constTitle);
    await verifyCommandEdits(
      action.command!,
      expected,
      workDoneToken: commandWorkDoneToken,
    );
  }
}

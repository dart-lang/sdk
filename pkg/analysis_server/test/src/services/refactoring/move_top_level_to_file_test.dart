// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveTopLevelToFileTest);
  });
}

@reflectiveTest
class MoveTopLevelToFileTest extends RefactoringTest {
  /// Simple file content with a single class named 'A'.
  static const simpleClassContent = '''
class ^A {}
''';

  /// The title of the refactor when using [simpleClassContent].
  static const simpleClassRefactorTitle = "Move 'A' to file";

  @override
  String get refactoringName => MoveTopLevelToFile.commandName;

  /// Replaces the "Save URI" argument in [action].
  void replaceSaveUriArgument(CodeAction action, Uri newFileUri) {
    final arguments = getRefactorCommandArguments(action);
    // The filename is the first item we prompt for so is first in the
    // arguments.
    arguments[0] = newFileUri.toString();
  }

  @override
  void setUp() {
    super.setUp();

    setFileCreateSupport();
  }

  /// Test that references to getter/setters in different libraries used in
  /// a compound assignment are both imported into the destination file.
  Future<void> test_compoundAssignment_multipleLibraries() async {
    newFile('$projectFolderPath/lib/getter.dart', '''
int get splitVariable => 0;
''');
    newFile('$projectFolderPath/lib/setter.dart', '''
set splitVariable(num _) {}
''');

    var originalSource = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void function^ToMove() {
  splitVariable += 1;
}
''';
    var declarationName = 'functionToMove';

    var expected = '''
>>>>>>>>>> lib/function_to_move.dart created
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void functionToMove() {
  splitVariable += 1;
}
>>>>>>>>>> lib/main.dart
import 'package:test/getter.dart';
import 'package:test/setter.dart';
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_copyFileHeader() async {
    var originalSource = '''
// File header.

class A {}

class ClassToMove^ {}

class B {}
''';
    var declarationName = 'ClassToMove';

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart created
// File header.

class ClassToMove {}
>>>>>>>>>> lib/main.dart
// File header.

class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_existingFile() async {
    addTestSource(simpleClassContent);

    /// Existing new file contents where 'ClassToMove' will be moved to.
    final newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    newFile(newFilePath, '''
int? a;
''');

    /// Expected updated new file contents.
    const expected = '''
>>>>>>>>>> lib/a.dart
int? a;

class A {}
>>>>>>>>>> lib/main.dart empty
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await verifyCommandEdits(action.command!, expected);
  }

  Future<void> test_existingFile_withHeader() async {
    addTestSource(simpleClassContent);

    /// Existing new file contents where 'ClassToMove' will be moved to.
    final newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    newFile(newFilePath, '''
// This is a file header

int? a;
''');

    /// Expected updated new file contents.
    const expected = '''
>>>>>>>>>> lib/a.dart
// This is a file header

int? a;

class A {}
>>>>>>>>>> lib/main.dart empty
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await verifyCommandEdits(action.command!, expected);
  }

  Future<void> test_existingFile_withImports() async {
    addTestSource(simpleClassContent);

    /// Existing new file contents where 'ClassToMove' will be moved to.
    final newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    newFile(newFilePath, '''
import 'dart:async';

FutureOr<int>? a;
''');

    /// Expected updated new file contents.
    const expected = '''
>>>>>>>>>> lib/a.dart
import 'dart:async';

FutureOr<int>? a;

class A {}
>>>>>>>>>> lib/main.dart empty
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await verifyCommandEdits(action.command!, expected);
  }

  Future<void> test_imports_declarationInSrc() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    newFile(libFilePath, 'export "src/a.dart";');
    newFile(srcFilePath, 'class A {}');
    var originalSource = '''
import 'package:test/a.dart';

A? staying;
A? mov^ing;
''';
    var declarationName = 'moving';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/a.dart';

A? staying;
>>>>>>>>>> lib/moving.dart created
import 'package:test/a.dart';

A? moving;
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_imports_extensionMethod() async {
    var otherFilePath = '$projectFolderPath/lib/extensions.dart';
    var otherFileContent = '''
import 'package:test/main.dart';

extension AExtension on A {
  void extensionMethod() {}
}
''';

    var originalSource = '''
import 'package:test/extensions.dart';

class A {}

void ^f() {
  A().extensionMethod();
}
''';
    var declarationName = 'f';

    var expected = '''
>>>>>>>>>> lib/f.dart created
import 'package:test/extensions.dart';
import 'package:test/main.dart';

void f() {
  A().extensionMethod();
}
>>>>>>>>>> lib/main.dart
import 'package:test/extensions.dart';

class A {}
''';

    await _singleDeclaration(
        originalSource: originalSource,
        expected: expected,
        declarationName: declarationName,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent);
  }

  Future<void> test_imports_extensionOperator() async {
    var otherFilePath = '$projectFolderPath/lib/extensions.dart';
    var otherFileContent = '''
import 'package:test/main.dart';

extension AExtension on A {
  A operator +(A other) => this;
}
''';

    var originalSource = '''
import 'package:test/extensions.dart';

class A {}

void ^f() {
  A() + A();
}
''';
    var declarationName = 'f';

    var expected = '''
>>>>>>>>>> lib/f.dart created
import 'package:test/extensions.dart';
import 'package:test/main.dart';

void f() {
  A() + A();
}
>>>>>>>>>> lib/main.dart
import 'package:test/extensions.dart';

class A {}
''';

    await _singleDeclaration(
        originalSource: originalSource,
        expected: expected,
        declarationName: declarationName,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent);
  }

  Future<void> test_imports_prefix_cascade() async {
    var otherFileDeclarations = '''
final list = <int>[];
''';

    var movingCode = '''
void ^moving() {
  other.list
    ..add(1)
    ..add(2);
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_class() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
other.A? ^moving;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_class_extends() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
class Mov^ing extends other.A {}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingDeclarationName: 'Moving',
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_compoundAssignment() async {
    var otherFileDeclarations = '''
int a = 0;
''';

    var movingCode = '''
void ^moving() {
  other.a += 1;
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_constructor_named() async {
    var otherFileDeclarations = '''
class A {
  A.named();
}
''';

    var movingCode = '''
final ^moving = other.A.named();
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_constructor_named_tearoff() async {
    var otherFileDeclarations = '''
class A {
  A.named();
}
''';

    var movingCode = '''
final ^moving = other.A.named;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_constructor_unnamed() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
final ^moving = other.A();
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_constructor_unnamed_tearoff() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
final ^moving = other.A.new;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_extension_method() async {
    var otherFilePath = '$projectFolderPath/lib/extensions.dart';
    var otherFileContent = '''
import 'package:test/main.dart';

extension X on A {
  void extensionMethod();
}
''';

    var originalSource = '''
import 'package:test/extensions.dart' as other;

class A {}

void ^moving() {
  A().extensionMethod();
}
''';
    var movingDeclarationName = 'moving';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/extensions.dart' as other;

class A {}
>>>>>>>>>> lib/moving.dart created
import 'package:test/extensions.dart' as other;
import 'package:test/main.dart';

void moving() {
  A().extensionMethod();
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        expected: expected,
        declarationName: movingDeclarationName,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent);
  }

  Future<void> test_imports_prefix_extension_operator() async {
    var otherFilePath = '$projectFolderPath/lib/extensions.dart';
    var otherFileContent = '''
import 'package:test/main.dart';

extension X on A {
  A operator +(A other) => this;
}
''';

    var originalSource = '''
import 'package:test/extensions.dart' as other;

class A {}

void ^moving() {
  A() + A();
}
''';
    var movingDeclarationName = 'moving';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/extensions.dart' as other;

class A {}
>>>>>>>>>> lib/moving.dart created
import 'package:test/extensions.dart' as other;
import 'package:test/main.dart';

void moving() {
  A() + A();
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        expected: expected,
        declarationName: movingDeclarationName,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent);
  }

  Future<void> test_imports_prefix_extensionOverride() async {
    var otherFileDeclarations = '''
extension E on int { void f() {} },
''';

    var movingCode = '''
void ^moving() {
  other.E(0).f();
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_function() async {
    var otherFileDeclarations = '''
void f() {}
''';

    var movingCode = '''
void ^moving() {
  other.f();
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_function_tearoff() async {
    var otherFileDeclarations = '''
void f() {}
''';

    var movingCode = '''
final mov^ing = other.f;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_functionInvocationExpression() async {
    var otherFileDeclarations = '''
final f = () {};
''';

    var movingCode = '''
void mov^ing() {
  other.f();
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_getterSetter() async {
    var otherFileDeclarations = '''
String get a => '';
set a(String value) {}
''';

    var movingCode = '''
void ^moving() {
  other.a = '';
  other.a;
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_postfixIncrement() async {
    var otherFileDeclarations = '''
int a = 0;
''';

    var movingCode = '''
void ^moving() {
  other.a++;
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_prefixIncrement() async {
    var otherFileDeclarations = '''
int a = 0;
''';

    var movingCode = '''
void ^moving() {
  ++other.a;
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_staticGetterSetter() async {
    var otherFileDeclarations = '''
class A {
  static String get a => '';
  static set a(String value) {}
}
''';

    var movingCode = '''
void ^moving() {
  other.A.a = '';
  other.A.a;
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_staticMethod() async {
    var otherFileDeclarations = '''
class A {
  static void f() {}
}
''';

    var movingCode = '''
void ^moving() {
  other.A.f();
}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_typeArgument() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
List<other.A>? ^moving;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_typeDefinition_source() async {
    var otherFileDeclarations = '''
typedef A = String;
''';

    var movingCode = '''
other.A? ^moving;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_typeDefinition_target() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
typedef ^Moving = other.A;
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingDeclarationName: 'Moving',
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_prefix_typeParameter() async {
    var otherFileDeclarations = '''
class A {}
''';

    var movingCode = '''
class Mov^ing<T extends other.A> {}
''';

    await _testPrefixCopied(
      declarations: otherFileDeclarations,
      movingDeclarationName: 'Moving',
      movingCode: movingCode,
    );
  }

  Future<void> test_imports_referenceFromMovingToImported() async {
    var originalSource = '''
import 'dart:io';

class A {}

class B^ {
  File? f;
}
''';
    var declarationName = 'B';

    var expected = '''
>>>>>>>>>> lib/b.dart created
import 'dart:io';

class B {
  File? f;
}
>>>>>>>>>> lib/main.dart
import 'dart:io';

class A {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_imports_referenceFromMovingToStaying() async {
    var originalSource = '''
class A {}

class ClassToMove^ extends A {}
''';
    var declarationName = 'ClassToMove';

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart created
import 'package:test/main.dart';

class ClassToMove extends A {}
>>>>>>>>>> lib/main.dart
class A {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_imports_referenceFromStayingToMoving() async {
    var originalSource = '''
class A extends B {}

class B^ {}
''';
    var declarationName = 'B';

    var expected = '''
>>>>>>>>>> lib/b.dart created
class B {}
>>>>>>>>>> lib/main.dart
import 'package:test/b.dart';

class A extends B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_imports_referenceInThirdFile_noPrefix() async {
    var originalSource = '''
class A {}

class B^ {}
''';
    var declarationName = 'B';
    var otherFilePath = '$projectFolderPath/lib/c.dart';
    var otherFileContent = '''
import 'package:test/main.dart';

B? b;
''';

    var expected = '''
>>>>>>>>>> lib/b.dart created
class B {}
>>>>>>>>>> lib/c.dart
import 'package:test/b.dart';
import 'package:test/main.dart';

B? b;
>>>>>>>>>> lib/main.dart
class A {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
    );
  }

  Future<void> test_imports_referenceInThirdFile_withMultiplePrefixes() async {
    var originalSource = '''
class A {}

class B^ {}
''';
    var declarationName = 'B';
    var otherFilePath = '$projectFolderPath/lib/c.dart';
    var otherFileContent = '''
import 'package:test/main.dart';
import 'package:test/main.dart' as p;
import 'package:test/main.dart' as q;

void f(p.B b, q.B b, B b) {}
''';

    var expected = '''
>>>>>>>>>> lib/b.dart created
class B {}
>>>>>>>>>> lib/c.dart
import 'package:test/b.dart';
import 'package:test/b.dart' as p;
import 'package:test/b.dart' as q;
import 'package:test/main.dart';
import 'package:test/main.dart' as p;
import 'package:test/main.dart' as q;

void f(p.B b, q.B b, B b) {}
>>>>>>>>>> lib/main.dart
class A {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
    );
  }

  Future<void> test_imports_referenceInThirdFile_withSinglePrefix() async {
    var originalSource = '''
class A {}

class B^ {}
''';
    var declarationName = 'B';
    var otherFilePath = '$projectFolderPath/lib/c.dart';
    var otherFileContent = '''
import 'package:test/main.dart' as p;

p.B? b;
''';

    var expected = '''
>>>>>>>>>> lib/b.dart created
class B {}
>>>>>>>>>> lib/c.dart
import 'package:test/b.dart' as p;
import 'package:test/main.dart' as p;

p.B? b;
>>>>>>>>>> lib/main.dart
class A {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
    );
  }

  /// Test moving declarations to a file that imports a library that exports a
  /// referenced declaration, but currently hides it.
  Future<void> test_imports_showHide_destinationHides() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    var destinationFileName = 'moving.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    newFile(libFilePath, 'export "src/a.dart";');
    newFile(srcFilePath, 'class A {}');
    newFile(destinationFilePath, '''
import 'package:test/a.dart' hide A;
''');
    var originalSource = '''
import 'package:test/a.dart';

A? staying;
A? mov^ing;
''';
    var declarationName = 'moving';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/a.dart';

A? staying;
>>>>>>>>>> lib/moving.dart
import 'package:test/a.dart' hide A;
import 'package:test/a.dart';

A? moving;
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  /// Test moving declarations to a file that imports a library that exports a
  /// referenced declaration, but currently hides it.
  Future<void> test_imports_showHide_destinationHides_sourceShows() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    var destinationFileName = 'moving.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    newFile(libFilePath, 'export "src/a.dart";');
    newFile(srcFilePath, 'class A {}');
    newFile(destinationFilePath, '''
import 'package:test/a.dart' hide A;
''');
    var originalSource = '''
import 'package:test/a.dart' show A;

A? staying;
A? mov^ing;
''';
    var declarationName = 'moving';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/a.dart' show A;

A? staying;
>>>>>>>>>> lib/moving.dart
import 'package:test/a.dart' hide A;
import 'package:test/a.dart' show A;

A? moving;
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  /// Test that if the moving declaration was imported with 'show' that any new
  /// import added to the destination also only shows it.
  Future<void> test_imports_showHide_sourceShows() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    newFile(libFilePath, 'export "src/a.dart";');
    newFile(srcFilePath, 'class A {}');
    var originalSource = '''
import 'package:test/a.dart' show A;

A? staying;
A? mov^ing;
''';
    var declarationName = 'moving';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/a.dart' show A;

A? staying;
>>>>>>>>>> lib/moving.dart created
import 'package:test/a.dart' show A;

A? moving;
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_kind_class() async {
    var originalSource = '''
class A {}

class ClassToMove^ {}

class B {}
''';
    var declarationName = 'ClassToMove';

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart created
class ClassToMove {}
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_logsAction() async {
    addTestSource(simpleClassContent);
    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await executeRefactor(action);

    expectCommandLogged('dart.refactor.move_top_level_to_file');
  }

  Future<void> test_multiple() async {
    var originalSource = '''
class A {}

class ClassTo[!Move1 {}

class ClassTo!]Move2 {}

class B {}
''';

    var expected = '''
>>>>>>>>>> lib/class_to_move1.dart created
class ClassToMove1 {}

class ClassToMove2 {}
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _multipleDeclarations(
      originalSource: originalSource,
      expected: expected,
      count: 2,
    );
  }

  Future<void> test_none_comment() async {
    addTestSource('''
// Comm^ent

class A {}

''');
    await initializeServer();
    await expectNoCodeAction(null);
  }

  Future<void> test_none_directive() async {
    addTestSource('''
imp^ort 'dart:core';

class A {}

''');
    await initializeServer();
    await expectNoCodeAction(null);
  }

  /// Test that references to getter/setters in different libraries used in
  /// a postfix increment are both imported into the destination file.
  Future<void> test_postfixIncrement_multipleLibraries() async {
    newFile('$projectFolderPath/lib/getter.dart', '''
    int get splitVariable => 0;
    ''');
    newFile('$projectFolderPath/lib/setter.dart', '''
    set splitVariable(num _) {}
    ''');

    var originalSource = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void function^ToMove() {
  splitVariable++;
}
''';
    var declarationName = 'functionToMove';

    var expected = '''
>>>>>>>>>> lib/function_to_move.dart created
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void functionToMove() {
  splitVariable++;
}
>>>>>>>>>> lib/main.dart
import 'package:test/getter.dart';
import 'package:test/setter.dart';
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void>
      test_protocol_available_withClientCommandParameterSupport() async {
    addTestSource(simpleClassContent);
    await initializeServer();
    await expectCodeAction(simpleClassRefactorTitle);
  }

  Future<void>
      test_protocol_available_withoutClientCommandParameterSupport() async {
    addTestSource(simpleClassContent);
    await initializeServer();
    // This refactor is available without command parameter support because
    // it has defaults.
    await expectCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_protocol_available_withoutExperimentalOptIn() async {
    addTestSource(simpleClassContent);
    await initializeServer(experimentalOptInFlag: false);
    await expectCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_protocol_clientModifiedValues() async {
    addTestSource(simpleClassContent);

    /// Filename to inject to replace default.
    final newFilePath = join(projectFolderPath, 'lib', 'my_new_class.dart');
    final newFileUri = Uri.file(newFilePath);

    /// Expected new file content.
    const expected = '''
>>>>>>>>>> lib/main.dart empty
>>>>>>>>>> lib/my_new_class.dart created
class A {}
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    // Replace the file URI argument with our custom path.
    replaceSaveUriArgument(action, newFileUri);
    await verifyCommandEdits(action.command!, expected);
  }

  Future<void> test_protocol_unavailable_withoutFileCreateSupport() async {
    addTestSource(simpleClassContent);
    setFileCreateSupport(false);
    await initializeServer();
    await expectNoCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_sealedClass_extends() async {
    var originalSource = '''
sealed class [!Either!] {}

class Left extends Either {}
class Right extends Either {}

class Neither {}
''';

    var expected = '''
>>>>>>>>>> lib/either.dart created
sealed class Either {}

class Left extends Either {}
class Right extends Either {}
>>>>>>>>>> lib/main.dart

class Neither {}
''';
    await _multipleDeclarations(
      originalSource: originalSource,
      expected: expected,
      count: 3,
    );
  }

  /// The code action is not available if you select a subclass of a sealed
  /// type.
  Future<void> test_sealedClass_extends_subclass() async {
    addTestSource('''
sealed class Either {}

class [!Left!] extends Either {}
class Right extends Either {}
''');

    await initializeServer();
    await expectNoCodeAction(null);
  }

  Future<void>
      test_sealedClass_extends_superclass_withDirectSubclassInOtherPart() async {
    addTestSource('''
part 'part2.dart';

sealed class [!Either!] {}
''');
    var otherFilePath = '$projectFolderPath/lib/part2.dart';
    var otherFileContent = '''
part of 'main.dart';

class Left extends Either {}
''';

    newFile(otherFilePath, otherFileContent);

    await initializeServer();
    await expectNoCodeAction(null);
  }

  Future<void>
      test_sealedClass_extends_superclass_withIndirectSubclass() async {
    var originalSource = '''
sealed class [!Either!] {}

class Left extends Either {}
class Right extends Either {}

class LeftSub extends Left {}

class Neither {}
''';

    // TODO(dantup): Track down where this extra newline is coming from.
    var expected = '''
>>>>>>>>>> lib/either.dart created
sealed class Either {}

class Left extends Either {}
class Right extends Either {}
>>>>>>>>>> lib/main.dart
import 'package:test/either.dart';


class LeftSub extends Left {}

class Neither {}
''';
    await _multipleDeclarations(
      originalSource: originalSource,
      expected: expected,
      count: 3,
    );
  }

  Future<void> test_sealedClass_extends_superclassAndSubclass() async {
    var originalSource = '''
sealed class [!Either {}

class Left!] extends Either {}
class Right extends Either {}

class Neither {}
''';

    var expected = '''
>>>>>>>>>> lib/either.dart created
sealed class Either {}

class Left extends Either {}
class Right extends Either {}
>>>>>>>>>> lib/main.dart

class Neither {}
''';
    await _multipleDeclarations(
      originalSource: originalSource,
      expected: expected,
      count: 3,
    );
  }

  Future<void> test_sealedClass_implements() async {
    var originalSource = '''
sealed class [!Either!] {}

class Left implements Either {}
class Right implements Either {}

class Neither {}
''';

    var expected = '''
>>>>>>>>>> lib/either.dart created
sealed class Either {}

class Left implements Either {}
class Right implements Either {}
>>>>>>>>>> lib/main.dart

class Neither {}
''';
    await _multipleDeclarations(
      originalSource: originalSource,
      expected: expected,
      count: 3,
    );
  }

  Future<void> test_sealedClass_sealedSubclass_extends_superclass() async {
    var originalSource = '''
sealed class [!SealedRoot!] {}

class Subclass extends SealedRoot {}
sealed class SealedSubclass extends SealedRoot {}

class SubSubclass extends SealedSubclass {}

class SubSubSubclass extends SubSubclass {}
''';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/sealed_root.dart';


class SubSubSubclass extends SubSubclass {}
>>>>>>>>>> lib/sealed_root.dart created
sealed class SealedRoot {}

class Subclass extends SealedRoot {}
sealed class SealedSubclass extends SealedRoot {}

class SubSubclass extends SealedSubclass {}
''';
    await _multipleDeclarations(
      originalSource: originalSource,
      expected: expected,
      count: 4,
    );
  }

  Future<void> test_single_class_withTypeParameters() async {
    var originalSource = '''
class A {}

class ClassToMove^<T> {}

class B {}
''';
    var declarationName = 'ClassToMove';

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart created
class ClassToMove<T> {}
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_enum() async {
    var originalSource = '''
class A {}

enum EnumToMove^ { a, b }

class B {}
''';
    var declarationName = 'EnumToMove';

    var expected = '''
>>>>>>>>>> lib/enum_to_move.dart created
enum EnumToMove { a, b }
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_extension() async {
    var originalSource = '''
class A {}

extension ExtensionToMove^ on int { }

class B {}
''';
    var declarationName = 'ExtensionToMove';

    var expected = '''
>>>>>>>>>> lib/extension_to_move.dart created
extension ExtensionToMove on int { }
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_function_endOfName() async {
    var originalSource = '''
class A {}

void functionToMove^() { }

class B {}
''';
    var declarationName = 'functionToMove';

    var expected = '''
>>>>>>>>>> lib/function_to_move.dart created
void functionToMove() { }
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_function_middleOfName() async {
    var originalSource = '''
class A {}

void functionToMo^ve() { }

class B {}
''';
    var declarationName = 'functionToMove';

    var expected = '''
>>>>>>>>>> lib/function_to_move.dart created
void functionToMove() { }
>>>>>>>>>> lib/main.dart
class A {}

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_mixin() async {
    var originalSource = '''
class A {}

mixin MixinToMove^ { }

class B {}
''';
    var declarationName = 'MixinToMove';

    var expected = '''
>>>>>>>>>> lib/main.dart
class A {}

class B {}
>>>>>>>>>> lib/mixin_to_move.dart created
mixin MixinToMove { }
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_parts_libraryToPart() async {
    var originalSource = '''
part 'class_to_move.dart';

class Clas^sToMove {}
''';
    var declarationName = 'ClassToMove';
    var destinationFileName = 'class_to_move.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    newFile(destinationFilePath, '''
part of 'main.dart';
''');

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart
part of 'main.dart';

class ClassToMove {}
>>>>>>>>>> lib/main.dart
part 'class_to_move.dart';
''';

    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_parts_partToLibrary() async {
    var originalSource = '''
part of 'class_to_move.dart';

class Clas^sToMove {}
''';
    var declarationName = 'ClassToMove';
    var destinationFileName = 'class_to_move.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    newFile(destinationFilePath, '''
part 'main.dart';
''');

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart
part 'main.dart';

class ClassToMove {}
>>>>>>>>>> lib/main.dart
part of 'class_to_move.dart';
''';

    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_parts_partToPart() async {
    var originalSource = '''
part of 'containing_library.dart';

class Clas^sToMove {}
''';
    var declarationName = 'ClassToMove';
    var destinationFileName = 'class_to_move.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    newFile(destinationFilePath, '''
part of 'containing_library.dart';
''');
    var containingLibraryFilePath =
        join(projectFolderPath, 'lib', 'containing_library.dart');
    var containingLibraryFileContent = '''
part 'main.dart';
part 'class_to_move.dart';
''';

    var expected = '''
>>>>>>>>>> lib/class_to_move.dart
part of 'containing_library.dart';

class ClassToMove {}
>>>>>>>>>> lib/main.dart
part of 'containing_library.dart';
''';
    await _singleDeclaration(
        originalSource: originalSource,
        expected: expected,
        declarationName: declarationName,
        otherFilePath: containingLibraryFilePath,
        otherFileContent: containingLibraryFileContent);
  }

  Future<void> test_single_typedef() async {
    var originalSource = '''
class A {}

typedef TypeToMove^ = void Function();

class B {}
''';
    var declarationName = 'TypeToMove';

    var expected = '''
>>>>>>>>>> lib/main.dart
class A {}

class B {}
>>>>>>>>>> lib/type_to_move.dart created
typedef TypeToMove = void Function();
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_variable() async {
    var originalSource = '''
class A {}


int variableT^oMove = 3;

class B {}
''';
    var declarationName = 'variableToMove';

    var expected = '''
>>>>>>>>>> lib/main.dart
class A {}

class B {}
>>>>>>>>>> lib/variable_to_move.dart created
int variableToMove = 3;
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> test_single_variable_firstDartDoc() async {
    var originalSource = '''
///
class ^A {}

class B {}
''';
    var declarationName = 'A';

    var expected = '''
>>>>>>>>>> lib/a.dart created
///
class A {}
>>>>>>>>>> lib/main.dart

class B {}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: declarationName,
    );
  }

  Future<void> _multipleDeclarations({
    required String originalSource,
    required int count,
    required String expected,
    String? otherFilePath,
    String? otherFileContent,
  }) async {
    await _refactor(
      originalSource: originalSource,
      expected: expected,
      actionTitle: 'Move $count declarations to file',
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
    );
  }

  Future<void> _refactor({
    required String originalSource,
    required String actionTitle,
    required String expected,
    String? otherFilePath,
    String? otherFileContent,
  }) async {
    if (originalSource.contains('>>>>') ||
        (otherFileContent?.contains('>>>>>') ?? false)) {
      throw '>>>>>';
    }
    addTestSource(originalSource);
    if (otherFilePath != null) {
      newFile(otherFilePath, otherFileContent!);
    }

    await initializeServer();
    final action = await expectCodeAction(actionTitle);
    await verifyCommandEdits(action.command!, expected);
  }

  Future<void> _singleDeclaration({
    required String originalSource,
    required String declarationName,
    required String expected,
    String? otherFilePath,
    String? otherFileContent,
  }) async {
    await _refactor(
      originalSource: originalSource,
      expected: expected,
      actionTitle: "Move '$declarationName' to file",
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
    );
  }

  /// Tests that prefixes are included in imports copied to the new code.
  ///
  /// [declarations] will be written to 'package:test/other.dart' which will
  /// be imported into [code] with the prefix 'other'.
  Future<void> _testPrefixCopied({
    required String declarations,
    required String movingCode,
    String movingDeclarationName = 'moving',
  }) async {
    var code = TestCode.parse(movingCode);
    var otherFilePath = '$projectFolderPath/lib/other.dart';
    var otherFileContent = declarations;

    var originalSource = '''
import 'package:test/other.dart' as other;

${code.rawCode}
''';

    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/other.dart' as other;
>>>>>>>>>> lib/moving.dart created
import 'package:test/other.dart' as other;

${code.code}
''';
    await _singleDeclaration(
      originalSource: originalSource,
      expected: expected,
      declarationName: movingDeclarationName,
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
    );
  }
}

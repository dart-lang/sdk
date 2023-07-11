// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
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

  /// Test that references to getter/setters in different libraries used in
  /// a compound assignment are both imported into the destination file.
  Future<void> test_compoundAssignment_multipleLibraries() async {
    addSource('$projectFolderPath/lib/getter.dart', '''
int get splitVariable => 0;
''');
    addSource('$projectFolderPath/lib/setter.dart', '''
set splitVariable(num _) {}
''');

    var originalSource = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void function^ToMove() {
  splitVariable += 1;
}
''';
    var modifiedSource = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';
''';
    var declarationName = 'functionToMove';
    var newFileName = 'function_to_move.dart';
    var newFileContent = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void functionToMove() {
  splitVariable += 1;
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_copyFileHeader() async {
    var originalSource = '''
// File header.

class A {}

class ClassToMove^ {}

class B {}
''';
    var modifiedSource = '''
// File header.

class A {}

class B {}
''';
    var declarationName = 'ClassToMove';
    var newFileName = 'class_to_move.dart';
    var newFileContent = '''
// File header.

class ClassToMove {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_existingFile() async {
    addTestSource(simpleClassContent);

    /// Existing new file contents where 'ClassToMove' will be moved to.
    final newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    addSource(newFilePath, '''
int? a;
''');

    /// Expected updated new file contents.
    const expectedNewFileContent = '''
int? a;

class A {}
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await executeRefactor(action);

    expect(content[newFilePath], expectedNewFileContent);
  }

  Future<void> test_existingFile_withHeader() async {
    addTestSource(simpleClassContent);

    /// Existing new file contents where 'ClassToMove' will be moved to.
    final newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    addSource(newFilePath, '''
// This is a file header

int? a;
''');

    /// Expected updated new file contents.
    const expectedNewFileContent = '''
// This is a file header

int? a;

class A {}
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await executeRefactor(action);

    expect(content[newFilePath], expectedNewFileContent);
  }

  Future<void> test_existingFile_withImports() async {
    addTestSource(simpleClassContent);

    /// Existing new file contents where 'ClassToMove' will be moved to.
    final newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    addSource(newFilePath, '''
import 'dart:async';

FutureOr<int>? a;
''');

    /// Expected updated new file contents.
    const expectedNewFileContent = '''
import 'dart:async';

FutureOr<int>? a;

class A {}
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await executeRefactor(action);

    expect(content[newFilePath], expectedNewFileContent);
  }

  Future<void> test_imports_declarationInSrc() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    addSource(libFilePath, 'export "src/a.dart";');
    addSource(srcFilePath, 'class A {}');
    var originalSource = '''
import 'package:test/a.dart';

A? staying;
A? mov^ing;
''';
    var modifiedSource = '''
import 'package:test/a.dart';

A? staying;
''';
    var declarationName = 'moving';
    var newFileName = 'moving.dart';
    var newFileContent = '''
import 'package:test/a.dart';

A? moving;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
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
    var modifiedSource = '''
import 'package:test/extensions.dart';

class A {}
''';
    var declarationName = 'f';
    var newFileName = 'f.dart';
    var newFileContent = '''
import 'package:test/extensions.dart';
import 'package:test/main.dart';

void f() {
  A().extensionMethod();
}
''';

    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
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
    var modifiedSource = '''
import 'package:test/extensions.dart';

class A {}
''';
    var declarationName = 'f';
    var newFileName = 'f.dart';
    var newFileContent = '''
import 'package:test/extensions.dart';
import 'package:test/main.dart';

void f() {
  A() + A();
}
''';

    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
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
    var modifiedSource = '''
import 'package:test/extensions.dart' as other;

class A {}
''';
    var movingDeclarationName = 'moving';
    var newFileName = 'moving.dart';
    var newFileContent = '''
import 'package:test/extensions.dart' as other;
import 'package:test/main.dart';

void moving() {
  A().extensionMethod();
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: movingDeclarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
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
    var modifiedSource = '''
import 'package:test/extensions.dart' as other;

class A {}
''';
    var movingDeclarationName = 'moving';
    var newFileName = 'moving.dart';
    var newFileContent = '''
import 'package:test/extensions.dart' as other;
import 'package:test/main.dart';

void moving() {
  A() + A();
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: movingDeclarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
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
    var modifiedSource = '''
import 'dart:io';

class A {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
import 'dart:io';

class B {
  File? f;
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_imports_referenceFromMovingToStaying() async {
    var originalSource = '''
class A {}

class ClassToMove^ extends A {}
''';
    var modifiedSource = '''
class A {}
''';
    var declarationName = 'ClassToMove';
    var newFileName = 'class_to_move.dart';
    var newFileContent = '''
import 'package:test/main.dart';

class ClassToMove extends A {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_imports_referenceFromStayingToMoving() async {
    var originalSource = '''
class A extends B {}

class B^ {}
''';
    var modifiedSource = '''
import 'package:test/b.dart';

class A extends B {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
class B {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_imports_referenceInThirdFile_noPrefix() async {
    var originalSource = '''
class A {}

class B^ {}
''';
    var modifiedSource = '''
class A {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
class B {}
''';
    var otherFilePath = '$projectFolderPath/lib/c.dart';
    var otherFileContent = '''
import 'package:test/main.dart';

B? b;
''';
    var modifiedOtherFileContent = '''
import 'package:test/b.dart';
import 'package:test/main.dart';

B? b;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent,
        modifiedOtherFileContent: modifiedOtherFileContent);
  }

  Future<void> test_imports_referenceInThirdFile_withMultiplePrefixes() async {
    var originalSource = '''
class A {}

class B^ {}
''';
    var modifiedSource = '''
class A {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
class B {}
''';
    var otherFilePath = '$projectFolderPath/lib/c.dart';
    var otherFileContent = '''
import 'package:test/main.dart';
import 'package:test/main.dart' as p;
import 'package:test/main.dart' as q;

void f(p.B b, q.B b, B b) {}
''';
    var modifiedOtherFileContent = '''
import 'package:test/b.dart';
import 'package:test/b.dart' as p;
import 'package:test/b.dart' as q;
import 'package:test/main.dart';
import 'package:test/main.dart' as p;
import 'package:test/main.dart' as q;

void f(p.B b, q.B b, B b) {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent,
        modifiedOtherFileContent: modifiedOtherFileContent);
  }

  Future<void> test_imports_referenceInThirdFile_withSinglePrefix() async {
    var originalSource = '''
class A {}

class B^ {}
''';
    var modifiedSource = '''
class A {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
class B {}
''';
    var otherFilePath = '$projectFolderPath/lib/c.dart';
    var otherFileContent = '''
import 'package:test/main.dart' as p;

p.B? b;
''';
    var modifiedOtherFileContent = '''
import 'package:test/b.dart' as p;
import 'package:test/main.dart' as p;

p.B? b;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent,
        modifiedOtherFileContent: modifiedOtherFileContent);
  }

  /// Test moving declarations to a file that imports a library that exports a
  /// referenced declaration, but currently hides it.
  Future<void> test_imports_showHide_destinationHides() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    var destinationFileName = 'moving.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    addSource(libFilePath, 'export "src/a.dart";');
    addSource(srcFilePath, 'class A {}');
    addSource(destinationFilePath, '''
import 'package:test/a.dart' hide A;
''');
    var originalSource = '''
import 'package:test/a.dart';

A? staying;
A? mov^ing;
''';
    var modifiedSource = '''
import 'package:test/a.dart';

A? staying;
''';
    var declarationName = 'moving';

    var expectedDestinationContent = '''
import 'package:test/a.dart' hide A;
import 'package:test/a.dart';

A? moving;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: destinationFileName,
        newFileContent: expectedDestinationContent);
  }

  /// Test moving declarations to a file that imports a library that exports a
  /// referenced declaration, but currently hides it.
  Future<void> test_imports_showHide_destinationHides_sourceShows() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    var destinationFileName = 'moving.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    addSource(libFilePath, 'export "src/a.dart";');
    addSource(srcFilePath, 'class A {}');
    addSource(destinationFilePath, '''
import 'package:test/a.dart' hide A;
''');
    var originalSource = '''
import 'package:test/a.dart' show A;

A? staying;
A? mov^ing;
''';
    var modifiedSource = '''
import 'package:test/a.dart' show A;

A? staying;
''';
    var declarationName = 'moving';

    var expectedDestinationContent = '''
import 'package:test/a.dart' hide A;
import 'package:test/a.dart' show A;

A? moving;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: destinationFileName,
        newFileContent: expectedDestinationContent);
  }

  /// Test that if the moving declaration was imported with 'show' that any new
  /// import added to the destination also only shows it.
  Future<void> test_imports_showHide_sourceShows() async {
    var libFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var srcFilePath = join(projectFolderPath, 'lib', 'src', 'a.dart');
    addSource(libFilePath, 'export "src/a.dart";');
    addSource(srcFilePath, 'class A {}');
    var originalSource = '''
import 'package:test/a.dart' show A;

A? staying;
A? mov^ing;
''';
    var modifiedSource = '''
import 'package:test/a.dart' show A;

A? staying;
''';
    var declarationName = 'moving';
    var newFileName = 'moving.dart';
    var newFileContent = '''
import 'package:test/a.dart' show A;

A? moving;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_kind_class() async {
    var originalSource = '''
class A {}

class ClassToMove^ {}

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'ClassToMove';
    var newFileName = 'class_to_move.dart';
    var newFileContent = '''
class ClassToMove {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
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
    var modifiedSource = '''
class A {}

class B {}
''';
    var newFileName = 'class_to_move1.dart';
    var newFileContent = '''
class ClassToMove1 {}

class ClassToMove2 {}
''';
    await _multipleDeclarations(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        count: 2,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_none_comment() async {
    addTestSource('''
// Comm^ent

class A {}
''');
    await initializeServer(experimentalOptInFlag: false);
    await expectNoCodeAction(null);
  }

  Future<void> test_none_directive() async {
    addTestSource('''
imp^ort 'dart:core';

class A {}
''');
    await initializeServer(experimentalOptInFlag: false);
    await expectNoCodeAction(null);
  }

  /// Test that references to getter/setters in different libraries used in
  /// a postfix increment are both imported into the destination file.
  Future<void> test_postfixIncrement_multipleLibraries() async {
    addSource('$projectFolderPath/lib/getter.dart', '''
int get splitVariable => 0;
''');
    addSource('$projectFolderPath/lib/setter.dart', '''
set splitVariable(num _) {}
''');

    var originalSource = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void function^ToMove() {
  splitVariable++;
}
''';
    var modifiedSource = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';
''';
    var declarationName = 'functionToMove';
    var newFileName = 'function_to_move.dart';
    var newFileContent = '''
import 'package:test/getter.dart';
import 'package:test/setter.dart';

void functionToMove() {
  splitVariable++;
}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
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
    await initializeServer(commandParameterSupportedKinds: null);
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
    const expectedNewFileContent = '''
class A {}
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    // Replace the file URI argument with our custom path.
    replaceSaveUriArgument(action, newFileUri);
    await executeRefactor(action);

    expect(content[newFilePath], expectedNewFileContent);
  }

  Future<void> test_protocol_unavailable_withoutFileCreateSupport() async {
    addTestSource(simpleClassContent);
    await initializeServer(fileCreateSupport: false);
    await expectNoCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_sealedClass_extends() async {
    var originalSource = '''
sealed class [!Either!] {}

class Left extends Either {}
class Right extends Either {}

class Neither {}
''';
    var modifiedSource = '''

class Neither {}
''';
    var newFileName = 'either.dart';
    var newFileContent = '''
sealed class Either {}

class Left extends Either {}
class Right extends Either {}
''';
    await _multipleDeclarations(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        count: 3,
        newFileName: newFileName,
        newFileContent: newFileContent);
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

    addSource(otherFilePath, otherFileContent);

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
    var modifiedSource = '''
import 'package:test/either.dart';


class LeftSub extends Left {}

class Neither {}
''';
    var newFileName = 'either.dart';
    var newFileContent = '''
sealed class Either {}

class Left extends Either {}
class Right extends Either {}
''';
    await _multipleDeclarations(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        count: 3,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_sealedClass_extends_superclassAndSubclass() async {
    var originalSource = '''
sealed class [!Either {}

class Left!] extends Either {}
class Right extends Either {}

class Neither {}
''';
    var modifiedSource = '''

class Neither {}
''';
    var newFileName = 'either.dart';
    var newFileContent = '''
sealed class Either {}

class Left extends Either {}
class Right extends Either {}
''';
    await _multipleDeclarations(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        count: 3,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_sealedClass_implements() async {
    var originalSource = '''
sealed class [!Either!] {}

class Left implements Either {}
class Right implements Either {}

class Neither {}
''';
    var modifiedSource = '''

class Neither {}
''';
    var newFileName = 'either.dart';
    var newFileContent = '''
sealed class Either {}

class Left implements Either {}
class Right implements Either {}
''';
    await _multipleDeclarations(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        count: 3,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_sealedClass_sealedSubclass_extends_superclass() async {
    var originalSource = '''
sealed class [!SealedRoot!] {}

class Subclass extends SealedRoot {}
sealed class SealedSubclass extends SealedRoot {}

class SubSubclass extends SealedSubclass {}

class SubSubSubclass extends SubSubclass {}
''';
    var modifiedSource = '''
import 'package:test/sealed_root.dart';


class SubSubSubclass extends SubSubclass {}
''';
    var newFileName = 'sealed_root.dart';
    var newFileContent = '''
sealed class SealedRoot {}

class Subclass extends SealedRoot {}
sealed class SealedSubclass extends SealedRoot {}

class SubSubclass extends SealedSubclass {}
''';
    await _multipleDeclarations(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        count: 4,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_class_withTypeParameters() async {
    var originalSource = '''
class A {}

class ClassToMove^<T> {}

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'ClassToMove';
    var newFileName = 'class_to_move.dart';
    var newFileContent = '''
class ClassToMove<T> {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_enum() async {
    var originalSource = '''
class A {}

enum EnumToMove^ { a, b }

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'EnumToMove';
    var newFileName = 'enum_to_move.dart';
    var newFileContent = '''
enum EnumToMove { a, b }
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_extension() async {
    var originalSource = '''
class A {}

extension ExtensionToMove^ on int { }

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'ExtensionToMove';
    var newFileName = 'extension_to_move.dart';
    var newFileContent = '''
extension ExtensionToMove on int { }
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_function_endOfName() async {
    var originalSource = '''
class A {}

void functionToMove^() { }

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'functionToMove';
    var newFileName = 'function_to_move.dart';
    var newFileContent = '''
void functionToMove() { }
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_function_middleOfName() async {
    var originalSource = '''
class A {}

void functionToMo^ve() { }

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'functionToMove';
    var newFileName = 'function_to_move.dart';
    var newFileContent = '''
void functionToMove() { }
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_mixin() async {
    var originalSource = '''
class A {}

mixin MixinToMove^ { }

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'MixinToMove';
    var newFileName = 'mixin_to_move.dart';
    var newFileContent = '''
mixin MixinToMove { }
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_parts_libraryToPart() async {
    var originalSource = '''
part 'class_to_move.dart';

class Clas^sToMove {}
''';
    var modifiedSource = '''
part 'class_to_move.dart';
''';
    var declarationName = 'ClassToMove';
    var destinationFileName = 'class_to_move.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    addSource(destinationFilePath, '''
part of 'main.dart';
''');
    var destinationFileContent = '''
part of 'main.dart';

class ClassToMove {}
''';

    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: destinationFileName,
        newFileContent: destinationFileContent);
  }

  Future<void> test_single_parts_partToLibrary() async {
    var originalSource = '''
part of 'class_to_move.dart';

class Clas^sToMove {}
''';
    var modifiedSource = '''
part of 'class_to_move.dart';
''';
    var declarationName = 'ClassToMove';
    var destinationFileName = 'class_to_move.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    addSource(destinationFilePath, '''
part 'main.dart';
''');
    var destinationFileContent = '''
part 'main.dart';

class ClassToMove {}
''';

    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: destinationFileName,
        newFileContent: destinationFileContent);
  }

  Future<void> test_single_parts_partToPart() async {
    var originalSource = '''
part of 'containing_library.dart';

class Clas^sToMove {}
''';
    var modifiedSource = '''
part of 'containing_library.dart';
''';
    var declarationName = 'ClassToMove';
    var destinationFileName = 'class_to_move.dart';
    var destinationFilePath =
        join(projectFolderPath, 'lib', destinationFileName);
    addSource(destinationFilePath, '''
part of 'containing_library.dart';
''');
    var destinationFileContent = '''
part of 'containing_library.dart';

class ClassToMove {}
''';
    var containingLibraryFilePath =
        join(projectFolderPath, 'lib', 'containing_library.dart');
    var containingLibraryFileContent = '''
part 'main.dart';
part 'class_to_move.dart';
''';

    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: destinationFileName,
        newFileContent: destinationFileContent,
        otherFilePath: containingLibraryFilePath,
        otherFileContent: containingLibraryFileContent);
  }

  Future<void> test_single_typedef() async {
    var originalSource = '''
class A {}

typedef TypeToMove^ = void Function();

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'TypeToMove';
    var newFileName = 'type_to_move.dart';
    var newFileContent = '''
typedef TypeToMove = void Function();
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_variable() async {
    var originalSource = '''
class A {}

int variableT^oMove = 3;

class B {}
''';
    var modifiedSource = '''
class A {}

class B {}
''';
    var declarationName = 'variableToMove';
    var newFileName = 'variable_to_move.dart';
    var newFileContent = '''
int variableToMove = 3;
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_single_variable_firstDartDoc() async {
    var originalSource = '''
///
class ^A {}

class B {}
''';
    var modifiedSource = '''

class B {}
''';
    var declarationName = 'A';
    var newFileName = 'a.dart';
    var newFileContent = '''
///
class A {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> _multipleDeclarations(
      {required String originalSource,
      required String modifiedSource,
      required int count,
      required String newFileName,
      required String newFileContent,
      String? otherFilePath,
      String? otherFileContent,
      String? modifiedOtherFileContent}) async {
    await _refactor(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        actionTitle: "Move $count declarations to file",
        newFileName: newFileName,
        newFileContent: newFileContent,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent,
        modifiedOtherFileContent: modifiedOtherFileContent);
  }

  Future<void> _refactor(
      {required String originalSource,
      required String modifiedSource,
      required String actionTitle,
      required String newFileName,
      required String newFileContent,
      String? otherFilePath,
      String? otherFileContent,
      String? modifiedOtherFileContent}) async {
    addTestSource(originalSource);
    if (otherFilePath != null) {
      addSource(otherFilePath, otherFileContent!);
    }

    /// Expected new file path/content.
    final expectedNewFilePath = join(projectFolderPath, 'lib', newFileName);

    await initializeServer();
    final action = await expectCodeAction(actionTitle);
    await executeRefactor(action);

    expect(content[mainFilePath], modifiedSource);
    // Check the new file was added to `content`. If no CreateFile resource
    // was sent, the executeRefactor helper would've thrown when trying to
    // apply the changes.
    expect(content[expectedNewFilePath], newFileContent);
    if (modifiedOtherFileContent != null) {
      expect(content[convertPath(otherFilePath!)], modifiedOtherFileContent);
    }
  }

  Future<void> _singleDeclaration(
      {required String originalSource,
      required String modifiedSource,
      required String declarationName,
      required String newFileName,
      required String newFileContent,
      String? otherFilePath,
      String? otherFileContent,
      String? modifiedOtherFileContent}) async {
    await _refactor(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        actionTitle: "Move '$declarationName' to file",
        newFileName: newFileName,
        newFileContent: newFileContent,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent,
        modifiedOtherFileContent: modifiedOtherFileContent);
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
    var modifiedSource = '''
import 'package:test/other.dart' as other;
''';
    var newFileName = 'moving.dart';
    var newFileContent = '''
import 'package:test/other.dart' as other;

${code.code}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: movingDeclarationName,
        newFileName: newFileName,
        newFileContent: newFileContent,
        otherFilePath: otherFilePath,
        otherFileContent: otherFileContent);
  }
}

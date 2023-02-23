// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
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
class A {}
int? a;
''';

    await initializeServer();
    final action = await expectCodeAction(simpleClassRefactorTitle);
    await executeRefactor(action);

    expect(content[newFilePath], expectedNewFileContent);
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

  @failingTest
  Future<void> test_imports_referenceInThirdFile_withMultiplePrefixes() async {
    // This fails for two reasons:
    // 1. The indexer isn't recording when a top-level element is referenced
    //    without a prefix.
    // 2. The method `DartFileEditBuilderImpl._importLibrary` doesn't support
    //    importing the same URI with multiple prefixes.
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

  Future<void> test_protocol_unavailable_withoutExperimentalOptIn() async {
    addTestSource(simpleClassContent);
    await initializeServer(experimentalOptInFlag: false);
    await expectNoCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_protocol_unavailable_withoutFileCreateSupport() async {
    addTestSource(simpleClassContent);
    await initializeServer(fileCreateSupport: false);
    await expectNoCodeAction(simpleClassRefactorTitle);
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
}

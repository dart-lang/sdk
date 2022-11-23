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
  static const simpleClassContent = 'class ^A {}';

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

  Future<void> test_available() async {
    addTestSource(simpleClassContent);
    await initializeServer();
    await expectCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_available_withoutClientCommandParameterSupport() async {
    addTestSource(simpleClassContent);
    await initializeServer(commandParameterSupportedKinds: null);
    // This refactor is available without command parameter support because
    // it has defaults.
    await expectCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_class() async {
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

  Future<void> test_clientModifiedValues() async {
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

  Future<void> test_enum() async {
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

  Future<void> test_extension() async {
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

  Future<void> test_function() async {
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

  Future<void> test_imports_referenceFromMovingToImported() async {
    var originalSource = '''
// File header.

import 'dart:io';

class A {}

class B^ {
  File? f;
}
''';
    var modifiedSource = '''
// File header.

import 'dart:io';

class A {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
import 'dart:io';

// File header.

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
// File header.

class A {}

class ClassToMove^ extends A {}
''';
    var modifiedSource = '''
// File header.

class A {}
''';
    var declarationName = 'ClassToMove';
    var newFileName = 'class_to_move.dart';
    var newFileContent = '''
import 'package:test/main.dart';

// File header.

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
// File header.

class A extends B {}

class B^ {}
''';
    var modifiedSource = '''
// File header.

import 'package:test/b.dart';

class A extends B {}
''';
    var declarationName = 'B';
    var newFileName = 'b.dart';
    var newFileContent = '''
// File header.

class B {}
''';
    await _singleDeclaration(
        originalSource: originalSource,
        modifiedSource: modifiedSource,
        declarationName: declarationName,
        newFileName: newFileName,
        newFileContent: newFileContent);
  }

  Future<void> test_mixin() async {
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

  Future<void> test_typedef() async {
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

  Future<void> test_unavailable_withoutExperimentalOptIn() async {
    addTestSource(simpleClassContent);
    await initializeServer(experimentalOptInFlag: false);
    await expectNoCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_unavailable_withoutFileCreateSupport() async {
    addTestSource(simpleClassContent);
    await initializeServer(fileCreateSupport: false);
    await expectNoCodeAction(simpleClassRefactorTitle);
  }

  Future<void> test_variable() async {
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

  Future<void> _singleDeclaration(
      {required String originalSource,
      required String modifiedSource,
      required String declarationName,
      required String newFileName,
      required String newFileContent}) async {
    addTestSource(originalSource);

    /// Expected new file path/content.
    final expectedNewFilePath = join(projectFolderPath, 'lib', newFileName);

    await initializeServer();
    final action = await expectCodeAction("Move '$declarationName' to file");
    await executeRefactor(action);

    expect(content[mainFilePath], modifiedSource);
    // Check the new file was added to `content`. If no CreateFile resource
    // was sent, the executeRefactor helper would've thrown when trying to
    // apply the changes.
    expect(content[expectedNewFilePath], newFileContent);
  }
}

// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveTopLevelToFileTest);
  });
}

@reflectiveTest
class MoveTopLevelToFileTest extends RefactoringTest {
  @override
  String get refactoringName => MoveTopLevelToFile.commandName;

  Future<void> test_class() async {
    addTestSource('''
class ClassToStay {}

class ClassToMove^ {}
''');
    await assertRefactoring({
      mainFilePath: '''
class ClassToStay {}
''',
      join(projectFolderPath, 'lib', 'class_to_move.dart'): '''
class ClassToMove {}
''',
    });
  }
}

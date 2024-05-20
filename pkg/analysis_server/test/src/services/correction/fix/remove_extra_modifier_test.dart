// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveExtraModifierMultiTest);
    defineReflectiveTests(RemoveExtraModifierTest);
  });
}

@reflectiveTest
class RemoveExtraModifierMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EXTRA_MODIFIER_MULTI;

  Future<void> test_singleFile() async {
    newFile('$testPackageLibPath/a.dart', '''
import augment 'test.dart';

class A { }
''');

    await resolveTestCode('''
augment library 'a.dart';

augment abstract class A {}

augment final class A {}
''');
    await assertHasFixAllFix(
        CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, '''
augment library 'a.dart';

augment class A {}

augment class A {}
''');
  }
}

@reflectiveTest
class RemoveExtraModifierTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EXTRA_MODIFIER;

  test_invalidAsyncConstructorModifier() async {
    await resolveTestCode(r'''
class A {
  A() async {}
}
''');
    await assertHasFix('''
class A {
  A() {}
}
''');
  }

  Future<void> test_it() async {
    newFile('$testPackageLibPath/a.dart', '''
import augment 'test.dart';

class A { }
''');

    await resolveTestCode('''
augment library 'a.dart';

augment abstract class A {}
''');
    await assertHasFix('''
augment library 'a.dart';

augment class A {}
''');
  }
}

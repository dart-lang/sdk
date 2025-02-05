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
    defineReflectiveTests(RemoveExtendsClauseMultiTest);
    defineReflectiveTests(RemoveExtendsClauseTest);
  });
}

@reflectiveTest
class RemoveExtendsClauseMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EXTENDS_CLAUSE_MULTI;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {}
mixin class B extends A {}
mixin class C extends A {}
''');
    await assertHasFixAllFix(
      CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT,
      '''
class A {}
mixin class B {}
mixin class C {}
''',
    );
  }
}

@reflectiveTest
class RemoveExtendsClauseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EXTENDS_CLAUSE;

  Future<void> test_mixinClass_extends_class() async {
    await resolveTestCode('''
class A {}
mixin class B extends A {}
''');
    await assertHasFix('''
class A {}
mixin class B {}
''');
  }
}

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
    defineReflectiveTests(AddEmptyArgumentListTest);
    defineReflectiveTests(AddEmptyArgumentListMultiTest);
  });
}

@reflectiveTest
class AddEmptyArgumentListMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_EMPTY_ARGUMENT_LIST_MULTI;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  const A();
}
@A
@A
main() {}
''');
    await assertHasFixAllFix(
        CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, '''
class A {
  const A();
}
@A()
@A()
main() {}
''');
  }
}

@reflectiveTest
class AddEmptyArgumentListTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_EMPTY_ARGUMENT_LIST;

  Future<void> test_annotationConstructorMissingArgs() async {
    await resolveTestCode('''
class A {
  const A();
}
@A
main() {}
''');
    await assertHasFix('''
class A {
  const A();
}
@A()
main() {}
''');
  }
}

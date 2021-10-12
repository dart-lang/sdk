// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstructorNameBulkTest);
    defineReflectiveTests(RemoveConstructorNameInFileTest);
    defineReflectiveTests(RemoveConstructorNameTest);
  });
}

@reflectiveTest
class RemoveConstructorNameBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_constructor_name;

  Future<void> test_singleFile() async {
    await resolveTestCode(r'''
class A {
  A.new(int x) {
    print('new: $x');
  }
}
var a = A.new(3);
''');
    await assertHasFix(r'''
class A {
  A(int x) {
    print('new: $x');
  }
}
var a = A(3);
''');
  }
}

@reflectiveTest
class RemoveConstructorNameInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.unnecessary_constructor_name]);
    await resolveTestCode(r'''
class A {
  A.new(int x) {
    print('new: $x');
  }
}
var a = A.new(3);
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
class A {
  A(int x) {
    print('new: $x');
  }
}
var a = A(3);
''');
  }
}

@reflectiveTest
class RemoveConstructorNameTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONSTRUCTOR_NAME;

  @override
  String get lintCode => LintNames.unnecessary_constructor_name;

  Future<void> test_constructorDeclaration() async {
    await resolveTestCode(r'''
class A {
  A.new(int x) {
    print('new: $x');
  }
}
''');
    await assertHasFix(r'''
class A {
  A(int x) {
    print('new: $x');
  }
}
''');
  }

  Future<void> test_constructorInvocation() async {
    await resolveTestCode(r'''
class A { }
var a = A.new();
''');
    await assertHasFix(r'''
class A { }
var a = A();
''');
  }
}

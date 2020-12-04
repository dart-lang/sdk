// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableBazelWorkspaceTest);
  });
}

@reflectiveTest
class NonNullableBazelWorkspaceTest extends BazelWorkspaceResolutionTest {
  @override
  bool get typeToStringWithNullability => true;

  test_buildFile_legacy_commentedOut() async {
    newFile('$myPackageRootPath/BUILD', content: r'''
dart_package(
#  null_safety = True,
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.typeName('int v'), 'int*');
  }

  test_buildFile_nonNullable() async {
    newFile('$myPackageRootPath/BUILD', content: r'''
dart_package(
  null_safety = True,
)
''');

    // Non-nullable in lib/.
    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.typeName('int v'), 'int');

    // Non-nullable in test/.
    await resolveFileCode(
      '$myPackageRootPath/test/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.typeName('int v'), 'int');

    // Non-nullable in bin/.
    await resolveFileCode(
      '$myPackageRootPath/bin/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.typeName('int v'), 'int');
  }

  test_buildFile_nonNullable_oneLine_noComma() async {
    newFile('$myPackageRootPath/BUILD', content: r'''
dart_package(null_safety = True)
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.typeName('int v'), 'int');
  }

  test_buildFile_nonNullable_withComments() async {
    newFile('$myPackageRootPath/BUILD', content: r'''
dart_package(
  # Preceding comment.
  null_safety = True,  # Trailing comment.
)  # Last comment.
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.typeName('int v'), 'int');
  }

  test_noBuildFile_legacy() async {
    await assertNoErrorsInCode('''
int v = 0;
''');

    assertType(findNode.typeName('int v'), 'int*');
  }
}

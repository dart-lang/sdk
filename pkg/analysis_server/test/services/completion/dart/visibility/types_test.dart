// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../completion_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionVisibilityTest);
  });
}

@reflectiveTest
class CompletionVisibilityTest extends CompletionTestCase {
  Future<void> test_imported() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
import 'lib.dart';

C^
''');
    assertHasCompletion('C');
  }

  Future<void> test_imported_localAndMultiplePrefixes() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
import 'lib.dart' as l1;
import 'lib.dart' as l2;

class C {}

C^
''');
    assertHasCompletion('C');
    assertHasCompletion('l1.C');
    assertHasCompletion('l2.C');
  }

  Future<void> test_imported_localAndUnprefixed() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
import 'lib.dart';

class C {}

C^
''');
    // Verify exactly one, and it was the local one.
    assertHasCompletion('C', libraryUri: isNull);
  }

  Future<void> test_imported_multiplePrefixes() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
import 'lib.dart' as l1;
import 'lib.dart' as l2;

C^
''');
    assertHasCompletion('l1.C');
    assertHasCompletion('l2.C');
  }

  Future<void> test_imported_prefix() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
import 'lib.dart' as l;

C^
''');
    assertHasCompletion('l.C');
  }

  Future<void> test_local() async {
    await getTestCodeSuggestions('''
class C {}

C^
''');
    assertHasCompletion('C');
  }

  Future<void> test_localAndNotImported() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
class C {}

C^
''');
    // This verifies exactly one, since we won't suggest the not-imported
    // when it matches a local name.
    assertHasCompletion('C');
  }

  Future<void> test_notImported() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
class C {}
''');
    await getTestCodeSuggestions('''
C^
''');
    assertHasCompletion('C');
  }
}

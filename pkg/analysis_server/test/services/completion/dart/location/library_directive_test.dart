// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectiveTest);
  });
}

@reflectiveTest
class LibraryDirectiveTest extends AbstractCompletionDriverTest
    with LibraryDirectiveTestCases {}

mixin LibraryDirectiveTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLibrary_beforeEnd() async {
    await computeSuggestions('''
library ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLibrary_beforeEnd_partial() async {
    await computeSuggestions('''
library a^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterPeriod_beforeEnd() async {
    await computeSuggestions('''
library a.^
''');
    assertResponse(r'''
suggestions
''');
  }
}

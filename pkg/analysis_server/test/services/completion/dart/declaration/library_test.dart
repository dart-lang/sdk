// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryTest);
  });
}

@reflectiveTest
class LibraryTest extends AbstractCompletionDriverTest with LibraryTestCases {}

mixin LibraryTestCases on AbstractCompletionDriverTest {
  Future<void> test_dart_noInternalLibraries() async {
    await computeSuggestions('''
void f() {
  ^
}
''');

    for (var suggestion in response.suggestions) {
      var libraryUri = suggestion.libraryUri;
      if (libraryUri != null && libraryUri.startsWith('dart:_')) {
        fail('Private SDK library: $libraryUri');
      }
    }
  }
}

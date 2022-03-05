// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryTest1);
    defineReflectiveTests(LibraryTest2);
  });
}

mixin EnumTestCases on AbstractCompletionDriverTest {
  Future<void> test_dart_noInternalLibraries() async {
    var response = await getTestCodeSuggestions('''
void f() {
  ^
}
''');

    check(response).suggestions.excludesAll([
      (suggestion) => suggestion.libraryUri.isNotNull.startsWith('dart:_'),
    ]);
  }
}

@reflectiveTest
class LibraryTest1 extends AbstractCompletionDriverTest with EnumTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LibraryTest2 extends AbstractCompletionDriverTest with EnumTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

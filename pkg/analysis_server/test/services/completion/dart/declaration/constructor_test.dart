// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorTest1);
    defineReflectiveTests(ConstructorTest2);
  });
}

@reflectiveTest
class ConstructorTest1 extends AbstractCompletionDriverTest
    with ConstructorTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ConstructorTest2 extends AbstractCompletionDriverTest
    with ConstructorTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ConstructorTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        final completion = suggestion.completion;
        return completion.contains('Foo');
      },
    );
  }

  Future<void> test_sealed_library() async {
    newFile('$testPackageLibPath/a.dart', 'sealed class FooSealed {}');
    await computeSuggestions('''
import 'a.dart';
void f() {
  var x = new ^
}
''');

    if (isProtocolVersion1) {
      assertResponse('''
suggestions
  FooSealed
    kind: constructorInvocation
''');
    } else {
      assertResponse('''
suggestions
''');
    }
  }

  Future<void> test_sealed_local() async {
    await computeSuggestions('''
sealed class FooSealed {}
void f() {
  var x = new ^
}
''');

    assertResponse('''
suggestions
''');
  }
}

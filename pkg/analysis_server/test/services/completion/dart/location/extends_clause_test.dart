// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsClauseTest1);
    defineReflectiveTests(ExtendsClauseTest2);
  });
}

@reflectiveTest
class ExtendsClauseTest1 extends AbstractCompletionDriverTest
    with ExtendsClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ExtendsClauseTest2 extends AbstractCompletionDriverTest
    with ExtendsClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ExtendsClauseTestCases on AbstractCompletionDriverTest {
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

  Future<void> test_class_inside() async {
    await computeSuggestions('''
base class FooBase {}
interface class FooInterface {}
final class FooFinal {}
sealed class FooSealed {}
class A extends ^
''');

    assertResponse('''
suggestions
  FooBase
    kind: class
  FooFinal
    kind: class
  FooInterface
    kind: class
  FooSealed
    kind: class
''');
  }

  Future<void> test_class_outside_base() async {
    newFile('$testPackageLibPath/a.dart', 'base class Foo {}');
    await computeSuggestions('''
import 'a.dart';
class A extends ^
''');

    assertResponse('''
suggestions
  Foo
    kind: class
''');
  }

  Future<void> test_class_outside_final() async {
    newFile('$testPackageLibPath/a.dart', 'final class Foo {}');
    await computeSuggestions('''
lib B;
import 'a.dart';
class A extends ^
''');

    if (isProtocolVersion1) {
      assertResponse('''
suggestions
  Foo
    kind: class
''');
    } else {
      assertResponse('''
suggestions
''');
    }
  }

  Future<void> test_class_outside_interface() async {
    newFile('$testPackageLibPath/a.dart', 'interface class Foo {}');
    await computeSuggestions('''
lib B;
import 'a.dart';
class A extends ^
''');

    if (isProtocolVersion1) {
      assertResponse('''
suggestions
  Foo
    kind: class
''');
    } else {
      assertResponse('''
suggestions
''');
    }
  }

  Future<void> test_class_outside_sealed() async {
    newFile('$testPackageLibPath/a.dart', 'sealed class Foo {}');
    await computeSuggestions('''
lib B;
import 'a.dart';
class A extends ^
''');

    if (isProtocolVersion1) {
      assertResponse('''
suggestions
  Foo
    kind: class
''');
    } else {
      assertResponse('''
suggestions
''');
    }
  }
}

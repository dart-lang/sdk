// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsClauseTest1);
    defineReflectiveTests(ImplementsClauseTest2);
  });
}

@reflectiveTest
class ImplementsClauseTest1 extends AbstractCompletionDriverTest
    with ImplementsClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ImplementsClauseTest2 extends AbstractCompletionDriverTest
    with ImplementsClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ImplementsClauseTestCases on AbstractCompletionDriverTest {
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
class A implements ^
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
class A implements ^
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

  Future<void> test_class_outside_final() async {
    newFile('$testPackageLibPath/a.dart', 'final class Foo {}');
    await computeSuggestions('''
lib B;
import 'a.dart';
class A implements ^
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
class A implements ^
''');

    assertResponse('''
suggestions
  Foo
    kind: class
''');
  }

  Future<void> test_class_outside_sealed() async {
    newFile('$testPackageLibPath/a.dart', 'sealed class Foo {}');
    await computeSuggestions('''
lib B;
import 'a.dart';
class A implements ^
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

  Future<void> test_mixin_inside() async {
    await computeSuggestions('''
base mixin FooBase {}
class A implements ^
''');

    assertResponse('''
suggestions
  FooBase
    kind: mixin
''');
  }

  Future<void> test_mixin_outside_base() async {
    newFile('$testPackageLibPath/a.dart', 'base mixin Foo {}');
    await computeSuggestions('''
import 'a.dart';
class A implements ^
''');

    if (isProtocolVersion1) {
      assertResponse('''
suggestions
  Foo
    kind: mixin
''');
    } else {
      assertResponse('''
suggestions
''');
    }
  }
}

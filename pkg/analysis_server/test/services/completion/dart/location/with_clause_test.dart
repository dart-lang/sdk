// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WithClauseTest1);
    defineReflectiveTests(WithClauseTest2);
  });
}

@reflectiveTest
class WithClauseTest1 extends AbstractCompletionDriverTest
    with WithClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class WithClauseTest2 extends AbstractCompletionDriverTest
    with WithClauseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin WithClauseTestCases on AbstractCompletionDriverTest {
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
class A with ^
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

  Future<void> test_class_outside() async {
    newFile('$testPackageLibPath/a.dart', '''
base class FooBase {}
interface class FooInterface {}
final class FooFinal {}
sealed class FooSealed {}
''');
    await computeSuggestions('''
import 'a.dart';
class A with ^
''');

    if (isProtocolVersion1) {
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
    } else {
      assertResponse('''
suggestions
''');
    }
  }

  Future<void> test_mixin_base_inside() async {
    await computeSuggestions('''
base mixin FooBase {}
class A with ^
''');

    assertResponse('''
suggestions
  FooBase
    kind: mixin
''');
  }

  Future<void> test_mixin_base_outside() async {
    newFile('$testPackageLibPath/a.dart', 'base mixin Foo {}');
    await computeSuggestions('''
import 'a.dart';
class A with ^
''');

    assertResponse('''
suggestions
  Foo
    kind: mixin
''');
  }

  Future<void> test_mixinClass_base_inside() async {
    await computeSuggestions('''
base mixin class FooBaseMixinClass {}
mixin class FooMixinClass {}
class A with ^
''');

    assertResponse('''
suggestions
  FooBaseMixinClass
    kind: class
  FooMixinClass
    kind: class
''');
  }

  Future<void> test_mixinClass_base_outside() async {
    newFile('$testPackageLibPath/a.dart', '''
base mixin class FooBaseMixinClass {}
mixin class FooMixinClass {}
''');
    await computeSuggestions('''
import 'a.dart';
class A with ^
''');

    assertResponse('''
suggestions
  FooBaseMixinClass
    kind: class
  FooMixinClass
    kind: class
''');
  }
}

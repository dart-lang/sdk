// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassStaticMembersWithoutClassNameTest);
  });
}

@reflectiveTest
class ClassStaticMembersWithoutClassNameTest
    extends AbstractCompletionDriverTest with _Helpers {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        final completion = suggestion.completion;
        return completion.contains('foo0');
      },
    );
  }

  Future<void> test_field_hasContextType_exact() async {
    await _checkLocations(
      classCode: r'''
class A {
  static final int foo01 = 0;
  static final num foo02 = 0;
  static final double foo03 = 0;
  final int foo04 = 0;
}
''',
      contextCode: r'''
void f() {
  int a = foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
  A.foo01
    kind: field
''');
      },
    );
  }

  Future<void> test_field_hasContextType_subtypes() async {
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    await _checkLocations(
      classCode: r'''
class A {
  static final int foo01 = 0;
  static final double foo02 = 0;
  static final num foo03 = 0;
  static final Object foo04 = '';
}
''',
      contextCode: r'''
void f() {
  num a = foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
  A.foo03
    kind: field
  A.foo01
    kind: field
  A.foo02
    kind: field
''');
      },
    );
  }

  Future<void> test_field_noContextType() async {
    await _checkLocations(
      classCode: r'''
class A {
  static final foo01 = 0;
  static final foo02 = 0;
  final foo03 = 0;
}
''',
      contextCode: r'''
void f() {
  foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
''');
      },
    );
  }

  Future<void> test_getter_hasContextType_exact() async {
    await _checkLocations(
      classCode: r'''
class A {
  static int get foo01 => 0;
  static num get foo02 => 0;
  static double get foo03 => 0;
}
''',
      contextCode: r'''
void f() {
  int a = foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
  A.foo01
    kind: getter
''');
      },
    );
  }

  Future<void> test_getter_hasContextType_subtypes() async {
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    await _checkLocations(
      classCode: r'''
class A {
  static int get foo01 => 0;
  static double get foo02 => 0;
  static num get foo03 => 0;
  static Object get foo04 => '';
}
''',
      contextCode: r'''
void f() {
  num a = foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
  A.foo03
    kind: getter
  A.foo01
    kind: getter
  A.foo02
    kind: getter
''');
      },
    );
  }

  Future<void> test_getter_noContextType() async {
    await _checkLocations(
      classCode: r'''
class A {
  static int get foo01 => 0;
}
''',
      contextCode: r'''
void f() {
  foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
''');
      },
    );
  }

  Future<void> test_method() async {
    await _checkLocations(
      classCode: r'''
class A {
  static void foo01() {}
}
''',
      contextCode: r'''
void f() {
  foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
''');
      },
    );
  }

  Future<void> test_setter_hasContextType() async {
    await _checkLocations(
      classCode: r'''
class A {
  static set foo01(int _) {}
  static set foo02(num _) {}
  static set foo03(double _) {}
}
''',
      contextCode: r'''
void f() {
  int a = foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
''');
      },
    );
  }

  Future<void> test_setter_noContextType() async {
    await _checkLocations(
      classCode: r'''
class A {
  static set foo01(int _) {}
}
''',
      contextCode: r'''
void f() {
  foo0^
}
''',
      validator: () {
        assertResponse(r'''
replacement
  left: 4
suggestions
''');
      },
    );
  }
}

mixin _Helpers on AbstractCompletionDriverTest {
  Future<void> _checkLocations({
    required String classCode,
    required String contextCode,
    required void Function() validator,
  }) async {
    // local
    {
      await computeSuggestions('''
$classCode

$contextCode
''');
      validator();
    }

    // imported, without prefix
    {
      newFile('$testPackageLibPath/a.dart', classCode);
      await computeSuggestions('''
import 'a.dart';

$contextCode
''');
      validator();
    }

    // not imported
    {
      newFile('$testPackageLibPath/a.dart', classCode);
      await computeSuggestions('''
$contextCode
''');
      validator();
    }
  }
}

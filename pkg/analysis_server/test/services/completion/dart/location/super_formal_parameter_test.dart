// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterTest1);
    defineReflectiveTests(SuperFormalParameterTest2);
  });
}

@reflectiveTest
class SuperFormalParameterTest1 extends AbstractCompletionDriverTest
    with SuperFormalParameterTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class SuperFormalParameterTest2 extends AbstractCompletionDriverTest
    with SuperFormalParameterTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SuperFormalParameterTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  Future<void> test_explicit_optionalNamed_hasArgument_named() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(first: 0);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_explicit_optionalNamed_hasArgument_positional() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(0);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  /// It is an error, but the user already typed `super.`, so maybe do it.
  Future<void> test_explicit_requiredPositional_hasArgument_positional() async {
    var response = await getTestCodeSuggestions('''
class A {
  A(int first, double second);
}

class B extends A {
  B(super.^) : super(0);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_explicitNamed_noOther() async {
    var response = await getTestCodeSuggestions('''
class A {
  A.named(int first, double second);
  A(int third)
}

class B extends A {
  B(super.^) : super.named();
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_hasNamed_notSuper() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int a, super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_hasNamed_notSuper2() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int first, super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_hasNamed_super() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.first, super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_hasNamed_super2() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.second, super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_hasPositional_notSuper() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B(int a, {super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_hasPositional_super() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B(super.first, {super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalNamed_noOther() async {
    var response = await getTestCodeSuggestions('''
class A {
  A(bool first, {int second, double third});
}

class B extends A {
  B({super.^});
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo('third')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalPositional_hasPositional_notSuper() async {
    var response = await getTestCodeSuggestions('''
class A {
  A([int first, double second]);
}

class B extends A {
  B([int one, super.^]);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_implicit_optionalPositional_hasPositional_super() async {
    var response = await getTestCodeSuggestions('''
class A {
  A([int first, double second, bool third]);
}

class B extends A {
  B([super.one, super.^]);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalPositional_hasPositional_super2() async {
    var response = await getTestCodeSuggestions('''
class A {
  A([int first, double second, bool third]);
}

class B extends A {
  B([super.second, super.^]);
}
''');

    // It does not matter what is the name of the positional parameter.
    // Here `super.second` consumes `int first`.
    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_optionalPositional_noOther() async {
    var response = await getTestCodeSuggestions('''
class A {
  A([int first, double second]);
}

class B extends A {
  B(super.^);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_implicit_requiredPositional_hasPositional_notSuper() async {
    var response = await getTestCodeSuggestions('''
class A {
  A(int first, double second);
}

class B extends A {
  B(int one, super.^);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_implicit_requiredPositional_hasPositional_super() async {
    var response = await getTestCodeSuggestions('''
class A {
  A(int first, double second, bool third);
}

class B extends A {
  B(super.one, super.^);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_requiredPositional_hasPositional_super2() async {
    var response = await getTestCodeSuggestions('''
class A {
  A(int first, double second, bool third);
}

class B extends A {
  B(super.second, super.^);
}
''');

    // It does not matter what is the name of the positional parameter.
    // Here `super.second` consumes `int first`.
    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isParameter
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_implicit_requiredPositional_noOther() async {
    var response = await getTestCodeSuggestions('''
class A {
  A(int first, double second);
  A.named(int third);
}

class B extends A {
  B(super.^);
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isParameter
          ..returnType.isEqualTo('int'),
      ]);
  }
}

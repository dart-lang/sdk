// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/super_formal_contributor.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_check.dart';
import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalContributorTest);
  });
}

@reflectiveTest
class SuperFormalContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return SuperFormalContributor(request, builder);
  }

  Future<void> test_explicit_optionalNamed_hasArgument_named() async {
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(first: 0);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(0);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A(int first, double second);
}

class B extends A {
  B(super.^) : super(0);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A.named(int first, double second);
  A(int third)
}

class B extends A {
  B(super.^) : super.named();
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int a, super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int first, super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.first, super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.second, super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B(int a, {super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A({int first, double second});
}

class B extends A {
  B(super.first, {super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A(bool first, {int second, double third});
}

class B extends A {
  B({super.^});
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A([int first, double second]);
}

class B extends A {
  B([int one, super.^]);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A([int first, double second, bool third]);
}

class B extends A {
  B([super.one, super.^]);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A([int first, double second, bool third]);
}

class B extends A {
  B([super.second, super.^]);
}
''');

    // It does not matter what is the name of the positional parameter.
    // Here `super.second` consumes `int first`.
    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A([int first, double second]);
}

class B extends A {
  B(super.^);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A(int first, double second);
}

class B extends A {
  B(int one, super.^);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A(int first, double second, bool third);
}

class B extends A {
  B(super.one, super.^);
}
''');

    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A(int first, double second, bool third);
}

class B extends A {
  B(super.second, super.^);
}
''');

    // It does not matter what is the name of the positional parameter.
    // Here `super.second` consumes `int first`.
    var response = await computeSuggestions2();
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
    addTestSource('''
class A {
  A(int first, double second);
  A.named(int third);
}

class B extends A {
  B(super.^);
}
''');

    var response = await computeSuggestions2();
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

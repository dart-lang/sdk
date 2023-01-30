// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

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
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers = const {'first', 'second', 'third'};
    printerConfiguration.withReturnType = true;
  }

  Future<void> test_explicit_optionalNamed_hasArgument_named() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(first: 0);
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_explicit_optionalNamed_hasArgument_positional() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(0);
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
  second
    kind: parameter
    returnType: double
''');
  }

  /// It is an error, but the user already typed `super.`, so maybe do it.
  Future<void> test_explicit_requiredPositional_hasArgument_positional() async {
    await computeSuggestions('''
class A {
  A(int first, double second);
}

class B extends A {
  B(super.^) : super(0);
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }

  Future<void> test_explicitNamed_noOther() async {
    await computeSuggestions('''
class A {
  A.named(int first, double second);
  A(int third)
}

class B extends A {
  B(super.^) : super.named();
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }

  Future<void> test_implicit_optionalNamed_hasNamed_notSuper() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int a, super.^});
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalNamed_hasNamed_notSuper2() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int first, super.^});
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalNamed_hasNamed_super() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.first, super.^});
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalNamed_hasNamed_super2() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.second, super.^});
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }

  Future<void> test_implicit_optionalNamed_hasPositional_notSuper() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B(int a, {super.^});
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalNamed_hasPositional_super() async {
    await computeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B(super.first, {super.^});
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalNamed_noOther() async {
    await computeSuggestions('''
class A {
  A(bool first, {int second, double third});
}

class B extends A {
  B({super.^});
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: int
  third
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalPositional_hasPositional_notSuper() async {
    await computeSuggestions('''
class A {
  A([int first, double second]);
}

class B extends A {
  B([int one, super.^]);
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }

  Future<void> test_implicit_optionalPositional_hasPositional_super() async {
    await computeSuggestions('''
class A {
  A([int first, double second, bool third]);
}

class B extends A {
  B([super.one, super.^]);
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalPositional_hasPositional_super2() async {
    await computeSuggestions('''
class A {
  A([int first, double second, bool third]);
}

class B extends A {
  B([super.second, super.^]);
}
''');

    // It does not matter what is the name of the positional parameter.
    // Here `super.second` consumes `int first`.
    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_optionalPositional_noOther() async {
    await computeSuggestions('''
class A {
  A([int first, double second]);
}

class B extends A {
  B(super.^);
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }

  Future<void> test_implicit_requiredPositional_hasPositional_notSuper() async {
    await computeSuggestions('''
class A {
  A(int first, double second);
}

class B extends A {
  B(int one, super.^);
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }

  Future<void> test_implicit_requiredPositional_hasPositional_super() async {
    await computeSuggestions('''
class A {
  A(int first, double second, bool third);
}

class B extends A {
  B(super.one, super.^);
}
''');

    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_requiredPositional_hasPositional_super2() async {
    await computeSuggestions('''
class A {
  A(int first, double second, bool third);
}

class B extends A {
  B(super.second, super.^);
}
''');

    // It does not matter what is the name of the positional parameter.
    // Here `super.second` consumes `int first`.
    assertResponse('''
suggestions
  second
    kind: parameter
    returnType: double
''');
  }

  Future<void> test_implicit_requiredPositional_noOther() async {
    await computeSuggestions('''
class A {
  A(int first, double second);
  A.named(int third);
}

class B extends A {
  B(super.^);
}
''');

    assertResponse('''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }
}

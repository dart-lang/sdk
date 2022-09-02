// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

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

    printerConfiguration = printer.Configuration(
      filter: (suggestion) => true,
      withReturnType: true,
    );
  }

  Future<void> test_explicit_optionalNamed_hasArgument_named() async {
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({super.^}) : super(first: 0);
}
''');

    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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

    assertResponseText(response, r'''
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
    var response = await getTestCodeSuggestions('''
class A {
  A(int first, double second);
}

class B extends A {
  B(super.^) : super(0);
}
''');

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
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

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
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

    assertResponseText(response, r'''
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
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B({int first, super.^});
}
''');

    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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

    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
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

    assertResponseText(response, r'''
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
    var response = await getTestCodeSuggestions('''
class A {
  A({int first, double second});
}

class B extends A {
  B(super.first, {super.^});
}
''');

    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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

    assertResponseText(response, r'''
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
    var response = await getTestCodeSuggestions('''
class A {
  A([int first, double second]);
}

class B extends A {
  B([int one, super.^]);
}
''');

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
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

    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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
    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
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

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
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

    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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
    assertResponseText(response, r'''
suggestions
  second
    kind: parameter
    returnType: double
''');
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

    assertResponseText(response, r'''
suggestions
  first
    kind: parameter
    returnType: int
''');
  }
}

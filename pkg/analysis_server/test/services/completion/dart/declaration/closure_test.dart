import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosureTest1);
    defineReflectiveTests(ClosureTest2);
  });
}

@reflectiveTest
class ClosureTest1 extends AbstractCompletionDriverTest with ClosureTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

@reflectiveTest
class ClosureTest2 extends AbstractCompletionDriverTest with ClosureTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ClosureTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeClosures => true;

  @override
  bool get includeKeywords => false;

  Future<void> test_argumentList_named() async {
    await computeSuggestions('''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, b) => ,
    kind: invocation
    selection: 10
  (a, b) {
${' ' * 4}
  },
    kind: invocation
    selection: 13
''');
  }

  Future<void> test_argumentList_named_hasComma() async {
    await computeSuggestions('''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(
    closure: ^,
  );
}
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
  (a, b) {
${' ' * 6}
    }
    kind: invocation
    selection: 15
''');
  }

  Future<void> test_argumentList_positional() async {
    await computeSuggestions('''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^);
}
''');
    assertResponse('''
suggestions
  (a, b) => ,
    kind: invocation
    selection: 10
  (a, b) {
${' ' * 4}
  },
    kind: invocation
    selection: 13
''');
  }

  Future<void> test_argumentList_positional_hasComma() async {
    await computeSuggestions('''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^,);
}
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
  (a, b) {
${' ' * 4}
  }
    kind: invocation
    selection: 13
''');
  }

  Future<void> test_parameters_optionalNamed() async {
    await computeSuggestions('''
void f({void Function(int a, {int b, int c}) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, {b, c}) => ,
    kind: invocation
    selection: 15
  (a, {b, c}) {
${' ' * 4}
  },
    kind: invocation
    selection: 18
''');
  }

  Future<void> test_parameters_optionalPositional() async {
    await computeSuggestions('''
void f({void Function(int a, [int b, int c]) closure]) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, [b, c]) => ,
    kind: invocation
    selection: 15
  (a, [b, c]) {
${' ' * 4}
  },
    kind: invocation
    selection: 18
''');
  }

  Future<void> test_variableInitializer() async {
    await computeSuggestions('''
void Function(int a, int b) v = ^;
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
  (a, b) {
${' ' * 2}
}
    kind: invocation
    selection: 11
''');
  }
}

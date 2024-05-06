import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableNameTest);
  });
}

@reflectiveTest
class VariableNameTest extends AbstractCompletionDriverTest
    with VariableNameTestCases {}

mixin VariableNameTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers = {
      'abstractCrazyNonsenseClassName',
      'crazyNonsenseClassName',
      'nonsenseClassName',
      'className',
      'name',
      'a',
      '_abstractCrazyNonsenseClassName',
      '_crazyNonsenseClassName',
      '_nonsenseClassName',
      '_className',
      '_name',
      '_a',
    };
  }

  @failingTest
  Future<void> test_forStatement() async {
    await computeSuggestions('''
void f() {
  for (AbstractCrazyNonsenseClassName ^) {}
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_forStatement_partial() async {
    await computeSuggestions('''
void f() {
  for (AbstractCrazyNonsenseClassName a^) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
''');
  }

  @failingTest
  Future<void> test_forStatement_prefixed() async {
    await computeSuggestions('''
void f() {
  for (prefix.AbstractCrazyNonsenseClassName ^) {}
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_forStatement_prefixed_partial() async {
    await computeSuggestions('''
void f() {
  for (prefix.AbstractCrazyNonsenseClassName a^) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_afterGenericType() async {
    await computeSuggestions('''
void f() {
  AbstractCrazyNonsenseClassName<int> ^
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_dontSuggestType_beforeEnd() async {
    await computeSuggestions('''
void f() {
  a ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_localVariable_dontSuggestType_beforeSemicolon() async {
    await computeSuggestions('''
void f() {
  a ^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_localVariable_inConstructorBody() async {
    await computeSuggestions('''
class A {
  A() {
    AbstractCrazyNonsenseClassName ^
  }
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_inFunctionBody() async {
    await computeSuggestions('''
void f() {
  AbstractCrazyNonsenseClassName ^
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_inMethodBody() async {
    await computeSuggestions('''
class A {
  void f() {
    AbstractCrazyNonsenseClassName ^
  }
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_long_beforeSemicolon() async {
    await computeSuggestions('''
void f() {
  AbstractCrazyNonsenseClassName ^;
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_prefixed_beforeEnd() async {
    await computeSuggestions('''
void f() {
  prefix.AbstractCrazyNonsenseClassName ^
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_prefixed_beforeSemicolon() async {
    await computeSuggestions('''
void f() {
  prefix.AbstractCrazyNonsenseClassName ^;
}
''');
    assertResponse(r'''
suggestions
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_localVariable_short_beforeEnd() async {
    await computeSuggestions('''
void f() {
  A ^
}
''');
    assertResponse(r'''
suggestions
  a
    kind: identifier
''');
  }

  Future<void> test_localVariable_short_beforeSemicolon() async {
    await computeSuggestions('''
void f() {
  A ^;
}
''');
    assertResponse(r'''
suggestions
  a
    kind: identifier
''');
  }

  Future<void> test_parameter_FormalParameterList() async {
    await computeSuggestions('''
void f(A ^) {}
''');
    assertResponse(r'''
suggestions
  a
    kind: identifier
''');
  }

  Future<void> test_parameter_partial() async {
    await computeSuggestions('''
void f(A n^) {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_topLevelVariable_beforeEnd_partial() async {
    await computeSuggestions('''
AbstractCrazyNonsenseClassName abs^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  _abstractCrazyNonsenseClassName
    kind: identifier
  abstractCrazyNonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_beforeSemicolon_partial() async {
    await computeSuggestions('''
AbstractCrazyNonsenseClassName abs^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  _abstractCrazyNonsenseClassName
    kind: identifier
  abstractCrazyNonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_dontSuggestType_beforeEnd() async {
    await computeSuggestions('''
a ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_topLevelVariable_dontSuggestType_beforeSemicolon() async {
    await computeSuggestions('''
a ^;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_topLevelVariable_long_beforeEnd() async {
    await computeSuggestions('''
AbstractCrazyNonsenseClassName ^
''');
    assertResponse(r'''
suggestions
  _abstractCrazyNonsenseClassName
    kind: identifier
  _className
    kind: identifier
  _crazyNonsenseClassName
    kind: identifier
  _name
    kind: identifier
  _nonsenseClassName
    kind: identifier
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_long_beforeSemicolon() async {
    await computeSuggestions('''
AbstractCrazyNonsenseClassName ^;
''');
    assertResponse(r'''
suggestions
  _abstractCrazyNonsenseClassName
    kind: identifier
  _className
    kind: identifier
  _crazyNonsenseClassName
    kind: identifier
  _name
    kind: identifier
  _nonsenseClassName
    kind: identifier
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_prefixed_beforeEnd() async {
    await computeSuggestions('''
prefix.AbstractCrazyNonsenseClassName ^
''');
    assertResponse(r'''
suggestions
  _abstractCrazyNonsenseClassName
    kind: identifier
  _className
    kind: identifier
  _crazyNonsenseClassName
    kind: identifier
  _name
    kind: identifier
  _nonsenseClassName
    kind: identifier
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_prefixed_beforeSemicolon() async {
    await computeSuggestions('''
prefix.AbstractCrazyNonsenseClassName ^;
''');
    assertResponse(r'''
suggestions
  _abstractCrazyNonsenseClassName
    kind: identifier
  _className
    kind: identifier
  _crazyNonsenseClassName
    kind: identifier
  _name
    kind: identifier
  _nonsenseClassName
    kind: identifier
  abstractCrazyNonsenseClassName
    kind: identifier
  className
    kind: identifier
  crazyNonsenseClassName
    kind: identifier
  name
    kind: identifier
  nonsenseClassName
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_short_beforeEnd() async {
    await computeSuggestions('''
A ^
''');
    assertResponse(r'''
suggestions
  _a
    kind: identifier
  a
    kind: identifier
''');
  }

  Future<void> test_topLevelVariable_short_beforeSemicolon() async {
    await computeSuggestions('''
A ^;
''');
    assertResponse(r'''
suggestions
  _a
    kind: identifier
  a
    kind: identifier
''');
  }
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.arglist;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/arglist_contributor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../../utils.dart';
import 'completion_contributor_util.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(ArgListContributorTest);
}

@reflectiveTest
class ArgListContributorTest extends DartCompletionContributorTest {
  void assertNoOtherSuggestions(Iterable<CompletionSuggestion> expected) {
    for (CompletionSuggestion suggestion in suggestions) {
      if (!expected.contains(suggestion)) {
        failedCompletion('did not expect completion: '
            '${suggestion.completion}\n  $suggestion');
      }
    }
  }

  void assertSuggestArgumentList(
      List<String> paramNames, List<String> paramTypes) {
    // DEPRECATED... argument lists are no longer suggested.
    // See https://github.com/dart-lang/sdk/issues/25197
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);

    // CompletionSuggestionKind csKind = CompletionSuggestionKind.ARGUMENT_LIST;
    // CompletionSuggestion cs = getSuggest(csKind: csKind);
    // if (cs == null) {
    //   failedCompletion('expected completion $csKind', suggestions);
    // }
    // assertSuggestArgumentList_params(
    //     paramNames, paramTypes, cs.parameterNames, cs.parameterTypes);
    // expect(cs.relevance, DART_RELEVANCE_HIGH);
    // assertNoOtherSuggestions([cs]);
  }

  void assertSuggestArgumentList_params(
      List<String> expectedNames,
      List<String> expectedTypes,
      List<String> actualNames,
      List<String> actualTypes) {
    if (actualNames != null &&
        actualNames.length == expectedNames.length &&
        actualTypes != null &&
        actualTypes.length == expectedTypes.length) {
      int index = 0;
      while (index < expectedNames.length) {
        if (actualNames[index] != expectedNames[index] ||
            actualTypes[index] != expectedTypes[index]) {
          break;
        }
        ++index;
      }
      if (index == expectedNames.length) {
        return;
      }
    }
    StringBuffer msg = new StringBuffer();
    msg.writeln('Argument list not the same');
    msg.writeln('  Expected names: $expectedNames');
    msg.writeln('           found: $actualNames');
    msg.writeln('  Expected types: $expectedTypes');
    msg.writeln('           found: $actualTypes');
    fail(msg.toString());
  }

  /**
   * Assert that the specified named argument suggestions with their types are
   * the only suggestions.
   */
  void assertSuggestArgumentsAndTypes(
      {Map<String, String> namedArgumentsWithTypes}) {
    List<CompletionSuggestion> expected = new List<CompletionSuggestion>();
    namedArgumentsWithTypes.forEach((String name, String type) {
      expected.add(assertSuggest('$name: ',
          csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
          relevance: DART_RELEVANCE_NAMED_PARAMETER,
          paramName: name,
          paramType: type));
    });
    assertNoOtherSuggestions(expected);
  }

  /**
   * Assert that the specified suggestions are the only suggestions.
   */
  void assertSuggestions(List<String> suggestions) {
    List<CompletionSuggestion> expected = new List<CompletionSuggestion>();
    for (String suggestion in suggestions) {
      expected.add(assertSuggest('$suggestion',
          csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
          relevance: DART_RELEVANCE_NAMED_PARAMETER));
    }
    assertNoOtherSuggestions(expected);
  }

  @override
  DartCompletionContributor createContributor() {
    return new ArgListContributor();
  }

  fail_test_Annotation_local_constructor_named_param_10() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(two: '2' ^) main() { }''');
    await computeSuggestions();
    assertSuggestions([', one: ']);
  }

  fail_test_Annotation_local_constructor_named_param_9() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(two: '2'^) main() { }''');
    await computeSuggestions();
    assertSuggestions([', one: ']);
  }

  test_Annotation_imported_constructor_named_param() async {
    addSource(
        '/libA.dart',
        '''
library libA; class A { const A({int one, String two: 'defaultValue'}); }''');
    addTestSource('import "/libA.dart"; @A(^) main() { }');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  test_Annotation_local_constructor_named_param() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^) main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  test_Annotation_local_constructor_named_param_11() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(two: '2', ^) main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  test_Annotation_local_constructor_named_param_2() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^ two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  test_Annotation_local_constructor_named_param_3() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  test_Annotation_local_constructor_named_param_4() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^, two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  test_Annotation_local_constructor_named_param_5() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^ , two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  test_Annotation_local_constructor_named_param_6() async {
    addTestSource('''
class A { const A(int zero, {int one, String two: 'defaultValue'}); }
@A(0, ^, two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  test_Annotation_local_constructor_named_param_7() async {
    addTestSource('''
class A { const A(int zero, {int one, String two: 'defaultValue'}); }
@A(0, ^ two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  test_Annotation_local_constructor_named_param_8() async {
    addTestSource('''
class A { const A(int zero, {int one, String two: 'defaultValue'}); }
@A(0, ^two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  test_Annotation_local_constructor_named_param_negative() async {
    addTestSource('''
class A { const A(int one, int two, int three, {int four, String five:
  'defaultValue'}); }
@A(1, ^, 3) main() { }''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_getter() async {
    addTestSource('class A {int get foo => 7; main() {foo(^)}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_constructor_named_param() async {
    //
    addSource('/libA.dart', 'library libA; class A{A({int one}); }');
    addTestSource('import "/libA.dart"; main() { new A(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  test_ArgumentList_imported_constructor_named_param2() async {
    //
    addSource('/libA.dart', 'library libA; class A{A.foo({int one}); }');
    addTestSource('import "/libA.dart"; main() { new A.foo(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  test_ArgumentList_imported_constructor_named_typed_param() async {
    //
    addSource(
        '/libA.dart', 'library libA; class A { A({int i, String s, d}) {} }}');
    addTestSource('import "/libA.dart"; main() { var a = new A(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'i': 'int', 's': 'String', 'd': 'dynamic'});
  }

  test_ArgumentList_imported_function_0() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect() { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(a^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_function_1() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg'], ['String']);
  }

  test_ArgumentList_imported_function_2() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg1', 'arg2'], ['String', 'int']);
  }

  test_ArgumentList_imported_function_3() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg1', 'arg2'], ['String', 'int']);
  }

  test_ArgumentList_imported_function_3a() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_function_3b() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', ^x)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_function_3c() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', x^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_function_3d() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', x ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_function_named_param() async {
    //
    addTestSource('main() { int.parse("16", ^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'radix': 'int', 'onError': '(String) → int'});
  }

  test_ArgumentList_imported_function_named_param1() async {
    //
    addTestSource('main() { int.parse("16", r^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'radix': 'int', 'onError': '(String) → int'});
  }

  test_ArgumentList_imported_function_named_param2() async {
    //
    addTestSource('main() { int.parse("16", radix: 7, ^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'onError': '(String) → int'});
  }

  test_ArgumentList_imported_function_named_param2a() async {
    //
    addTestSource('main() { int.parse("16", radix: ^);}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_imported_function_named_param_label1() async {
    //
    addTestSource('main() { int.parse("16", r^: 16);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'radix': 'int', 'onError': '(String) → int'});
  }

  test_ArgumentList_imported_function_named_param_label2() async {
    //
    addTestSource('main() { int.parse("16", ^r: 16);}');
    await computeSuggestions();
    assertSuggestions(['radix: ,', 'onError: ,']);
  }

  test_ArgumentList_imported_function_named_param_label3() async {
    //
    addTestSource('main() { int.parse("16", ^: 16);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'radix': 'int', 'onError': '(String) → int'});
  }

  test_ArgumentList_local_constructor_named_param() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  test_ArgumentList_local_constructor_named_param2() async {
    //
    addTestSource('''
class A { A.foo({int one, String two: 'defaultValue'}) { } }
main() { new A.foo(^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  test_ArgumentList_local_function_1() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg) { }
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg'], ['dynamic']);
  }

  test_ArgumentList_local_function_2() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2) { }
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg1', 'arg2'], ['dynamic', 'int']);
  }

  test_ArgumentList_local_function_3() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2) { }
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg1', 'arg2'], ['dynamic', 'int']);
  }

  test_ArgumentList_local_function_3a() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_local_function_3b() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', ^x)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_local_function_3c() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', x^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_local_function_3d() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', x ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_local_function_named_param() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", ^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'radix': 'int', 'onError': '(String) → int'});
  }

  test_ArgumentList_local_function_named_param1() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", r^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'radix': 'int', 'onError': '(String) → int'});
  }

  test_ArgumentList_local_function_named_param2() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", radix: 7, ^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'onError': '(String) → int'});
  }

  test_ArgumentList_local_function_named_param2a() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", radix: ^);}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_local_method_0() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B {
        expect() { }
        void foo() {expect(^)}}
      String bar() => true;''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_ArgumentList_local_method_2() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B {
        expect(arg, int blat) { }
        void foo() {expect(^)}}
      String bar() => true;''');
    await computeSuggestions();
    assertSuggestArgumentList(['arg', 'blat'], ['dynamic', 'int']);
  }
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.arglist;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/arglist_contributor.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ArgListContributorTest);
}

@reflectiveTest
class ArgListContributorTest extends AbstractCompletionTest {
  void assertNoOtherSuggestions(Iterable<CompletionSuggestion> expected) {
    for (CompletionSuggestion suggestion in request.suggestions) {
      if (!expected.contains(suggestion)) {
        failedCompletion('did not expect completion: '
            '${suggestion.completion}\n  $suggestion');
      }
    }
  }

  void assertSuggestArgumentList(
      List<String> paramNames, List<String> paramTypes) {
    CompletionSuggestionKind csKind = CompletionSuggestionKind.ARGUMENT_LIST;
    CompletionSuggestion cs = getSuggest(csKind: csKind);
    if (cs == null) {
      failedCompletion('expected completion $csKind', request.suggestions);
    }
    assertSuggestArgumentList_params(
        paramNames, paramTypes, cs.parameterNames, cs.parameterTypes);
    expect(cs.relevance, DART_RELEVANCE_HIGH);
    assertNoOtherSuggestions([cs]);
  }

  void assertSuggestArgumentList_params(List<String> expectedNames,
      List<String> expectedTypes, List<String> actualNames,
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
   * Assert that the specified suggestions are the only suggestions.
   */
  void assertSuggestArguments({List<String> namedArguments}) {
    List<CompletionSuggestion> expected = new List<CompletionSuggestion>();
    for (String name in namedArguments) {
      expected.add(assertSuggest('$name: ',
          csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
          relevance: DART_RELEVANCE_PARAMETER));
    }
    assertNoOtherSuggestions(expected);
  }

  @override
  void setUpContributor() {
    contributor = new ArgListContributor();
  }

  test_ArgumentList_getter() {
    addTestSource('class A {int get foo => 7; main() {foo(^)}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_imported_function_0() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect() { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(a^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_imported_function_1() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg'], ['String']);
    });
  }

  test_ArgumentList_imported_function_2() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg1', 'arg2'], ['String', 'int']);
    });
  }

  test_ArgumentList_imported_function_3() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg1', 'arg2'], ['String', 'int']);
    });
  }

  test_ArgumentList_imported_function_3a() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', ^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_imported_function_3b() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', ^x)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_imported_function_3c() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', x^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_imported_function_3d() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', x ^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_imported_function_named_param() {
    //
    addTestSource('main() { int.parse("16", ^);}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArguments(namedArguments: ['radix', 'onError']);
    });
  }

  test_ArgumentList_imported_function_named_param1() {
    //
    addTestSource('main() { int.parse("16", r^);}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArguments(namedArguments: ['radix', 'onError']);
    });
  }

  test_ArgumentList_imported_function_named_param2() {
    //
    addTestSource('main() { int.parse("16", radix: 7, ^);}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArguments(namedArguments: ['onError']);
    });
  }

  test_ArgumentList_imported_function_named_param2a() {
    //
    addTestSource('main() { int.parse("16", radix: ^);}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_function_1() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg) { }
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg'], ['dynamic']);
    });
  }

  test_ArgumentList_local_function_2() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2) { }
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg1', 'arg2'], ['dynamic', 'int']);
    });
  }

  test_ArgumentList_local_function_3() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2) { }
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg1', 'arg2'], ['dynamic', 'int']);
    });
  }

  test_ArgumentList_local_function_3a() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', ^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_function_3b() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', ^x)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_function_3c() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', x^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_function_3d() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      import '/libA.dart'
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', x ^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_function_named_param() {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", ^);}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArguments(namedArguments: ['radix', 'onError']);
    });
  }

  test_ArgumentList_local_function_named_param1() {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", r^);}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArguments(namedArguments: ['radix', 'onError']);
    });
  }

  test_ArgumentList_local_function_named_param2() {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", radix: 7, ^);}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArguments(namedArguments: ['onError']);
    });
  }

  test_ArgumentList_local_function_named_param2a() {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", radix: ^);}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_method_0() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B {
        expect() { }
        void foo() {expect(^)}}
      String bar() => true;''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ArgumentList_local_method_2() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B {
        expect(arg, int blat) { }
        void foo() {expect(^)}}
      String bar() => true;''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestArgumentList(['arg', 'blat'], ['dynamic', 'int']);
    });
  }
}

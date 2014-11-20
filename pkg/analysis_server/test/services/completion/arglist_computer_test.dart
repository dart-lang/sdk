// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.arglist;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/arglist_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ArgListComputerTest);
}

@ReflectiveTestCase()
class ArgListComputerTest extends AbstractCompletionTest {

  @override
  void setUpComputer() {
    computer = new ArgListComputer();
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
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    });
  }

//  test_ArgumentList_imported_function_1() {
//    // ArgumentList  MethodInvocation  ExpressionStatement  Block
//    addSource('/libA.dart', '''
//      library A;
//      bool hasLength(int expected) { }
//      expect(String arg) { }
//      void baz() { }''');
//    addTestSource('''
//      import '/libA.dart'
//      class B { }
//      String bar() => true;
//      void main() {expect(^)}''');
//    computeFast();
//    return computeFull((bool result) {
//      assertSuggestArgumentList(['arg'], ['String']);
//    });
//  }

  test_ArgumentList_local_function_1() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
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
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
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

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ImportedTypeComputerTest);
}

@ReflectiveTestCase()
class ImportedTypeComputerTest extends AbstractSelectorSuggestionTest {

  @override
  void setUp() {
    super.setUp();
    computer = new ImportedComputer();
  }

  test_Block_function() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addSource('/testA.dart', '''
      export "dart:math" hide max;
      @deprecated A() {int x;}
      _B() {}''');
    addTestSource('''
      import "/testA.dart";
      class X {foo(){^}}''');
    return computeFull().then((_) {
      assertSuggestFunction('A', null, true);
      assertNotSuggested('x');
      assertNotSuggested('_B');
      assertSuggestFunction('min', 'num', false);
      assertSuggestFunction('max', 'num', false, CompletionRelevance.LOW);
      // Should not suggest compilation unit elements
      // which are returned by the LocalComputer
      assertNotSuggested('X');
      assertNotSuggested('foo');
    });
  }

  test_Block_topLevelVar() {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/testA.dart', '''
      String T1;
      var _T2;''');
    addSource('/testB.dart', /* not imported */ '''
      int T3;
      var _T4;''');
    addTestSource('''
      import "/testA.dart";
      class C {foo(){^}}''');
    // pass true for full analysis to pick up unimported source
    return computeFull(true).then((_) {
      assertSuggestTopLevelVarGetterSetter('T1', 'String');
      assertNotSuggested('_T2');
      assertSuggestTopLevelVar('T3', 'int', CompletionRelevance.LOW);
      assertNotSuggested('_T4');
      // LocalComputer provides local suggestions
      assertNotSuggested('C');
      assertNotSuggested('foo');
    });
  }

  test_ExpressionStatement_class() {
    // SimpleIdentifier  ExpressionStatement  Block
    addSource('/testA.dart', '''
      _B F1() { }
      class A {int x;}
      class _B { }''');
    addTestSource('''
      import "/testA.dart";
      class C {foo(){O^}}''');
    return computeFull().then((_) {
      assertSuggestClass('A');
      assertSuggestFunction('F1', '_B', false);
      assertNotSuggested('x');
      assertNotSuggested('_B');
      // Should not suggest compilation unit elements
      // which are returned by the LocalComputer
      assertNotSuggested('C');
    });
  }

  test_ExpressionStatement_name() {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addSource('/testA.dart', '''
      B T1;
      class B{}''');
    addTestSource('''
      import "/testA.dart";
      class C {a() {C ^}}''');
    return computeFull().then((_) {
      assertNotSuggested('T1');
    });
  }

  test_FieldDeclaration_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/testA.dart', 'class A { }');
    addTestSource('''
      import "/testA.dart";
      class C {A ^}''');
    return computeFull().then((_) {
      assertNotSuggested('A');
    });
  }

  test_FieldDeclaration_name_varType() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/testA.dart', 'class A { }');
    addTestSource('''
      import "/testA.dart";
      class C {var ^}''');
    return computeFull().then((_) {
      assertNotSuggested('A');
    });
  }
}

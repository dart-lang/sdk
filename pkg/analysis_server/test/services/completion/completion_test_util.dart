// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.util;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol show Element,
    ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:analysis_server/src/services/completion/local_computer.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';

class AbstractCompletionTest extends AbstractContextTest {
  Index index;
  SearchEngineImpl searchEngine;
  DartCompletionComputer computer;
  String testFile = '/completionTest.dart';
  Source testSource;
  CompilationUnit testUnit;
  int completionOffset;
  AstNode completionNode;
  bool _computeFastCalled = false;
  DartCompletionRequest request;

  void addResolvedUnit(String file, String code) {
    Source source = addSource(file, code);
    CompilationUnit unit = resolveLibraryUnit(source);
    index.indexUnit(context, unit);
  }

  void addTestSource(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    testSource = addSource(testFile, content);
    request =
        new DartCompletionRequest(context, searchEngine, testSource, completionOffset);
  }

  void assertNoSuggestions() {
    if (request.suggestions.length > 0) {
      _failedCompletion('Expected no suggestions', request.suggestions);
    }
  }

  CompletionSuggestion assertNotSuggested(String completion) {
    CompletionSuggestion suggestion = request.suggestions.firstWhere(
        (cs) => cs.completion == completion,
        orElse: () => null);
    if (suggestion != null) {
      _failedCompletion(
          'did not expect completion: $completion\n  $suggestion');
    }
    return null;
  }

  CompletionSuggestion assertSuggest(CompletionSuggestionKind kind,
      String completion, [CompletionRelevance relevance = CompletionRelevance.DEFAULT,
      bool isDeprecated = false, bool isPotential = false]) {
    CompletionSuggestion cs;
    request.suggestions.forEach((s) {
      if (s.completion == completion && s.kind == kind) {
        if (cs == null) {
          cs = s;
        } else {
          _failedCompletion(
              'expected exactly one $completion',
              request.suggestions.where((s) => s.completion == completion));
        }
      }
    });
    if (cs == null) {
      _failedCompletion('expected $completion $kind', request.suggestions);
    }
    expect(cs.kind, equals(kind));
    expect(cs.relevance, equals(relevance));
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
    return cs;
  }

  CompletionSuggestion assertSuggestClass(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.CLASS, name, relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS));
    expect(element.name, equals(name));
    expect(element.returnType, isNull);
    return cs;
  }

  CompletionSuggestion assertSuggestFunction(String name, String returnType,
      bool isDeprecated, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs = assertSuggest(
        CompletionSuggestionKind.FUNCTION,
        name,
        relevance,
        isDeprecated);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestGetter(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.GETTER, name, relevance);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.GETTER));
    expect(element.name, equals(name));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestLibraryPrefix(String prefix,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    // Library prefix should only be suggested by ImportedComputer
    if (computer is ImportedComputer) {
      CompletionSuggestion cs =
          assertSuggest(CompletionSuggestionKind.LIBRARY_PREFIX, prefix, relevance);
      protocol.Element element = cs.element;
      expect(element, isNotNull);
      expect(element.kind, equals(protocol.ElementKind.LIBRARY));
      expect(element.returnType, isNull);
      return cs;
    } else {
      return assertNotSuggested(prefix);
    }
  }

  CompletionSuggestion assertSuggestLocalVariable(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    // Local variables should only be suggested by LocalComputer
    if (computer is LocalComputer) {
      CompletionSuggestion cs =
          assertSuggest(CompletionSuggestionKind.LOCAL_VARIABLE, name, relevance);
      expect(cs.returnType, equals(returnType));
      protocol.Element element = cs.element;
      expect(element, isNotNull);
      expect(element.kind, equals(protocol.ElementKind.LOCAL_VARIABLE));
      expect(element.name, equals(name));
      expect(
          element.returnType,
          equals(returnType != null ? returnType : 'dynamic'));
      return cs;
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestMethod(String name, String declaringType,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.METHOD, name, relevance);
    expect(cs.declaringType, equals(declaringType));
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.METHOD));
    expect(element.name, equals(name));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestNamedConstructor(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is InvocationComputer) {
      CompletionSuggestion cs =
          assertSuggest(CompletionSuggestionKind.CONSTRUCTOR, name, relevance);
      protocol.Element element = cs.element;
      expect(element, isNotNull);
      expect(element.kind, equals(protocol.ElementKind.CONSTRUCTOR));
      expect(element.name, equals(name));
      expect(element.returnType, equals(returnType));
      return cs;
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestParameter(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    // Parameters should only be suggested by LocalComputer
    if (computer is LocalComputer) {
      CompletionSuggestion cs =
          assertSuggest(CompletionSuggestionKind.PARAMETER, name, relevance);
      expect(cs.returnType, equals(returnType));
      protocol.Element element = cs.element;
      expect(element, isNotNull);
      expect(element.kind, equals(protocol.ElementKind.PARAMETER));
      expect(element.name, equals(name));
      expect(
          element.returnType,
          equals(returnType != null ? returnType : 'dynamic'));
      return cs;
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestSetter(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.SETTER, name, relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.SETTER));
    expect(element.name, equals(name));
    expect(element.returnType, isNull);
    return cs;
  }

  CompletionSuggestion assertSuggestTopLevelVar(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.TOP_LEVEL_VARIABLE, name, relevance);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.TOP_LEVEL_VARIABLE));
    expect(element.name, equals(name));
    //TODO (danrubel) return type level variable 'type' but not as 'returnType'
//    expect(
//        element.returnType,
//        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  void assertSuggestTopLevelVarGetterSetter(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    if (computer is ImportedComputer) {
      assertSuggestGetter(name, returnType);
      assertSuggestSetter(name);
    } else {
      assertNotSuggested(name);
    }
  }

  bool computeFast() {
    _computeFastCalled = true;
    testUnit = context.parseCompilationUnit(testSource);
    completionNode =
        new NodeLocator.con1(completionOffset).searchWithin(testUnit);
    request.unit = testUnit;
    request.node = completionNode;
    return computer.computeFast(request);
  }

  Future<bool> computeFull([bool fullAnalysis = false]) {
    if (!_computeFastCalled) {
      expect(computeFast(), isFalse);
    }

    // Index SDK
    for (Source librarySource in context.librarySources) {
      CompilationUnit unit =
          context.getResolvedCompilationUnit2(librarySource, librarySource);
      if (unit != null) {
        index.indexUnit(context, unit);
      }
    }

    var result = context.performAnalysisTask();
    bool resolved = false;
    while (result.hasMoreWork) {

      // Update the index
      result.changeNotices.forEach((ChangeNotice notice) {
        CompilationUnit unit = notice.compilationUnit;
        if (unit != null) {
          index.indexUnit(context, unit);
        }
      });

      // If the unit has been resolved, then finish the completion
      LibraryElement library = context.getLibraryElement(testSource);
      if (library != null) {
        CompilationUnit unit =
            context.getResolvedCompilationUnit(testSource, library);
        if (unit != null) {
          request.unit = unit;
          request.node =
              new NodeLocator.con1(completionOffset).searchWithin(unit);
          resolved = true;
          if (!fullAnalysis) {
            break;
          }
        }
      }

      result = context.performAnalysisTask();
    }
    if (!resolved) {
      fail('expected unit to be resolved');
    }
    return computer.computeFull(request);
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }

  void _failedCompletion(String message,
      [Iterable<CompletionSuggestion> completions]) {
    StringBuffer sb = new StringBuffer(message);
    if (completions != null) {
      sb.write('\n  found');
      completions.toList()
          ..sort((CompletionSuggestion s1, CompletionSuggestion s2) {
            String c1 = s1.completion.toLowerCase();
            String c2 = s2.completion.toLowerCase();
            return c1.compareTo(c2);
          })
          ..forEach((CompletionSuggestion suggestion) {
            sb.write('\n    ${suggestion.completion} -> $suggestion');
          });
    }
    if (completionNode != null) {
      sb.write('\n  in');
      AstNode node = completionNode;
      while (node != null) {
        sb.write('\n    ${node.runtimeType}');
        node = node.parent;
      }
    }
    fail(sb.toString());
  }
}

/**
 * Common tests for `ImportedTypeComputerTest`, `InvocationComputerTest`,
 * and `LocalComputerTest`.
 */
class AbstractSelectorSuggestionTest extends AbstractCompletionTest {

  CompletionSuggestion assertLocalSuggestMethod(String name,
      String declaringType, String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is LocalComputer) {
      return assertSuggestMethod(name, declaringType, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedClass(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    if (computer is ImportedComputer) {
      return assertSuggestClass(name, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedFunction(String name,
      String returnType, [bool isDeprecated = false, CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is ImportedComputer) {
      return assertSuggestFunction(name, returnType, isDeprecated, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedGetter(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is ImportedComputer) {
      return assertSuggestGetter(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedMethod(String name,
      String declaringType, String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is ImportedComputer) {
      return assertSuggestMethod(name, declaringType, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedTopLevelVar(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is ImportedComputer) {
      return assertSuggestTopLevelVar(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationClass(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestClass(name, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationGetter(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestGetter(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationMethod(String name,
      String declaringType, String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestMethod(name, declaringType, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationSetter(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestSetter(name);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationTopLevelVar(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestTopLevelVar(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestLocalClass(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    if (computer is LocalComputer) {
      return assertSuggestClass(name, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestLocalFunction(String name,
      String returnType, [bool isDeprecated = false, CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is LocalComputer) {
      return assertSuggestFunction(name, returnType, isDeprecated, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestLocalGetter(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    if (computer is LocalComputer) {
      return assertSuggestGetter(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestLocalMethod(String name,
      String declaringType, String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is LocalComputer) {
      return assertSuggestMethod(name, declaringType, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestLocalTopLevelVar(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    if (computer is LocalComputer) {
      return assertSuggestTopLevelVar(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  test_AssignmentExpression_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int ^b = 1;}');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_AssignmentExpression_RHS() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int b = ^}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', 'int');
      assertSuggestLocalFunction('main', null);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_AssignmentExpression_type() {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int^ b = 1;}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('int');
      assertNotSuggested('a');
      assertNotSuggested('main');
    });
  }

  test_AwaitExpression() {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('''
      class A {int x; int y() => 0;}
      main(){A a; await ^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', 'A');
      assertSuggestLocalFunction('main', null);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_BinaryExpression_LHS() {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = ^ + 2;}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', 'int');
      assertSuggestImportedClass('Object');
      assertNotSuggested('b');
    });
  }

  test_BinaryExpression_RHS() {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', 'int');
      assertSuggestImportedClass('Object');
      assertNotSuggested('b');
      assertNotSuggested('==');
    });
  }

  test_Block() {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/testAB.dart', '''
      export "dart:math" hide max;
      class A {int x;}
      @deprecated D1() {int x;}
      class _B { }''');
    addSource('/testCD.dart', '''
      String T1;
      var _T2;
      class C { }
      class D { }''');
    addSource('/testEEF.dart', '''
      class EE { }
      class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource('/testH.dart', '''
      class H { }
      int T3;
      var _T4;'''); // not imported
    addTestSource('''
      import "/testAB.dart";
      import "/testCD.dart" hide D;
      import "/testEEF.dart" show EE;
      import "/testG.dart" as g;
      int T5;
      var _T6;
      Z D2() {int x;}
      class X {a() {var f; {var x;} ^ var r;} void b() { }}
      class Z { }''');
    computeFast();
    return computeFull(true).then((_) {

      assertSuggestLocalClass('X');
      assertSuggestLocalClass('Z');
      assertLocalSuggestMethod('a', 'X', null);
      assertLocalSuggestMethod('b', 'X', 'void');
      assertSuggestLocalVariable('f', null);
      // Don't suggest locals out of scope
      assertNotSuggested('r');
      assertNotSuggested('x');

      assertSuggestImportedClass('A');
      assertNotSuggested('_B');
      assertSuggestImportedClass('C');
      // hidden element suggested as low relevance
      assertSuggestImportedClass('D', CompletionRelevance.LOW);
      assertSuggestImportedFunction('D1', null, true);
      assertSuggestLocalFunction('D2', 'Z');
      assertSuggestImportedClass('EE');
      // hidden element suggested as low relevance
      assertSuggestImportedClass('F', CompletionRelevance.LOW);
      assertSuggestLibraryPrefix('g');
      assertNotSuggested('G');
      assertSuggestImportedClass('H', CompletionRelevance.LOW);
      assertSuggestImportedClass('Object');
      assertSuggestImportedFunction('min', 'num', false);
      assertSuggestImportedFunction(
          'max',
          'num',
          false,
          CompletionRelevance.LOW);
      assertSuggestTopLevelVarGetterSetter('T1', 'String');
      assertNotSuggested('_T2');
      assertSuggestImportedTopLevelVar('T3', 'int', CompletionRelevance.LOW);
      assertNotSuggested('_T4');
      assertSuggestLocalTopLevelVar('T5', 'int');
      assertSuggestLocalTopLevelVar('_T6', null);
      assertNotSuggested('==');
      // TODO (danrubel) suggest HtmlElement as low relevance
      assertNotSuggested('HtmlElement');
    });
  }

  test_Block_inherited_imported() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addSource('/testB.dart', '''
      lib B;
      class F { var f1; f2() { } }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }''');
    addTestSource('''
      import "/testB.dart";
      class A extends E implements I with M {a() {^}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedGetter('e1', null);
      assertSuggestImportedGetter('f1', null);
      assertSuggestImportedGetter('i1', 'int');
      assertSuggestImportedGetter('m1', null);
      //TODO (danrubel) include declared type in suggestion
      assertSuggestImportedMethod('e2', null, null);
      assertSuggestImportedMethod('f2', null, null);
      assertSuggestImportedMethod('i2', null, null);
      //assertSuggestImportedMethod('m2', null, null);
      assertNotSuggested('==');
    });
  }

  test_Block_inherited_local() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
      class F { var f1; f2() { } }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }
      class A extends E implements I with M {a() {^}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalGetter('e1', null);
      assertSuggestLocalGetter('f1', null);
      assertSuggestLocalGetter('i1', 'int');
      assertSuggestLocalGetter('m1', null);
      assertSuggestLocalMethod('e2', 'E', null);
      assertSuggestLocalMethod('f2', 'F', null);
      assertSuggestLocalMethod('i2', 'I', null);
      assertSuggestLocalMethod('m2', 'M', 'int');
    });
  }

  test_CascadeExpression_selector1() {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addSource('/testB.dart', '''
      class B { }''');
    addTestSource('''
      import "/testB.dart";
      class A {var b; X _c;}
      class X{}
      // looks like a cascade to the parser
      // but the user is trying to get completions for a non-cascade
      main() {A a; a.^.z}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('b', null);
      assertSuggestInvocationGetter('_c', 'X');
      assertNotSuggested('Object');
      assertNotSuggested('A');
      assertNotSuggested('B');
      assertNotSuggested('X');
      assertNotSuggested('z');
      assertNotSuggested('==');
    });
  }

  test_CascadeExpression_selector2() {
    // SimpleIdentifier  PropertyAccess  CascadeExpression  ExpressionStatement
    addSource('/testB.dart', '''
      class B { }''');
    addTestSource('''
      import "/testB.dart";
      class A {var b; X _c;}
      class X{}
      main() {A a; a..^z}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('b', null);
      assertSuggestInvocationGetter('_c', 'X');
      assertNotSuggested('Object');
      assertNotSuggested('A');
      assertNotSuggested('B');
      assertNotSuggested('X');
      assertNotSuggested('z');
      assertNotSuggested('==');
    });
  }

  test_CascadeExpression_target() {
    // SimpleIdentifier  CascadeExpression  ExpressionStatement
    addTestSource('''
      class A {var b; X _c;}
      class X{}
      main() {A a; a^..b}''');
    computeFast();
    return computeFull(true).then((_) {
      assertNotSuggested('b');
      assertNotSuggested('_c');
      assertSuggestLocalVariable('a', 'A');
      assertSuggestLocalClass('A');
      assertSuggestLocalClass('X');
      assertSuggestImportedClass('Object');
      assertNotSuggested('==');
    });
  }

  test_CatchClause_typed() {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on E catch (e) {^}}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestParameter('e', 'E');
      assertSuggestLocalMethod('a', 'A', null);
      assertSuggestImportedClass('Object');
      assertNotSuggested('x');
    });
  }

  test_CatchClause_untyped() {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} catch (e, s) {^}}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestParameter('e', null);
      assertSuggestParameter('s', 'StackTrace');
      assertSuggestLocalMethod('a', 'A', null);
      assertSuggestImportedClass('Object');
      assertNotSuggested('x');
    });
  }

  test_ClassDeclaration_body() {
    // ClassDeclaration  CompilationUnit
    addSource('/testB.dart', '''
      class B { }''');
    addTestSource('''
      import "testB.dart" as x;
      @deprecated class A {^}
      class _B {}
      A T;''');
    computeFast();
    return computeFull(true).then((_) {
      CompletionSuggestion suggestionA = assertSuggestLocalClass('A');
      if (suggestionA != null) {
        expect(suggestionA.element.isDeprecated, isTrue);
        expect(suggestionA.element.isPrivate, isFalse);
      }
      CompletionSuggestion suggestionB = assertSuggestLocalClass('_B');
      if (suggestionB != null) {
        expect(suggestionB.element.isDeprecated, isFalse);
        expect(suggestionB.element.isPrivate, isTrue);
      }
      CompletionSuggestion suggestionO = assertSuggestImportedClass('Object');
      if (suggestionO != null) {
        expect(suggestionO.element.isDeprecated, isFalse);
        expect(suggestionO.element.isPrivate, isFalse);
      }
      assertSuggestLocalTopLevelVar('T', 'A');
      assertSuggestLibraryPrefix('x');
    });
  }

  test_Combinator_hide() {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('/testAB.dart', '''
      library libAB;
      part '/partAB.dart';
      class A { }
      class B { }''');
    addSource('/partAB.dart', '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      class PB { }''');
    addSource('/testCD.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" hide ^;
      import "/testCD.dart";
      class X {}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('A');
      assertSuggestImportedClass('B');
      assertSuggestImportedClass('PB');
      assertSuggestImportedTopLevelVar('T1', null);
      assertSuggestImportedFunction('F1', 'PB');
      assertNotSuggested('C');
      assertNotSuggested('D');
      assertNotSuggested('X');
      assertNotSuggested('Object');
    });
  }

  test_Combinator_show() {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('/testAB.dart', '''
      library libAB;
      part '/partAB.dart';
      class A { }
      class B { }''');
    addSource('/partAB.dart', '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      class PB { }''');
    addSource('/testCD.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" show ^;
      import "/testCD.dart";
      class X {}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('A');
      assertSuggestImportedClass('B');
      assertSuggestImportedClass('PB');
      assertSuggestImportedTopLevelVar('T1', null);
      assertSuggestImportedFunction('F1', 'PB');
      assertNotSuggested('C');
      assertNotSuggested('D');
      assertNotSuggested('X');
      assertNotSuggested('Object');
    });
  }

  test_ConstructorName_importedClass() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/testB.dart', '''
      lib B;
      int T1;
      F1() { }
      class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      var m;
      main() {new X.^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestNamedConstructor('c', 'X');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('_d');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_ConstructorName_localClass() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
      int T1;
      F1() { }
      class X {X.c(); X._d(); z() {}}
      main() {new X.^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestNamedConstructor('c', 'X');
      assertSuggestNamedConstructor('_d', 'X');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_ExpressionStatement_identifier() {
    // SimpleIdentifier  ExpressionStatement  Block
    addSource('/testA.dart', '''
      _B F1() { }
      class A {int x;}
      class _B { }''');
    addTestSource('''
      import "/testA.dart";
      class C {foo(){O^} void bar() {}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('A');
      assertSuggestImportedFunction('F1', '_B', false);
      assertSuggestLocalClass('C');
      assertSuggestLocalMethod('foo', 'C', null);
      assertSuggestLocalMethod('bar', 'C', 'void');
      assertSuggestLocalClass('C');
      assertNotSuggested('x');
      assertNotSuggested('_B');
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
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_FieldDeclaration_name_typed() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/testA.dart', 'class A { }');
    addTestSource('''
      import "/testA.dart";
      class C {A ^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_FieldDeclaration_name_var() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/testA.dart', 'class A { }');
    addTestSource('''
      import "/testA.dart";
      class C {var ^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_ForEachStatement_body_typed() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('foo', 'int');
      assertSuggestImportedClass('Object');
    });
  }

  test_ForEachStatement_body_untyped() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (foo in bar) {^}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('foo', null);
      assertSuggestImportedClass('Object');
    });
  }

  test_ForStatement_body() {
    // Block  ForStatement
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('i', 'int');
      assertSuggestImportedClass('Object');
    });
  }

  test_ForStatement_condition() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('index', 'int');
    });
  }

  test_ForStatement_initializer() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (^)}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', 'List');
      assertSuggestImportedClass('Object');
      assertSuggestImportedClass('int');
    });
  }

  test_ForStatement_updaters() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('index', 'int');
    });
  }

  test_ForStatement_updaters_prefix_expression() {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('''
      void bar() { }
      main() {for (int index = 0; index < 10; ++i^)}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('index', 'int');
      assertSuggestLocalFunction('main', null);
      assertNotSuggested('bar');
    });
  }

  test_FunctionExpression_body_function() {
    // Block  BlockFunctionBody  FunctionExpression
    addTestSource('''
      void bar() { }
      String foo(List args) {x.then((R b) {^});}''');
    computeFast();
    return computeFull(true).then((_) {
      var f = assertSuggestLocalFunction('foo', 'String', false);
      if (f != null) {
        expect(f.element.isPrivate, isFalse);
      }
      assertSuggestLocalFunction('bar', 'void');
      assertSuggestParameter('args', 'List');
      assertSuggestParameter('b', 'R');
      assertSuggestImportedClass('Object');
    });
  }

  test_IfStatement_condition() {
    // SimpleIdentifier  IfStatement  Block  BlockFunctionBody
    addTestSource('''
      class A {int x; int y() => 0;}
      main(){var a; if (^)}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', null);
      assertSuggestLocalFunction('main', null);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_ImportDirective_dart() {
    // SimpleStringLiteral  ImportDirective
    addTestSource('''
      import "dart^";
      main() {}''');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_InstanceCreationExpression_imported() {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} new ^}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('Object');
      assertSuggestImportedClass('A');
      assertSuggestLocalClass('B');
      assertSuggestLocalClass('C');
      assertNotSuggested('f');
      assertNotSuggested('x');
      assertNotSuggested('foo');
      assertNotSuggested('F1');
      assertNotSuggested('F2');
      assertNotSuggested('T1');
      assertNotSuggested('T2');
    });
  }

  test_InterpolationExpression() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \$^");}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('name', 'String');
      assertSuggestImportedClass('Object');
    });
  }

  test_InterpolationExpression_block() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('name', 'String');
      assertSuggestImportedClass('Object');
    });
  }

  test_InterpolationExpression_prefix_selector() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${name.^}");}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('length', 'int');
      assertNotSuggested('name');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_InterpolationExpression_prefix_target() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${nam^e.length}");}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('name', 'String');
      assertSuggestImportedClass('Object');
      assertNotSuggested('length');
    });
  }

  test_IsExpression() {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addSource('/testB.dart', '''
      lib B;
      foo() { }
      class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      class Y {Y.c(); Y._d(); z() {}}
      main() {var x; if (x is ^) { }}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('X');
      assertSuggestLocalClass('Y');
      assertNotSuggested('x');
      assertNotSuggested('main');
      assertNotSuggested('foo');
    });
  }

  test_IsExpression_target() {
    // IfStatement  Block  BlockFunctionBody
    addTestSource('''
      foo() { }
      void bar() { }
      class A {int x; int y() => 0;}
      main(){var a; if (^ is A)}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalVariable('a', null);
      assertSuggestLocalFunction('main', null);
      assertSuggestLocalFunction('foo', null);
      assertNotSuggested('bar');
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_IsExpression_type() {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
      class A {int x; int y() => 0;}
      main(){var a; if (a is ^)}''');
    computeFast();
    return computeFull(true).then((_) {
      assertNotSuggested('a');
      assertNotSuggested('main');
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_Literal_string() {
    // SimpleStringLiteral  ExpressionStatement  Block
    addTestSource('class A {a() {"hel^lo"}}');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_MethodDeclaration_body_getters() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X get f => 0; Z a() {^} get _g => 1;}');
    computeFast();
    return computeFull(true).then((_) {
      CompletionSuggestion methodA = assertSuggestLocalMethod('a', 'A', 'Z');
      if (methodA != null) {
        expect(methodA.element.isDeprecated, isFalse);
        expect(methodA.element.isPrivate, isFalse);
      }
      CompletionSuggestion getterF = assertSuggestLocalGetter('f', 'X');
      if (getterF != null) {
        expect(getterF.element.isDeprecated, isTrue);
        expect(getterF.element.isPrivate, isFalse);
      }
      CompletionSuggestion getterG = assertSuggestLocalGetter('_g', null);
      if (getterG != null) {
        expect(getterG.element.isDeprecated, isFalse);
        expect(getterG.element.isPrivate, isTrue);
      }
    });
  }

  test_MethodDeclaration_members() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X f; Z _a() {^} var _g;}');
    computeFast();
    return computeFull(true).then((_) {
      CompletionSuggestion methodA = assertSuggestLocalMethod('_a', 'A', 'Z');
      if (methodA != null) {
        expect(methodA.element.isDeprecated, isFalse);
        expect(methodA.element.isPrivate, isTrue);
      }
      CompletionSuggestion getterF = assertSuggestLocalGetter('f', 'X');
      if (getterF != null) {
        expect(getterF.element.isDeprecated, isTrue);
        expect(getterF.element.isPrivate, isFalse);
      }
      CompletionSuggestion getterG = assertSuggestLocalGetter('_g', null);
      if (getterG != null) {
        expect(getterG.element.isDeprecated, isFalse);
        expect(getterG.element.isPrivate, isTrue);
      }
      assertSuggestImportedClass('bool');
    });
  }

  test_MethodDeclaration_parameters_named() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated Z a(X x, _, b, {y: boo}) {^}}');
    computeFast();
    return computeFull(true).then((_) {
      CompletionSuggestion methodA = assertSuggestLocalMethod('a', 'A', 'Z');
      if (methodA != null) {
        expect(methodA.element.isDeprecated, isTrue);
        expect(methodA.element.isPrivate, isFalse);
      }
      assertSuggestParameter('x', 'X');
      assertSuggestParameter('y', null);
      assertSuggestParameter('b', null);
      assertSuggestImportedClass('int');
      assertNotSuggested('_');
    });
  }

  test_MethodDeclaration_parameters_positional() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
      foo() { }
      void bar() { }
      class A {Z a(X x, [int y=1]) {^}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestLocalFunction('foo', null);
      assertSuggestLocalFunction('bar', 'void');
      assertSuggestLocalMethod('a', 'A', 'Z');
      assertSuggestParameter('x', 'X');
      assertSuggestParameter('y', 'int');
      assertSuggestImportedClass('String');
    });
  }

  test_MethodInvocation_no_semicolon() {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      main() { }
      class I {X get f => new A();get _g => new A();}
      class A implements I {
        var b; X _c;
        X get d => new A();get _e => new A();
        // no semicolon between completion point and next statement
        set s1(I x) {} set _s2(I x) {x.^ m(null);}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('f', 'X');
      assertSuggestInvocationGetter('_g', null);
      assertNotSuggested('b');
      assertNotSuggested('_c');
      assertNotSuggested('d');
      assertNotSuggested('_e');
      assertNotSuggested('s1');
      assertNotSuggested('_s2');
      assertNotSuggested('m');
      assertNotSuggested('_n');
      assertNotSuggested('a');
      assertNotSuggested('A');
      assertNotSuggested('X');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_PrefixedIdentifier_class_imported() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class I {X get f => new A();get _g => new A();}
      class A implements I {
        var b; X _c;
        X get d => new A();get _e => new A();
        set s1(I x) {} set _s2(I x) {}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    addTestSource('''
      import "/testB.dart";
      main() {A a; a.^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('b', null);
      assertNotSuggested('_c');
      assertSuggestInvocationGetter('d', 'X');
      assertNotSuggested('_e');
      assertSuggestInvocationGetter('f', 'X');
      assertNotSuggested('_g');
      assertSuggestInvocationSetter('s1');
      assertNotSuggested('_s2');
      assertSuggestInvocationMethod('m', 'A', null);
      assertNotSuggested('_n');
      assertNotSuggested('a');
      assertNotSuggested('A');
      assertNotSuggested('X');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_PrefixedIdentifier_class_local() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
      main() {A a; a.^}
      class I {X get f => new A();get _g => new A();}
      class A implements I {
        var b; X _c;
        X get d => new A();get _e => new A();
        set s1(I x) {} set _s2(I x) {}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('b', null);
      assertSuggestInvocationGetter('_c', 'X');
      assertSuggestInvocationGetter('d', 'X');
      assertSuggestInvocationGetter('_e', null);
      assertSuggestInvocationGetter('f', 'X');
      assertSuggestInvocationGetter('_g', null);
      assertSuggestInvocationSetter('s1');
      assertSuggestInvocationSetter('_s2');
      assertSuggestInvocationMethod('m', 'A', null);
      assertSuggestInvocationMethod('_n', 'A', 'I');
      assertNotSuggested('a');
      assertNotSuggested('A');
      assertNotSuggested('X');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_PrefixedIdentifier_library() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      var T1;
      class X { }
      class Y { }''');
    addTestSource('''
      import "/testB.dart" as b;
      var T2;
      class A { }
      main() {b.^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationClass('X');
      assertSuggestInvocationClass('Y');
      assertSuggestInvocationTopLevelVar('T1', null);
      assertNotSuggested('T2');
      assertNotSuggested('Object');
      assertNotSuggested('b');
      assertNotSuggested('A');
      assertNotSuggested('==');
    });
  }

  test_PrefixedIdentifier_parameter() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class _W {M y; var _z;}
      class X extends _W {}
      class M{}''');
    addTestSource('''
      import "/testB.dart";
      foo(X x) {x.^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('y', 'M');
      assertNotSuggested('_z');
      assertNotSuggested('==');
    });
  }

  test_PrefixedIdentifier_prefix() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testA.dart', '''
      class A {static int bar = 10;}
      _B() {}''');
    addTestSource('''
      import "/testA.dart";
      class X {foo(){A^.bar}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('A');
      assertSuggestLocalClass('X');
      assertSuggestLocalMethod('foo', 'X', null);
      assertNotSuggested('bar');
      assertNotSuggested('_B');
    });
  }

  test_PropertyAccess_expression() {
    // SimpleIdentifier  MethodInvocation  PropertyAccess  ExpressionStatement
    addTestSource('class A {a() {"hello".to^String().length}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('length', 'int');
      assertNotSuggested('A');
      assertNotSuggested('a');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_PropertyAccess_selector() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement  Block
    addTestSource('class A {a() {"hello".length.^}}');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestInvocationGetter('isEven', 'bool');
      assertNotSuggested('A');
      assertNotSuggested('a');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_TopLevelVariableDeclaration_typed_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} B ^');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_TopLevelVariableDeclaration_untyped_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} var ^');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_VariableDeclaration_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addSource('/testB.dart', '''
      lib B;
      foo() { }
      class _B { }
      class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      class Y {Y.c(); Y._d(); z() {}}
      main() {var ^}''');
    computeFast();
    return computeFull(true).then((_) {
      assertNoSuggestions();
    });
  }

  test_VariableDeclarationStatement_RHS() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addSource('/testB.dart', '''
      lib B;
      foo() { }
      class _B { }
      class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      class Y {Y.c(); Y._d(); z() {}}
      class C {bar(){var f; {var x;} var e = ^}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('X');
      assertNotSuggested('_B');
      assertSuggestLocalClass('Y');
      assertSuggestLocalClass('C');
      assertSuggestLocalVariable('f', null);
      assertNotSuggested('x');
      assertNotSuggested('e');
    });
  }

  test_VariableDeclarationStatement_RHS_missing_semicolon() {
    // VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addSource('/testB.dart', '''
      lib B;
      foo1() { }
      void bar1() { }
      class _B { }
      class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      foo2() { }
      void bar2() { }
      class Y {Y.c(); Y._d(); z() {}}
      class C {bar(){var f; {var x;} var e = ^ var g}}''');
    computeFast();
    return computeFull(true).then((_) {
      assertSuggestImportedClass('X');
      assertSuggestImportedFunction('foo1', null);
      assertNotSuggested('bar1');
      assertSuggestLocalFunction('foo2', null);
      assertNotSuggested('bar2');
      assertNotSuggested('_B');
      assertSuggestLocalClass('Y');
      assertSuggestLocalClass('C');
      assertSuggestLocalVariable('f', null);
      assertNotSuggested('x');
      assertNotSuggested('e');
    });
  }
}

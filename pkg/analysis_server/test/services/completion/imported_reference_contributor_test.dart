// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/imported_reference_contributor.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';
import '../../operation/operation_queue_test.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(ImportedReferenceContributorTest);
}

@reflectiveTest
class ImportedReferenceContributorTest extends AbstractSelectorSuggestionTest {
  void assertCached(String completion) {
    DartCompletionCache cache = request.cache;
    if (!isCached(cache.importedTypeSuggestions, completion) &&
        !isCached(cache.importedVoidReturnSuggestions, completion) &&
        !isCached(cache.libraryPrefixSuggestions, completion) &&
        !isCached(cache.otherImportedSuggestions, completion)) {
      fail('expected $completion to be cached');
    }
  }

  /**
   * Assert that the ImportedReferenceContributor uses cached results
   * to produce identical suggestions to the original set of suggestions.
   */
  @override
  assertCachedCompute(_) {
    if (!(contributor as ImportedReferenceContributor).shouldWaitForLowPrioritySuggestions) {
      return null;
    }
    List<CompletionSuggestion> oldSuggestions = request.suggestions;
    /*
     * Simulate a source change to flush the cached compilation unit
     */
    ChangeSet changes = new ChangeSet();
    changes.addedSource(testSource);
    context.applyChanges(changes);
    /*
     * Calculate a new completion at the same location
     */
    setUpContributor();
    int replacementOffset = request.replacementOffset;
    int replacementLength = request.replacementLength;
    AnalysisServer server = new AnalysisServerMock();
    /*
     * Pass null for searchEngine to ensure that it is not used
     * when the cache has been populated.
     */
    request = new DartCompletionRequest(
        server, context, testSource, completionOffset, cache);
    request.replacementOffset = replacementOffset;
    request.replacementLength = replacementLength;

    void assertResultsFromCache(List<CompletionSuggestion> oldSuggestions) {
      List<CompletionSuggestion> newSuggestions = request.suggestions;
      if (newSuggestions.length == oldSuggestions.length) {
        if (!oldSuggestions
            .any((CompletionSuggestion s) => !newSuggestions.contains(s))) {
          return;
        }
      }
      StringBuffer sb = new StringBuffer(
          'suggestions based upon cached results do not match expectations');
      sb.write('\n  Expected:');
      oldSuggestions.toList()
        ..sort(suggestionComparator)
        ..forEach((CompletionSuggestion suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
      sb.write('\n  Actual:');
      newSuggestions.toList()
        ..sort(suggestionComparator)
        ..forEach((CompletionSuggestion suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
      fail(sb.toString());
    }

    computeFastResult = null;
    if (computeFast()) {
      expect(request.unit.element, isNull);
      assertResultsFromCache(oldSuggestions);
    } else {
      // Results from cache might need to be adjusted
      // if target is a function argument in an argument list
      resolve(false);
      return contributor.computeFull(request).then((bool result) {
        expect(result, isTrue);
        expect(request.unit.element, isNotNull);
        assertResultsFromCache(oldSuggestions);
      });
    }
  }

  void assertNotCached(String completion) {
    DartCompletionCache cache = request.cache;
    if (isCached(cache.importedTypeSuggestions, completion) ||
        isCached(cache.importedVoidReturnSuggestions, completion) ||
        isCached(cache.libraryPrefixSuggestions, completion) ||
        isCached(cache.otherImportedSuggestions, completion)) {
      fail('expected $completion NOT to be cached');
    }
  }

  @override
  CompletionSuggestion assertSuggestImportedClass(String name,
      {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT, String importUri}) {
    return assertSuggestClass(name,
        relevance: relevance, kind: kind, importUri: importUri);
  }

  @override
  CompletionSuggestion assertSuggestImportedConstructor(String name,
      {int relevance: DART_RELEVANCE_DEFAULT, String importUri}) {
    return assertSuggestConstructor(name,
        relevance: relevance, importUri: importUri);
  }

  @override
  CompletionSuggestion assertSuggestImportedField(String name, String type,
      {int relevance: DART_RELEVANCE_INHERITED_FIELD, String importUri}) {
    return assertSuggestField(name, type,
        relevance: relevance, importUri: importUri);
  }

  @override
  CompletionSuggestion assertSuggestImportedFunction(
      String name, String returnType,
      {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool deprecated: false, int relevance: DART_RELEVANCE_DEFAULT,
      String importUri}) {
    return assertSuggestFunction(name, returnType,
        kind: kind,
        deprecated: deprecated,
        relevance: relevance,
        importUri: importUri);
  }

  @override
  CompletionSuggestion assertSuggestImportedFunctionTypeAlias(
      String name, String returnType, [bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String importUri]) {
    return assertSuggestFunctionTypeAlias(
        name, returnType, isDeprecated, relevance, kind, importUri);
  }

  CompletionSuggestion assertSuggestImportedGetter(
      String name, String returnType,
      {int relevance: DART_RELEVANCE_INHERITED_ACCESSOR, String importUri}) {
    return assertSuggestGetter(name, returnType,
        relevance: relevance, importUri: importUri);
  }

  CompletionSuggestion assertSuggestImportedMethod(
      String name, String declaringType, String returnType,
      {int relevance: DART_RELEVANCE_INHERITED_METHOD, String importUri}) {
    return assertSuggestMethod(name, declaringType, returnType,
        relevance: relevance, importUri: importUri);
  }

  CompletionSuggestion assertSuggestImportedSetter(String name,
      {int relevance: DART_RELEVANCE_INHERITED_ACCESSOR, String importUri}) {
    return assertSuggestSetter(name, relevance, importUri);
  }

  @override
  CompletionSuggestion assertSuggestImportedTopLevelVar(
      String name, String returnType, [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String importUri]) {
    return assertSuggestTopLevelVar(
        name, returnType, relevance, kind, importUri);
  }

  @override
  CompletionSuggestion assertSuggestLibraryPrefix(String prefix,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    CompletionSuggestion cs =
        assertSuggest(prefix, csKind: kind, relevance: relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LIBRARY));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  fail_enum_deprecated() {
    addSource('/libA.dart', 'library A; @deprecated enum E { one, two }');
    addTestSource('import "/libA.dart"; main() {^}');
    return computeFull((bool result) {
      // TODO(danrube) investigate why suggestion/element is not deprecated
      // when AST node has correct @deprecated annotation
      assertSuggestEnum('E', isDeprecated: true);
      assertNotSuggested('one');
      assertNotSuggested('two');
    });
  }

  bool isCached(List<CompletionSuggestion> suggestions, String completion) =>
      suggestions.any((CompletionSuggestion s) => s.completion == completion);

  @override
  void setUpContributor() {
    contributor = new ImportedReferenceContributor(
        shouldWaitForLowPrioritySuggestions: true);
  }

  @override
  test_ArgumentList() {
    return super.test_ArgumentList().then((_) {
      expect(request.cache.importKey, "import '/libA.dart';");
      ClassElement objClassElem1 = request.cache.importedClassMap['Object'];
      expect(objClassElem1, isNotNull);
      ClassElement objClassElem2 = request.cache.objectClassElement;
      expect(objClassElem1, same(objClassElem2));
    });
  }

  @override
  test_ArgumentList_imported_function() {
    return super.test_ArgumentList_imported_function().then((_) {
      expect(request.cache.importKey, "import '/libA.dart';");
    });
  }

  @override
  test_AssignmentExpression_RHS() {
    return super.test_AssignmentExpression_RHS().then((_) {
      expect(request.cache.importKey, '');
    });
  }

  @override
  test_Block() {
    return super.test_Block().then((_) {
      expect(request.cache.importKey,
          'import "/testAB.dart";import "/testCD.dart" hide D;import "/testEEF.dart" show EE;import "/testG.dart" as g;');
      assertCached('A');
      assertCached('T3');
    });
  }

  @override
  test_Block_inherited_imported() {
    return super.test_Block_inherited_imported().then((_) {
      assertCached('E');
      assertCached('F');
      assertNotCached('e1');
      assertNotCached('i2');
      assertNotCached('m1');
      assertNotCached('_pf');
    });
  }

  test_Block_partial_results() {
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
    ImportedReferenceContributor contributor = this.contributor;
    contributor.shouldWaitForLowPrioritySuggestions = false;
    computeFast();
    return computeFull((bool result) {
      assertSuggestImportedClass('C');
      // Assert contributor does not wait for or include low priority results
      // from non-imported libraries unless instructed to do so.
      assertNotSuggested('H');
    });
  }

  test_enum() {
    addSource('/libA.dart', 'library A; enum E { one, two }');
    addTestSource('import "/libA.dart"; main() {^}');
    return computeFull((bool result) {
      assertSuggestEnum('E');
      assertNotSuggested('one');
      assertNotSuggested('two');
    });
  }

  test_function_parameters_mixed_required_and_named() {
    addSource('/libA.dart', '''
void m(x, {int y}) {}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestFunction('m', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_function_parameters_mixed_required_and_positional() {
    addSource('/libA.dart', '''
void m(x, [int y]) {}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestFunction('m', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_function_parameters_named() {
    addSource('/libA.dart', '''
void m({x, int y}) {}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestFunction('m', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_function_parameters_none() {
    addSource('/libA.dart', '''
void m() {}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    computeFast();
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestFunction('m', 'void');
      expect(suggestion.parameterNames, isEmpty);
      expect(suggestion.parameterTypes, isEmpty);
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_function_parameters_positional() {
    addSource('/libA.dart', '''
void m([x, int y]) {}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestFunction('m', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_function_parameters_required() {
    addSource('/libA.dart', '''
void m(x, int y) {}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestFunction('m', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 2);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_InstanceCreationExpression() {
    addSource('/testA.dart', '''
class A {foo(){var f; {var x;}}}
class B {B(this.x, [String boo]) { } int x;}
class C {C.bar({boo: 'hoo', int z: 0}) { } }''');
    addTestSource('''
import "/testA.dart";
import "dart:math" as math;
main() {new ^ String x = "hello";}''');
    computeFast();
    return computeFull((bool result) {
      CompletionSuggestion suggestion;

      suggestion = assertSuggestImportedConstructor('Object');
      expect(suggestion.element.parameters, '()');
      expect(suggestion.parameterNames, hasLength(0));
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);

      suggestion = assertSuggestImportedConstructor('A');
      expect(suggestion.element.parameters, '()');
      expect(suggestion.parameterNames, hasLength(0));
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);

      suggestion = assertSuggestImportedConstructor('B');
      expect(suggestion.element.parameters, '(int x, [String boo])');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'int');
      expect(suggestion.parameterNames[1], 'boo');
      expect(suggestion.parameterTypes[1], 'String');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, false);

      suggestion = assertSuggestImportedConstructor('C.bar');
      expect(
          suggestion.element.parameters, "({dynamic boo: 'hoo'}, {int z: 0})");
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'boo');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'z');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, true);

      assertSuggestLibraryPrefix('math');
    });
  }

  test_internal_sdk_libs() {
    addTestSource('main() {p^}');
    computeFast();
    return computeFull((bool result) {
      assertSuggest('print');
      assertSuggest('pow',
          relevance: DART_RELEVANCE_LOW, importUri: 'dart:math');
      // Do not suggest completions from internal SDK library
      assertNotSuggested('printToConsole');
    });
  }

  test_method_parameters_mixed_required_and_named() {
    addSource('/libA.dart', '''
class A {
  void m(x, {int y}) {}
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion =
          assertSuggestImportedMethod('m', 'A', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_method_parameters_mixed_required_and_positional() {
    addSource('/libA.dart', '''
class A {
  void m(x, [int y]) {}
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion =
          assertSuggestImportedMethod('m', 'A', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_named() {
    addSource('/libA.dart', '''
class A {
  void m({x, int y}) {}
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion =
          assertSuggestImportedMethod('m', 'A', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_method_parameters_none() {
    addSource('/libA.dart', '''
class A {
  void m() {}
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    computeFast();
    return computeFull((bool result) {
      CompletionSuggestion suggestion =
          assertSuggestImportedMethod('m', 'A', 'void');
      expect(suggestion.parameterNames, isEmpty);
      expect(suggestion.parameterTypes, isEmpty);
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_positional() {
    addSource('/libA.dart', '''
class A {
  void m([x, int y]) {}
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion =
          assertSuggestImportedMethod('m', 'A', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_required() {
    addSource('/libA.dart', '''
class A {
  void m(x, int y) {}
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion =
          assertSuggestImportedMethod('m', 'A', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 2);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_mixin_ordering() {
    addSource('/libA.dart', '''
class B {}
class M1 {
  void m() {}
}
class M2 {
  void m() {}
}
''');
    addTestSource('''
import '/libA.dart';
class C extends B with M1, M2 {
  void f() {
    ^
  }
}
''');
    return computeFull((bool result) {
      assertSuggestImportedMethod('m', 'M2', 'void');
    });
  }

  /**
   * Ensure that completions in one context don't appear in another
   */
  test_multiple_contexts() {

    // Create a 2nd context with source
    var context2 = AnalysisEngine.instance.createAnalysisContext();
    context2.sourceFactory =
        new SourceFactory([AbstractContextTest.SDK_RESOLVER, resourceResolver]);
    String content2 = 'class ClassFromAnotherContext { }';
    Source source2 =
        provider.newFile('/context2/foo.dart', content2).createSource();
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source2);
    context2.applyChanges(changeSet);
    context2.setContents(source2, content2);

    // Resolve the source in the 2nd context and update the index
    var result = context2.performAnalysisTask();
    while (result.hasMoreWork) {
      result.changeNotices.forEach((ChangeNotice notice) {
        CompilationUnit unit = notice.resolvedDartUnit;
        if (unit != null) {
          index.indexUnit(context2, unit);
        }
      });
      result = context2.performAnalysisTask();
    }

    // Check that source in 2nd context does not appear in completion in 1st
    addSource('/context1/libA.dart', '''
      library libA;
      class ClassInLocalContext {int x;}''');
    testFile = '/context1/completionTest.dart';
    addTestSource('''
      import "/context1/libA.dart";
      import "/foo.dart";
      main() {C^}
      ''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestImportedClass('ClassInLocalContext');
      // Assert contributor does not include results from 2nd context.
      assertNotSuggested('ClassFromAnotherContext');
    });
  }

  test_no_parameters_field() {
    addSource('/libA.dart', '''
class A {
  int x;
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestImportedField('x', 'int');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_no_parameters_getter() {
    addSource('/libA.dart', '''
class A {
  int get x => null;
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestImportedGetter('x', 'int');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_no_parameters_setter() {
    addSource('/libA.dart', '''
class A {
  set x(int value) {};
}
''');
    addTestSource('''
import '/libA.dart';
class B extends A {
  main() {^}
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestImportedSetter('x');
      assertHasNoParameterInfo(suggestion);
    });
  }

  @override
  test_partFile_TypeName() {
    return super.test_partFile_TypeName().then((_) {
      expect(request.cache.importKey, 'part of libA;');
    });
  }

  @override
  test_partFile_TypeName2() {
    return super.test_partFile_TypeName2().then((_) {
      expect(request.cache.importKey,
          'library libA;import "/testB.dart";part "/testA.dart";');
    });
  }
}

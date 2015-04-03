// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.util;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/common_usage_computer.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';

int suggestionComparator(CompletionSuggestion s1, CompletionSuggestion s2) {
  String c1 = s1.completion.toLowerCase();
  String c2 = s2.completion.toLowerCase();
  return c1.compareTo(c2);
}

abstract class AbstractCompletionTest extends AbstractContextTest {
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
  DartCompletionCache cache;
  DartCompletionManager _completionManager;

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
    cache = new DartCompletionCache(context, testSource);
    request = new DartCompletionRequest(context, searchEngine, testSource,
        completionOffset, cache, new CompletionPerformance());
  }

  void assertHasNoParameterInfo(CompletionSuggestion suggestion) {
    expect(suggestion.parameterNames, isNull);
    expect(suggestion.parameterTypes, isNull);
    expect(suggestion.requiredParameterCount, isNull);
    expect(suggestion.hasNamedParameters, isNull);
  }

  void assertHasParameterInfo(CompletionSuggestion suggestion) {
    expect(suggestion.parameterNames, isNotNull);
    expect(suggestion.parameterTypes, isNotNull);
    expect(suggestion.parameterNames.length, suggestion.parameterTypes.length);
    expect(suggestion.requiredParameterCount,
        lessThanOrEqualTo(suggestion.parameterNames.length));
    expect(suggestion.hasNamedParameters, isNotNull);
  }

  void assertNoSuggestions({CompletionSuggestionKind kind: null}) {
    if (kind == null) {
      if (request.suggestions.length > 0) {
        failedCompletion('Expected no suggestions', request.suggestions);
      }
      return;
    }
    CompletionSuggestion suggestion = request.suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.kind == kind, orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  CompletionSuggestion assertNotSuggested(String completion) {
    CompletionSuggestion suggestion = request.suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.completion == completion,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
    return null;
  }

  CompletionSuggestion assertSuggest(String completion,
      {CompletionSuggestionKind csKind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT,
      protocol.ElementKind elemKind: null, bool isDeprecated: false,
      bool isPotential: false}) {
    CompletionSuggestion cs =
        getSuggest(completion: completion, csKind: csKind, elemKind: elemKind);
    if (cs == null) {
      failedCompletion(
          'expected $completion $csKind $elemKind', request.suggestions);
    }
    expect(cs.kind, equals(csKind));
    if (isDeprecated) {
      expect(cs.relevance, equals(DART_RELEVANCE_LOW));
    } else {
      expect(cs.relevance, equals(relevance));
    }
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
    return cs;
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

  CompletionSuggestion assertSuggestClass(String name,
      {int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind, relevance: relevance, isDeprecated: isDeprecated);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestClassTypeAlias(String name,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    CompletionSuggestion cs =
        assertSuggest(name, csKind: kind, relevance: relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS_TYPE_ALIAS));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestConstructor(String name,
      {int relevance: DART_RELEVANCE_DEFAULT}) {
    CompletionSuggestion cs = assertSuggest(name, relevance: relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CONSTRUCTOR));
    int index = name.indexOf('.');
    expect(element.name, index >= 0 ? name.substring(index + 1) : '');
    return cs;
  }

  CompletionSuggestion assertSuggestField(String name, String type,
      {int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        elemKind: protocol.ElementKind.FIELD,
        isDeprecated: isDeprecated);
    // The returnType represents the type of a field
    expect(cs.returnType, type != null ? type : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FIELD));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    // The returnType represents the type of a field
    expect(element.returnType, type != null ? type : 'dynamic');
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestFunction(String name, String returnType,
      {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool deprecated: false, int relevance: DART_RELEVANCE_DEFAULT}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind, relevance: relevance, isDeprecated: deprecated);
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(deprecated));
    String param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    expect(element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestFunctionTypeAlias(
      String name, String returnType, bool isDeprecated,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind, relevance: relevance, isDeprecated: isDeprecated);
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION_TYPE_ALIAS));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    // TODO (danrubel) Determine why params are null
//    String param = element.parameters;
//    expect(param, isNotNull);
//    expect(param[0], equals('('));
//    expect(param[param.length - 1], equals(')'));
    expect(element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    // TODO (danrubel) Determine why param info is missing
//    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestGetter(String name, String returnType,
      {int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        elemKind: protocol.ElementKind.GETTER,
        isDeprecated: isDeprecated);
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.GETTER));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestLabel(String name,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.IDENTIFIER]) {
    CompletionSuggestion cs =
        assertSuggest(name, csKind: kind, relevance: relevance);
    expect(cs.returnType, isNull);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.flags, 0);
    expect(element.kind, equals(protocol.ElementKind.LABEL));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestLibraryPrefix(String prefix,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    // Library prefix should only be suggested by ImportedComputer
    return assertNotSuggested(prefix);
  }

  CompletionSuggestion assertSuggestMethod(
      String name, String declaringType, String returnType,
      {int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind, relevance: relevance, isDeprecated: isDeprecated);
    expect(cs.declaringType, equals(declaringType));
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.METHOD));
    expect(element.name, equals(name));
    String param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, returnType != null ? returnType : 'dynamic');
    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestNamedConstructor(
      String name, String returnType, [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    if (computer is InvocationComputer) {
      CompletionSuggestion cs =
          assertSuggest(name, csKind: kind, relevance: relevance);
      protocol.Element element = cs.element;
      expect(element, isNotNull);
      expect(element.kind, equals(protocol.ElementKind.CONSTRUCTOR));
      expect(element.name, equals(name));
      String param = element.parameters;
      expect(param, isNotNull);
      expect(param[0], equals('('));
      expect(param[param.length - 1], equals(')'));
      expect(element.returnType, equals(returnType));
      assertHasParameterInfo(cs);
      return cs;
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestParameter(String name, String returnType,
      {int relevance: DART_RELEVANCE_PARAMETER}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestSetter(String name,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        elemKind: protocol.ElementKind.SETTER);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.SETTER));
    expect(element.name, equals(name));
    // TODO (danrubel) assert setter param
    //expect(element.parameters, isNull);
    // TODO (danrubel) it would be better if this was always null
    if (element.returnType != null) {
      expect(element.returnType, 'dynamic');
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestTopLevelVar(String name, String returnType,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    CompletionSuggestion cs =
        assertSuggest(name, csKind: kind, relevance: relevance);
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.TOP_LEVEL_VARIABLE));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, returnType != null ? returnType : 'dynamic');
    assertHasNoParameterInfo(cs);
    return cs;
  }

  void assertSuggestTopLevelVarGetterSetter(String name, String returnType,
      [int relevance = DART_RELEVANCE_DEFAULT]) {
    if (computer is ImportedComputer) {
      assertSuggestGetter(name, returnType);
      assertSuggestSetter(name);
    } else {
      assertNotSuggested(name);
    }
  }

  bool computeFast() {
    _computeFastCalled = true;
    _completionManager = new DartCompletionManager(context, searchEngine,
        testSource, cache, [computer], new CommonUsageComputer({}));
    var result = _completionManager.computeFast(request);
    expect(request.replacementOffset, isNotNull);
    expect(request.replacementLength, isNotNull);
    return result.isEmpty;
  }

  Future computeFull(assertFunction(bool result), {bool fullAnalysis: true}) {
    if (!_computeFastCalled) {
      expect(computeFast(), isFalse);
    }
    resolve(fullAnalysis);
    return computer.computeFull(request).then(assertFunction);
  }

  void failedCompletion(String message,
      [Iterable<CompletionSuggestion> completions]) {
    StringBuffer sb = new StringBuffer(message);
    if (completions != null) {
      sb.write('\n  found');
      completions.toList()
        ..sort(suggestionComparator)
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

  CompletionSuggestion getSuggest({String completion: null,
      CompletionSuggestionKind csKind: null,
      protocol.ElementKind elemKind: null}) {
    CompletionSuggestion cs;
    request.suggestions.forEach((CompletionSuggestion s) {
      if (completion != null && completion != s.completion) {
        return;
      }
      if (csKind != null && csKind != s.kind) {
        return;
      }
      if (elemKind != null) {
        protocol.Element element = s.element;
        if (element == null || elemKind != element.kind) {
          return;
        }
      }
      if (cs == null) {
        cs = s;
      } else {
        failedCompletion('expected exactly one $cs',
            request.suggestions.where((s) => s.completion == completion));
      }
    });
    return cs;
  }

  void resolve(bool fullAnalysis) {

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
        CompilationUnit unit = notice.resolvedDartUnit;
        if (unit != null) {
          index.indexUnit(context, unit);
        }
      });

      // If the unit has been resolved, then finish the completion
      List<Source> libSourceList = context.getLibrariesContaining(testSource);
      if (libSourceList.length > 0) {
        LibraryElement library = context.getLibraryElement(libSourceList[0]);
        if (library != null) {
          CompilationUnit unit =
              context.getResolvedCompilationUnit(testSource, library);
          if (unit != null) {
            request.unit = unit;
            request.target =
                new CompletionTarget.forOffset(unit, completionOffset);
            resolved = true;
            if (!fullAnalysis) {
              break;
            }
          }
        }
      }

      result = context.performAnalysisTask();
    }
    if (!resolved) {
      fail('expected unit to be resolved');
    }
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    setUpComputer();
  }

  void setUpComputer();
}

/**
 * Common tests for `ImportedTypeComputerTest`, `InvocationComputerTest`,
 * and `LocalComputerTest`.
 */
abstract class AbstractSelectorSuggestionTest extends AbstractCompletionTest {

  /**
   * Assert that the ImportedComputer uses cached results to produce identical
   * suggestions to the original set of suggestions.
   */
  void assertCachedCompute(_) {
    // Subclasses override
  }

  CompletionSuggestion assertSuggestImportedClass(String name,
      {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    if (computer is ImportedComputer) {
      return assertSuggestClass(name, relevance: relevance, kind: kind);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedConstructor(String name,
      {int relevance: DART_RELEVANCE_DEFAULT}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestImportedField(String name, String type,
      {int relevance: DART_RELEVANCE_INHERITED_FIELD}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestImportedFunction(
      String name, String returnType,
      {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool deprecated: false, int relevance: DART_RELEVANCE_DEFAULT}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestImportedFunctionTypeAlias(
      String name, String returnType, [bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    if (computer is ImportedComputer) {
      return assertSuggestFunctionTypeAlias(
          name, returnType, isDeprecated, relevance, kind);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestImportedGetter(
      String name, String returnType,
      {int relevance: DART_RELEVANCE_INHERITED_ACCESSOR}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestImportedMethod(
      String name, String declaringType, String returnType,
      {int relevance: DART_RELEVANCE_INHERITED_METHOD}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestImportedSetter(String name,
      {int relevance: DART_RELEVANCE_INHERITED_ACCESSOR}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestImportedTopLevelVar(
      String name, String returnType, [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    if (computer is ImportedComputer) {
      return assertSuggestTopLevelVar(name, returnType, relevance, kind);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationClass(String name,
      [int relevance = DART_RELEVANCE_DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestClass(name, relevance: relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationField(String name, String type,
      {int relevance: DART_RELEVANCE_DEFAULT, bool isDeprecated: false}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestInvocationGetter(
      String name, String returnType,
      {int relevance: DART_RELEVANCE_DEFAULT, bool isDeprecated: false}) {
    if (computer is InvocationComputer) {
      return assertSuggestGetter(name, returnType,
          relevance: relevance, isDeprecated: isDeprecated);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationMethod(
      String name, String declaringType, String returnType,
      [int relevance = DART_RELEVANCE_DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestMethod(name, declaringType, returnType,
          relevance: relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationSetter(String name,
      [int relevance = DART_RELEVANCE_DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestSetter(name);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestInvocationTopLevelVar(
      String name, String returnType,
      [int relevance = DART_RELEVANCE_DEFAULT]) {
    if (computer is InvocationComputer) {
      return assertSuggestTopLevelVar(name, returnType, relevance);
    } else {
      return assertNotSuggested(name);
    }
  }

  CompletionSuggestion assertSuggestLocalClass(String name,
      {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT, bool isDeprecated: false}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalClassTypeAlias(String name,
      {int relevance: DART_RELEVANCE_DEFAULT}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalConstructor(String name) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalField(String name, String type,
      {int relevance: DART_RELEVANCE_LOCAL_FIELD, bool deprecated: false}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalFunction(
      String name, String returnType, {bool deprecated: false,
      int relevance: DART_RELEVANCE_LOCAL_FUNCTION,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalFunctionTypeAlias(
      String name, String returnType,
      {bool deprecated: false, int relevance: DART_RELEVANCE_DEFAULT}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalGetter(String name, String returnType,
      {int relevance: DART_RELEVANCE_LOCAL_ACCESSOR, bool deprecated: false}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalMethod(
      String name, String declaringType, String returnType,
      {int relevance: DART_RELEVANCE_LOCAL_METHOD, bool deprecated: false}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalSetter(String name,
      {int relevance: DART_RELEVANCE_LOCAL_ACCESSOR}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalTopLevelVar(
      String name, String returnType,
      {int relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestLocalVariable(
      String name, String returnType,
      {int relevance: DART_RELEVANCE_LOCAL_VARIABLE}) {
    return assertNotSuggested(name);
  }

  CompletionSuggestion assertSuggestNonLocalClass(String name,
      [int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION]) {
    return assertSuggestImportedClass(name, relevance: relevance, kind: kind);
  }

  Future computeFull(assertFunction(bool result), {bool fullAnalysis: true}) {
    return super
        .computeFull(assertFunction, fullAnalysis: fullAnalysis)
        .then(assertCachedCompute);
  }

  test_ArgumentList() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart';
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String');
      assertSuggestImportedFunction('hasLength', 'bool');
      assertSuggestImportedFunction('identical', 'bool');
      assertSuggestLocalClass('B');
      assertSuggestImportedClass('Object');
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_imported_function() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(arg) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B { }
      String bar() => true;
      void main() {expect(^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String');
      assertSuggestImportedFunction('hasLength', 'bool');
      assertSuggestImportedFunction('identical', 'bool');
      assertSuggestLocalClass('B');
      assertSuggestImportedClass('Object');
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_InstanceCreationExpression_functionalArg() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      class A { A(f()) { } }
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import 'dart:async';
      import '/libA.dart';
      class B { }
      String bar() => true;
      void main() {new A(^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('hasLength', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('identical', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestLocalClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('A',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('Object',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_InstanceCreationExpression_typedefArg() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      typedef Funct();
      class A { A(Funct f) { } }
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import 'dart:async';
      import '/libA.dart';
      class B { }
      String bar() => true;
      void main() {new A(^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('hasLength', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('identical', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestLocalClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('A',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('Object',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_local_function() {
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
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String');
      assertSuggestImportedFunction('hasLength', 'bool');
      assertSuggestImportedFunction('identical', 'bool');
      assertSuggestLocalClass('B');
      assertSuggestImportedClass('Object');
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_local_method() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import '/libA.dart'
      class B {
        expect(arg) { }
        void foo() {expect(^)}}
      String bar() => true;''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String');
      assertSuggestImportedFunction('hasLength', 'bool');
      assertSuggestImportedFunction('identical', 'bool');
      assertSuggestLocalClass('B');
      assertSuggestImportedClass('Object');
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_MethodInvocation_functionalArg() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      class A { A(f()) { } }
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import 'dart:async';
      import '/libA.dart';
      class B { }
      String bar(f()) => true;
      void main() {bar(^);}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestLocalFunction('bar', 'String',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('hasLength', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('identical', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestLocalClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('A',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('Object',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_MethodInvocation_methodArg() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/libA.dart', '''
      library A;
      class A { A(f()) { } }
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import 'dart:async';
      import '/libA.dart';
      class B { String bar(f()) => true; }
      void main() {new B().bar(^);}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
      assertSuggestImportedFunction('hasLength', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedFunction('identical', 'bool',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestLocalClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('A',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestImportedClass('Object',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('main');
      assertNotSuggested('baz');
      assertNotSuggested('print');
    });
  }

  test_ArgumentList_namedParam() {
    // SimpleIdentifier  NamedExpression  ArgumentList  MethodInvocation
    // ExpressionStatement
    addSource('/libA.dart', '''
      library A;
      bool hasLength(int expected) { }''');
    addTestSource('''
      import '/libA.dart'
      String bar() => true;
      void main() {expect(foo: ^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalFunction('bar', 'String');
      assertSuggestImportedFunction('hasLength', 'bool');
      assertNotSuggested('main');
    });
  }

  test_AsExpression() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
      class A {var b; X _c; foo() {var a; (a as ^).foo();}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('b');
      assertNotSuggested('_c');
      assertSuggestImportedClass('Object');
      assertSuggestLocalClass('A');
      assertNotSuggested('==');
    });
  }

  test_AssignmentExpression_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int ^b = 1;}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_AssignmentExpression_RHS() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int b = ^}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalVariable('a', 'int');
      assertSuggestLocalFunction('main', null);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_AssignmentExpression_type() {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      class A {} main() {
        int a;
        ^ b = 1;}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('int');
      // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
      // the user may be either (1) entering a type for the assignment
      // or (2) starting a new statement.
      // Consider suggesting only types
      // if only spaces separates the 1st and 2nd identifiers.
      //assertNotSuggested('a');
      //assertNotSuggested('main');
      //assertNotSuggested('identical');
    });
  }

  test_AssignmentExpression_type_newline() {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      class A {} main() {
        int a;
        ^
        b = 1;}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('int');
      // Allow non-types preceding an identifier on LHS of assignment
      // if newline follows first identifier
      // because user is probably starting a new statement
      assertSuggestLocalVariable('a', 'int');
      assertSuggestLocalFunction('main', null);
      assertSuggestImportedFunction('identical', 'bool');
    });
  }

  test_AssignmentExpression_type_partial() {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      class A {} main() {
        int a;
        int^ b = 1;}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 3);
      expect(request.replacementLength, 3);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('int');
      // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
      // the user may be either (1) entering a type for the assignment
      // or (2) starting a new statement.
      // Consider suggesting only types
      // if only spaces separates the 1st and 2nd identifiers.
      //assertNotSuggested('a');
      //assertNotSuggested('main');
      //assertNotSuggested('identical');
    });
  }

  test_AssignmentExpression_type_partial_newline() {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      class A {} main() {
        int a;
        i^
        b = 1;}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('int');
      // Allow non-types preceding an identifier on LHS of assignment
      // if newline follows first identifier
      // because user is probably starting a new statement
      assertSuggestLocalVariable('a', 'int');
      assertSuggestLocalFunction('main', null);
      assertSuggestImportedFunction('identical', 'bool');
    });
  }

  test_AwaitExpression() {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('''
      class A {int x; int y() => 0;}
      main() async {A a; await ^}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
      String get T7 => 'hello';
      set T8(int value) { }
      Z D2() {int x;}
      class X {
        int get clog => 8;
        set blog(value) { }
        a() {
          var f;
          localF(int arg1) { }
          {var x;}
          ^ var r;
        }
        void b() { }}
      class Z { }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);

      assertSuggestLocalClass('X');
      assertSuggestLocalClass('Z');
      assertSuggestLocalMethod('a', 'X', null);
      assertSuggestLocalMethod('b', 'X', 'void');
      assertSuggestLocalFunction('localF', null);
      assertSuggestLocalVariable('f', null);
      // Don't suggest locals out of scope
      assertNotSuggested('r');
      assertNotSuggested('x');

      assertSuggestImportedClass('A');
      assertNotSuggested('_B');
      assertSuggestImportedClass('C');
      // hidden element suggested as low relevance
      // but imported results are partially filtered
      //assertSuggestImportedClass('D', COMPLETION_RELEVANCE_LOW);
      //assertSuggestImportedFunction(
      //    'D1', null, true, COMPLETION_RELEVANCE_LOW);
      assertSuggestLocalFunction('D2', 'Z');
      assertSuggestImportedClass('EE');
      // hidden element suggested as low relevance
      //assertSuggestImportedClass('F', COMPLETION_RELEVANCE_LOW);
      assertSuggestLibraryPrefix('g');
      assertNotSuggested('G');
      //assertSuggestImportedClass('H', COMPLETION_RELEVANCE_LOW);
      assertSuggestImportedClass('Object');
      assertSuggestImportedFunction('min', 'num');
      //assertSuggestImportedFunction(
      //    'max',
      //    'num',
      //    false,
      //    COMPLETION_RELEVANCE_LOW);
      if (computer is ImportedComputer) {
        // TODO(danrubel) should be top level var suggestion
        assertSuggestGetter('T1', 'String');
      }
      assertNotSuggested('_T2');
      //assertSuggestImportedTopLevelVar('T3', 'int', COMPLETION_RELEVANCE_LOW);
      assertNotSuggested('_T4');
      assertSuggestLocalTopLevelVar('T5', 'int');
      assertSuggestLocalTopLevelVar('_T6', null);
      assertNotSuggested('==');
      assertSuggestLocalGetter('T7', 'String');
      assertSuggestLocalSetter('T8');
      assertSuggestLocalGetter('clog', 'int');
      assertSuggestLocalSetter('blog');
      // TODO (danrubel) suggest HtmlElement as low relevance
      assertNotSuggested('HtmlElement');
    });
  }

  test_Block_identifier_partial() {
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
      class D3 { }
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
      class X {a() {var f; {var x;} D^ var r;} void b() { }}
      class Z { }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);

      assertSuggestLocalClass('X');
      assertSuggestLocalClass('Z');
      assertSuggestLocalMethod('a', 'X', null);
      assertSuggestLocalMethod('b', 'X', 'void');
      assertSuggestLocalVariable('f', null);
      // Don't suggest locals out of scope
      assertNotSuggested('r');
      assertNotSuggested('x');

      // imported elements are portially filtered
      //assertSuggestImportedClass('A');
      assertNotSuggested('_B');
      //assertSuggestImportedClass('C');
      // hidden element suggested as low relevance
      assertSuggestImportedClass('D', relevance: DART_RELEVANCE_LOW);
      assertSuggestImportedFunction('D1', null,
          deprecated: true, relevance: DART_RELEVANCE_LOW);
      assertSuggestLocalFunction('D2', 'Z');
      // unimported elements suggested with low relevance
      assertSuggestImportedClass('D3', relevance: DART_RELEVANCE_LOW);
      //assertSuggestImportedClass('EE');
      // hidden element suggested as low relevance
      //assertSuggestImportedClass('F', COMPLETION_RELEVANCE_LOW);
      //assertSuggestLibraryPrefix('g');
      assertNotSuggested('G');
      //assertSuggestImportedClass('H', COMPLETION_RELEVANCE_LOW);
      //assertSuggestImportedClass('Object');
      //assertSuggestImportedFunction('min', 'num', false);
      //assertSuggestImportedFunction(
      //    'max',
      //    'num',
      //    false,
      //    COMPLETION_RELEVANCE_LOW);
      //assertSuggestTopLevelVarGetterSetter('T1', 'String');
      assertNotSuggested('_T2');
      //assertSuggestImportedTopLevelVar('T3', 'int', COMPLETION_RELEVANCE_LOW);
      assertNotSuggested('_T4');
      //assertSuggestLocalTopLevelVar('T5', 'int');
      //assertSuggestLocalTopLevelVar('_T6', null);
      assertNotSuggested('==');
      // TODO (danrubel) suggest HtmlElement as low relevance
      assertNotSuggested('HtmlElement');
    });
  }

  test_Block_inherited_imported() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addSource('/testB.dart', '''
      lib B;
      class F { var f1; f2() { } get f3 => 0; set f4(fx) { } var _pf; }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }''');
    addTestSource('''
      import "/testB.dart";
      class A extends E implements I with M {a() {^}}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      // TODO (danrubel) prefer fields over getters
      // If add `get e1;` to interface I
      // then suggestions include getter e1 rather than field e1
      assertSuggestImportedField('e1', null);
      assertSuggestImportedField('f1', null);
      assertSuggestImportedField('i1', 'int');
      assertSuggestImportedField('m1', null);
      assertSuggestImportedGetter('f3', null);
      assertSuggestImportedSetter('f4');
      assertSuggestImportedMethod('e2', 'E', null);
      assertSuggestImportedMethod('f2', 'F', null);
      assertSuggestImportedMethod('i2', 'I', null);
      //assertSuggestImportedMethod('m2', null, null);
      assertNotSuggested('==');
    });
  }

  test_Block_inherited_local() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
      class F { var f1; f2() { } get f3 => 0; set f4(fx) { } }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }
      class A extends E implements I with M {a() {^}}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalField('e1', null);
      assertSuggestLocalField('f1', null);
      assertSuggestLocalField('i1', 'int');
      assertSuggestLocalField('m1', null);
      assertSuggestLocalGetter('f3', null);
      assertSuggestLocalSetter('f4');
      assertSuggestLocalMethod('e2', 'E', null);
      assertSuggestLocalMethod('f2', 'F', null);
      assertSuggestLocalMethod('i2', 'I', null);
      assertSuggestLocalMethod('m2', 'M', 'int');
    });
  }

  test_Block_unimported() {
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('class C {foo(){F^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestImportedClass('Foo', relevance: DART_RELEVANCE_LOW);
      assertSuggestImportedClass('Future', relevance: DART_RELEVANCE_LOW);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationField('b', null);
      assertSuggestInvocationField('_c', 'X');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 1);
      assertSuggestInvocationField('b', null);
      assertSuggestInvocationField('_c', 'X');
      assertNotSuggested('Object');
      assertNotSuggested('A');
      assertNotSuggested('B');
      assertNotSuggested('X');
      assertNotSuggested('z');
      assertNotSuggested('==');
    });
  }

  test_CascadeExpression_selector2_withTrailingReturn() {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addSource('/testB.dart', '''
      class B { }''');
    addTestSource('''
      import "/testB.dart";
      class A {var b; X _c;}
      class X{}
      main() {A a; a..^ return}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationField('b', null);
      assertSuggestInvocationField('_c', 'X');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertNotSuggested('b');
      assertNotSuggested('_c');
      assertSuggestLocalVariable('a', 'A');
      assertSuggestLocalClass('A');
      assertSuggestLocalClass('X');
      // top level results are partially filtered
      //assertSuggestImportedClass('Object');
      assertNotSuggested('==');
    });
  }

  test_CatchClause_onType() {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^ {}}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
      assertNotSuggested('a');
      assertNotSuggested('x');
    });
  }

  test_CatchClause_onType_noBrackets() {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
      assertNotSuggested('x');
    });
  }

  test_CatchClause_typed() {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on E catch (e) {^}}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      CompletionSuggestion suggestionA = assertSuggestLocalClass('A',
          relevance: DART_RELEVANCE_LOW, isDeprecated: true);
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
      assertNotSuggested('T');
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
    return computeFull((bool result) {
      assertNoSuggestions();
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
      typedef PB2 F2(int blat);
      class Clz = Object with Object;
      class PB { }''');
    addSource('/testCD.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" show ^;
      import "/testCD.dart";
      class X {}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ConditionalExpression_elseExpression() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} return a ? T1 : T^}}''');
    computeFast();
    return computeFull((bool result) {
      // top level results are partially filtered based on first char
      assertSuggestLocalTopLevelVar('T2', 'int');
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
    });
  }

  test_ConditionalExpression_elseExpression_empty() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} return a ? T1 : ^}}''');
    computeFast();
    return computeFull((bool result) {
      assertNotSuggested('x');
      assertSuggestLocalVariable('f', null);
      assertSuggestLocalMethod('foo', 'C', null);
      assertSuggestLocalClass('C');
      assertSuggestLocalFunction('F2', null);
      assertSuggestLocalTopLevelVar('T2', 'int');
      assertSuggestImportedClass('A');
      assertSuggestImportedFunction('F1', null);
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
    });
  }

  test_ConditionalExpression_partial_thenExpression() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} return a ? T^}}''');
    computeFast();
    return computeFull((bool result) {
      // top level results are partially filtered based on first char
      assertSuggestLocalTopLevelVar('T2', 'int');
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
    });
  }

  test_ConditionalExpression_partial_thenExpression_empty() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} return a ? ^}}''');
    computeFast();
    return computeFull((bool result) {
      assertNotSuggested('x');
      assertSuggestLocalVariable('f', null);
      assertSuggestLocalMethod('foo', 'C', null);
      assertSuggestLocalClass('C');
      assertSuggestLocalFunction('F2', null);
      assertSuggestLocalTopLevelVar('T2', 'int');
      assertSuggestImportedClass('A');
      assertSuggestImportedFunction('F1', null);
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
    });
  }

  test_ConditionalExpression_thenExpression() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} return a ? T^ : c}}''');
    computeFast();
    return computeFull((bool result) {
      // top level results are partially filtered based on first char
      assertSuggestLocalTopLevelVar('T2', 'int');
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestNamedConstructor('c', 'X');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('_d');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_ConstructorName_importedFactory() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/testB.dart', '''
      lib B;
      int T1;
      F1() { }
      class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      var m;
      main() {new X.^}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestNamedConstructor('c', 'X');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('_d');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_ConstructorName_importedFactory2() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
      main() {new String.fr^omCharCodes([]);}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 2);
      expect(request.replacementLength, 13);
      assertSuggestNamedConstructor('fromCharCodes', 'String');
      assertNotSuggested('isEmpty');
      assertNotSuggested('isNotEmpty');
      assertNotSuggested('length');
      assertNotSuggested('Object');
      assertNotSuggested('String');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestNamedConstructor('c', 'X');
      assertSuggestNamedConstructor('_d', 'X');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_ConstructorName_localFactory() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
      int T1;
      F1() { }
      class X {factory X.c(); factory X._d(); z() {}}
      main() {new X.^}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestNamedConstructor('c', 'X');
      assertSuggestNamedConstructor('_d', 'X');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_DefaultFormalParameter_named_expression() {
    // DefaultFormalParameter FormalParameterList MethodDeclaration
    addTestSource('''
      foo() { }
      void bar() { }
      class A {a(blat: ^) { }}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalFunction('foo', null);
      assertSuggestLocalMethod('a', 'A', null);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('String');
      assertSuggestImportedFunction('identical', 'bool');
      assertNotSuggested('bar');
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
      typedef int F2(int blat);
      class Clz = Object with Object;
      class C {foo(){^} void bar() {}}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('A');
      assertSuggestImportedFunction('F1', '_B');
      assertSuggestLocalClass('C');
      assertSuggestLocalMethod('foo', 'C', null);
      assertSuggestLocalMethod('bar', 'C', 'void');
      assertSuggestLocalFunctionTypeAlias('F2', 'int');
      assertSuggestLocalClassTypeAlias('Clz');
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
    return computeFull((bool result) {
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
    return computeFull((bool result) {
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
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_ForEachStatement_body_typed() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestParameter('args', null);
      assertSuggestLocalVariable('foo', 'int');
      assertSuggestImportedClass('Object');
    });
  }

  test_ForEachStatement_body_untyped() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (foo in bar) {^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestParameter('args', null);
      assertSuggestLocalVariable('foo', null);
      assertSuggestImportedClass('Object');
    });
  }

  test_ForEachStatement_iterable() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (int foo in ^) {}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestParameter('args', null);
      assertSuggestImportedClass('Object');
    });
  }

  test_ForEachStatement_loopVariable() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ in args) {}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('args');
      assertSuggestImportedClass('String');
    });
  }

  test_ForEachStatement_loopVariable_type() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ foo in args) {}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('args');
      assertNotSuggested('foo');
      assertSuggestImportedClass('String');
    });
  }

  test_ForEachStatement_loopVariable_type2() {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (S^ foo in args) {}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertNotSuggested('args');
      assertNotSuggested('foo');
      assertSuggestImportedClass('String');
    });
  }

  test_FormalParameterList() {
    // FormalParameterList MethodDeclaration
    addTestSource('''
      foo() { }
      void bar() { }
      class A {a(^) { }}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('foo');
      assertNotSuggested('a');
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('String');
      assertNotSuggested('identical');
      assertNotSuggested('bar');
    });
  }

  test_ForStatement_body() {
    // Block  ForStatement
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalVariable('i', 'int');
      assertSuggestImportedClass('Object');
    });
  }

  test_ForStatement_condition() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestLocalVariable('index', 'int');
    });
  }

  test_ForStatement_initializer() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (^)}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalVariable('a', 'List');
      assertSuggestImportedClass('Object');
      assertSuggestImportedClass('int');
    });
  }

  test_ForStatement_updaters() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestLocalVariable('index', 'int');
    });
  }

  test_ForStatement_updaters_prefix_expression() {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('''
      void bar() { }
      main() {for (int index = 0; index < 10; ++i^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestLocalVariable('index', 'int');
      assertSuggestLocalFunction('main', null);
      assertNotSuggested('bar');
    });
  }

  test_FunctionDeclaration_returnType_afterComment() {
    // ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      /* */ ^ zoo(z) { } String name;''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
    });
  }

  test_FunctionDeclaration_returnType_afterComment2() {
    // FunctionDeclaration  ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      /** */ ^ zoo(z) { } String name;''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
    });
  }

  test_FunctionDeclaration_returnType_afterComment3() {
    // FunctionDeclaration  ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      /// some dartdoc
      class C2 { }
      ^ zoo(z) { } String name;''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
    });
  }

  test_FunctionExpression_body_function() {
    // Block  BlockFunctionBody  FunctionExpression
    addTestSource('''
      void bar() { }
      String foo(List args) {x.then((R b) {^});}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      var f = assertSuggestLocalFunction('foo', 'String', deprecated: false);
      if (f != null) {
        expect(f.element.isPrivate, isFalse);
      }
      assertSuggestLocalFunction('bar', 'void');
      assertSuggestParameter('args', 'List');
      assertSuggestParameter('b', 'R');
      assertSuggestImportedClass('Object');
    });
  }

  test_IfStatement() {
    // SimpleIdentifier  IfStatement
    addTestSource('''
      class A {var b; X _c; foo() {A a; if (true) ^}}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalField('b', null);
      assertSuggestLocalField('_c', 'X');
      assertSuggestImportedClass('Object');
      assertSuggestLocalClass('A');
      assertNotSuggested('==');
    });
  }

  test_IfStatement_condition() {
    // SimpleIdentifier  IfStatement  Block  BlockFunctionBody
    addTestSource('''
      class A {int x; int y() => 0;}
      main(){var a; if (^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalVariable('a', null);
      assertSuggestLocalFunction('main', null);
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_IfStatement_empty() {
    // SimpleIdentifier  IfStatement
    addTestSource('''
      class A {var b; X _c; foo() {A a; if (^) something}}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalField('b', null);
      assertSuggestLocalField('_c', 'X');
      assertSuggestImportedClass('Object');
      assertSuggestLocalClass('A');
      assertNotSuggested('==');
    });
  }

  test_IfStatement_invocation() {
    // SimpleIdentifier  PrefixIdentifier  IfStatement
    addTestSource('''
      main() {var a; if (a.^) something}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationMethod('toString', 'Object', 'String');
      assertNotSuggested('Object');
      assertNotSuggested('A');
      assertNotSuggested('==');
    });
  }

  test_ImportDirective_dart() {
    // SimpleStringLiteral  ImportDirective
    addTestSource('''
      import "dart^";
      main() {}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_IndexExpression() {
    // ExpressionStatement  Block
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} f[^]}}''');
    computeFast();
    return computeFull((bool result) {
      assertNotSuggested('x');
      assertSuggestLocalVariable('f', null);
      assertSuggestLocalMethod('foo', 'C', null);
      assertSuggestLocalClass('C');
      assertSuggestLocalFunction('F2', null);
      assertSuggestLocalTopLevelVar('T2', 'int');
      assertSuggestImportedClass('A');
      assertSuggestImportedFunction('F1', null);
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
    });
  }

  test_IndexExpression2() {
    // SimpleIdentifier IndexExpression ExpressionStatement  Block
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      class B {int x;}
      class C {foo(){var f; {var x;} f[T^]}}''');
    computeFast();
    return computeFull((bool result) {
      // top level results are partially filtered based on first char
      assertSuggestLocalTopLevelVar('T2', 'int');
      // TODO (danrubel) getter is being suggested instead of top level var
      //assertSuggestImportedTopLevelVar('T1', 'int');
    });
  }

  test_InstanceCreationExpression_imported() {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      class A {A(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      import "dart:async";
      int T2;
      F2() { }
      class B {B(this.x, [String boo]) { } int x;}
      class C {foo(){var f; {var x;} new ^}}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedConstructor('Object');
      assertSuggestImportedConstructor('Future');
      assertSuggestImportedConstructor('A');
      assertSuggestLocalConstructor('B');
      assertSuggestLocalConstructor('C');
      assertNotSuggested('f');
      assertNotSuggested('x');
      assertNotSuggested('foo');
      assertNotSuggested('F1');
      assertNotSuggested('F2');
      assertNotSuggested('T1');
      assertNotSuggested('T2');
    });
  }

  test_InstanceCreationExpression_unimported() {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('class C {foo(){new F^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestImportedConstructor('Foo', relevance: DART_RELEVANCE_LOW);
      assertSuggestImportedConstructor('Future', relevance: DART_RELEVANCE_LOW);
    });
  }

  test_InterpolationExpression() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      main() {String name; print("hello \$^");}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('Object');
      // TODO(danrubel) should return top level var rather than getter
      if (computer is ImportedComputer) {
        //assertSuggestImportedTopLevelVar('T1', 'int');
        assertSuggestGetter('T1', 'int');
      }
      assertSuggestImportedFunction('F1', null);
      assertNotSuggested('D1');
      assertNotSuggested('C1');
      assertSuggestLocalTopLevelVar('T2', 'int');
      assertSuggestLocalFunction('F2', null);
      assertNotSuggested('D2');
      assertNotSuggested('C2');
      assertSuggestLocalVariable('name', 'String');
    });
  }

  test_InterpolationExpression_block() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      main() {String name; print("hello \${^}");}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      // TODO(danrubel) should return top level var rather than getter
      if (computer is ImportedComputer) {
        //assertSuggestImportedTopLevelVar('T1', 'int');
        assertSuggestGetter('T1', 'int');
      }
      assertSuggestImportedFunction('F1', null);
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertSuggestLocalTopLevelVar('T2', 'int');
      assertSuggestLocalFunction('F2', null);
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertSuggestLocalVariable('name', 'String');
    });
  }

  test_InterpolationExpression_block2() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestLocalVariable('name', 'String');
      // top level results are partially filtered
      //assertSuggestImportedClass('Object');
    });
  }

  test_InterpolationExpression_prefix_selector() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${name.^}");}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationGetter('length', 'int');
      assertNotSuggested('name');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_InterpolationExpression_prefix_selector2() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \$name.^");}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_InterpolationExpression_prefix_target() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${nam^e.length}");}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestLocalVariable('name', 'String');
      // top level results are partially filtered
      //assertSuggestImportedClass('Object');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('a');
      assertNotSuggested('main');
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_IsExpression_type_partial() {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
      class A {int x; int y() => 0;}
      main(){var a; if (a is Obj^)}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 3);
      expect(request.replacementLength, 3);
      assertNotSuggested('a');
      assertNotSuggested('main');
      assertSuggestLocalClass('A');
      assertSuggestImportedClass('Object');
    });
  }

  test_keyword() {
    addSource('/testB.dart', '''
      lib B;
      int newT1;
      int T1;
      nowIsIt() { }
      class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      String newer() {}
      var m;
      main() {new^ X.c();}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 3);
      expect(request.replacementLength, 3);
      assertNotSuggested('c');
      assertNotSuggested('_d');
      // Imported suggestion are filtered by 1st character
      assertSuggestImportedFunction('nowIsIt', null);
      assertNotSuggested('T1');
      // TODO (danrubel) this really should be TopLevelVar not getter/setter
      if (computer is ImportedComputer) {
        assertSuggestGetter('newT1', 'int');
      }
      assertNotSuggested('z');
      assertSuggestLocalTopLevelVar('m', 'dynamic');
      assertSuggestLocalFunction('newer', 'String');
    });
  }

  test_Literal_list() {
    // ']'  ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([^]);}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestLocalVariable('Some', null);
      assertSuggestImportedClass('String');
    });
  }

  test_Literal_list2() {
    // SimpleIdentifier ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([S^]);}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestLocalVariable('Some', null);
      assertSuggestImportedClass('String');
    });
  }

  test_Literal_string() {
    // SimpleStringLiteral  ExpressionStatement  Block
    addTestSource('class A {a() {"hel^lo"}}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_MapLiteralEntry() {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      foo = {^''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      // TODO(danrubel) Should be top level variable
      if (computer is ImportedComputer) {
        assertSuggestGetter('T1', 'int');
        // assertSuggestImportedTopLevelVar('T1', 'int');
      }
      assertSuggestImportedFunction('F1', null);
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertSuggestLocalTopLevelVar('T2', 'int');
      assertSuggestLocalFunction('F2', null);
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
    });
  }

  test_MapLiteralEntry1() {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      foo = {T^''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      // TODO(danrubel) Should be top level variable
      if (computer is ImportedComputer) {
        assertSuggestGetter('T1', 'int');
        // assertSuggestImportedTopLevelVar('T1', 'int');
      }
      assertSuggestLocalTopLevelVar('T2', 'int');
    });
  }

  test_MapLiteralEntry2() {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 { }
      foo = {7:T^};''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      // TODO(danrubel) Should be top level variable
      if (computer is ImportedComputer) {
        assertSuggestGetter('T1', 'int');
        // assertSuggestImportedTopLevelVar('T1', 'int');
      }
      assertSuggestLocalTopLevelVar('T2', 'int');
    });
  }

  test_MethodDeclaration_body_getters() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X get f => 0; Z a() {^} get _g => 1;}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      CompletionSuggestion methodA = assertSuggestLocalMethod('a', 'A', 'Z');
      if (methodA != null) {
        expect(methodA.element.isDeprecated, isFalse);
        expect(methodA.element.isPrivate, isFalse);
      }
      CompletionSuggestion getterF = assertSuggestLocalGetter('f', 'X',
          relevance: DART_RELEVANCE_LOW, deprecated: true);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      CompletionSuggestion methodA = assertSuggestLocalMethod('_a', 'A', 'Z');
      if (methodA != null) {
        expect(methodA.element.isDeprecated, isFalse);
        expect(methodA.element.isPrivate, isTrue);
      }
      CompletionSuggestion getterF = assertSuggestLocalField('f', 'X',
          relevance: DART_RELEVANCE_LOW, deprecated: true);
      if (getterF != null) {
        expect(getterF.element.isDeprecated, isTrue);
        expect(getterF.element.isPrivate, isFalse);
        expect(getterF.element.parameters, isNull);
      }
      CompletionSuggestion getterG = assertSuggestLocalField('_g', null);
      if (getterG != null) {
        expect(getterG.element.isDeprecated, isFalse);
        expect(getterG.element.isPrivate, isTrue);
        expect(getterF.element.parameters, isNull);
      }
      assertSuggestImportedClass('bool');
    });
  }

  test_MethodDeclaration_parameters_named() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated Z a(X x, _, b, {y: boo}) {^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      CompletionSuggestion methodA = assertSuggestLocalMethod('a', 'A', 'Z',
          relevance: DART_RELEVANCE_LOW, deprecated: true);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalFunction('foo', null);
      assertSuggestLocalFunction('bar', 'void');
      assertSuggestLocalMethod('a', 'A', 'Z');
      assertSuggestParameter('x', 'X');
      assertSuggestParameter('y', 'int');
      assertSuggestImportedClass('String');
    });
  }

  test_MethodDeclaration_returnType() {
    // ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 {^ zoo(z) { } String name; }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
    });
  }

  test_MethodDeclaration_returnType_afterComment() {
    // ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 {/* */ ^ zoo(z) { } String name; }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
    });
  }

  test_MethodDeclaration_returnType_afterComment2() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 {/** */ ^ zoo(z) { } String name; }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
    });
  }

  test_MethodDeclaration_returnType_afterComment3() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addSource('/testA.dart', '''
      int T1;
      F1() { }
      typedef D1();
      class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
      import "/testA.dart";
      int T2;
      F2() { }
      typedef D2();
      class C2 {
        /// some dartdoc
        ^ zoo(z) { } String name; }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertNotSuggested('T1');
      assertNotSuggested('F1');
      assertSuggestImportedFunctionTypeAlias('D1', null);
      assertSuggestImportedClass('C1');
      assertNotSuggested('T2');
      assertNotSuggested('F2');
      assertSuggestLocalFunctionTypeAlias('D2', null);
      assertSuggestLocalClass('C2');
      assertNotSuggested('name');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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

  test_new_instance() {
    addTestSource('import "dart:math"; class A {x() {new Random().^}}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationMethod('nextBool', 'Random', 'bool');
      assertSuggestInvocationMethod('nextDouble', 'Random', 'double');
      assertSuggestInvocationMethod('nextInt', 'Random', 'int');
      assertNotSuggested('Random');
      assertNotSuggested('Object');
      assertNotSuggested('A');
    });
  }

  test_partFile_TypeName() {
    // SimpleIdentifier  TypeName  ConstructorName
    addSource('/testB.dart', '''
      lib B;
      int T1;
      F1() { }
      class X {X.c(); X._d(); z() {}}''');
    addSource('/testA.dart', '''
      library libA;
      import "/testB.dart";
      part "$testFile";
      class A { }
      var m;''');
    addTestSource('''
      part of libA;
      class B { factory B.bar(int x) => null; }
      main() {new ^}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalConstructor('B.bar');
      assertSuggestImportedConstructor('Object');
      assertSuggestImportedConstructor('X.c');
      assertNotSuggested('X._d');
      assertSuggestImportedConstructor('A');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('_d');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_partFile_TypeName2() {
    // SimpleIdentifier  TypeName  ConstructorName
    addSource('/testB.dart', '''
      lib B;
      int T1;
      F1() { }
      class X {X.c(); X._d(); z() {}}''');
    addSource('/testA.dart', '''
      part of libA;
      class B { }''');
    addTestSource('''
      library libA;
      import "/testB.dart";
      part "/testA.dart";
      class A { A({String boo: 'hoo'}) { } }
      main() {new ^}
      var m;''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestLocalConstructor('A');
      assertSuggestImportedConstructor('Object');
      assertSuggestImportedConstructor('X.c');
      assertNotSuggested('X._d');
      assertSuggestImportedConstructor('B');
      assertNotSuggested('F1');
      assertNotSuggested('T1');
      assertNotSuggested('_d');
      assertNotSuggested('z');
      assertNotSuggested('m');
    });
  }

  test_PrefixedIdentifier_class_const() {
    // SimpleIdentifier PrefixedIdentifier ExpressionStatement Block
    addSource('/testB.dart', '''
      lib B;
      class I {
        static const scI = 'boo';
        X get f => new A();
        get _g => new A();}
      class B implements I {
        static const int scB = 12;
        var b; X _c;
        X get d => new A();get _e => new A();
        set s1(I x) {} set _s2(I x) {}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    addTestSource('''
      import "/testB.dart";
      class A extends B {
        static const String scA = 'foo';
        w() { }}
      main() {A.^}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationField('scA', 'String');
      assertSuggestInvocationField('scB', 'int');
      assertSuggestInvocationField('scI', null);
      assertNotSuggested('b');
      assertNotSuggested('_c');
      assertNotSuggested('d');
      assertNotSuggested('_e');
      assertNotSuggested('f');
      assertNotSuggested('_g');
      assertNotSuggested('s1');
      assertNotSuggested('_s2');
      assertNotSuggested('m');
      assertNotSuggested('_n');
      assertNotSuggested('a');
      assertNotSuggested('A');
      assertNotSuggested('X');
      assertNotSuggested('w');
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
        static const int sc = 12;
        @deprecated var b; X _c;
        X get d => new A();get _e => new A();
        set s1(I x) {} set _s2(I x) {}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    addTestSource('''
      import "/testB.dart";
      main() {A a; a.^}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('sc');
      assertSuggestInvocationField('b', null, isDeprecated: true);
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
        static const int sc = 12;
        var b; X _c;
        X get d => new A();get _e => new A();
        set s1(I x) {} set _s2(I x) {}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertNotSuggested('sc');
      assertSuggestInvocationField('b', null);
      assertSuggestInvocationField('_c', 'X');
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

  test_PrefixedIdentifier_getter() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String get g => "one"; f() {g.^}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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

  test_PrefixedIdentifier_library_typesOnly() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addSource('/testB.dart', '''
      lib B;
      var T1;
      class X { }
      class Y { }''');
    addTestSource('''
      import "/testB.dart" as b;
      var T2;
      class A { }
      foo(b.^ f) {}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationClass('X');
      assertSuggestInvocationClass('Y');
      assertNotSuggested('T1');
      assertNotSuggested('T2');
      assertNotSuggested('Object');
      assertNotSuggested('b');
      assertNotSuggested('A');
      assertNotSuggested('==');
    });
  }

  test_PrefixedIdentifier_library_typesOnly2() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addSource('/testB.dart', '''
      lib B;
      var T1;
      class X { }
      class Y { }''');
    addTestSource('''
      import "/testB.dart" as b;
      var T2;
      class A { }
      foo(b.^) {}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationClass('X');
      assertSuggestInvocationClass('Y');
      assertNotSuggested('T1');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationField('y', 'M');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestImportedClass('A');
      assertSuggestLocalClass('X');
      assertSuggestLocalMethod('foo', 'X', null);
      assertNotSuggested('bar');
      assertNotSuggested('_B');
    });
  }

  test_PrefixedIdentifier_propertyAccess() {
    // PrefixedIdentifier  ExpressionStatement  Block  BlockFunctionBody
    addTestSource('class A {String x; int get foo {x.^}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationGetter('isEmpty', 'bool');
      assertSuggestInvocationMethod('compareTo', 'Comparable', 'int');
    });
  }

  test_PrefixedIdentifier_propertyAccess_newStmt() {
    // PrefixedIdentifier  ExpressionStatement  Block  BlockFunctionBody
    addTestSource('class A {String x; int get foo {x.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationGetter('isEmpty', 'bool');
      assertSuggestInvocationMethod('compareTo', 'Comparable', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_const() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('const String g = "hello"; f() {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_field() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {String g; f() {g.^ int y = 0;}}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_function() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String g() => "one"; f() {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_functionTypeAlias() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('typedef String g(); f() {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_getter() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String get g => "one"; f() {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_local_typed() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f() {String g; g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_local_untyped() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f() {var g = "hello"; g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_method() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {String g() {}; f() {g.^ int y = 0;}}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_param() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {f(String g) {g.^ int y = 0;}}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_param2() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f(String g) {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PrefixedIdentifier_trailingStmt_topLevelVar() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String g; f() {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  test_PropertyAccess_expression() {
    // SimpleIdentifier  MethodInvocation  PropertyAccess  ExpressionStatement
    addTestSource('class A {a() {"hello".to^String().length}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 2);
      expect(request.replacementLength, 8);
      assertSuggestInvocationGetter('length', 'int');
      assertNotSuggested('A');
      assertNotSuggested('a');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_PropertyAccess_noTarget() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('class C {foo(){.^}}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_PropertyAccess_noTarget2() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('main() {.^}');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_PropertyAccess_selector() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement  Block
    addTestSource('class A {a() {"hello".length.^}}');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationGetter('isEven', 'bool');
      assertNotSuggested('A');
      assertNotSuggested('a');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_ThisExpression_block() {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      main() { }
      class I {X get f => new A();get _g => new A();}
      class A implements I {
        A() {}
        A.z() {}
        var b; X _c;
        X get d => new A();get _e => new A();
        // no semicolon between completion point and next statement
        set s1(I x) {} set _s2(I x) {this.^ m(null);}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationField('b', null);
      assertSuggestInvocationField('_c', 'X');
      assertSuggestInvocationGetter('d', 'X');
      assertSuggestInvocationGetter('_e', null);
      assertSuggestInvocationGetter('f', 'X');
      assertSuggestInvocationGetter('_g', null);
      assertSuggestInvocationMethod('m', 'A', null);
      assertSuggestInvocationMethod('_n', 'A', 'I');
      assertSuggestInvocationSetter('s1');
      assertSuggestInvocationSetter('_s2');
      assertNotSuggested('z');
      assertNotSuggested('I');
      assertNotSuggested('A');
      assertNotSuggested('X');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_ThisExpression_constructor() {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      main() { }
      class I {X get f => new A();get _g => new A();}
      class A implements I {
        A() {this.^}
        A.z() {}
        var b; X _c;
        X get d => new A();get _e => new A();
        // no semicolon between completion point and next statement
        set s1(I x) {} set _s2(I x) {m(null);}
        m(X x) {} I _n(X x) {}}
      class X{}''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestInvocationField('b', null);
      assertSuggestInvocationField('_c', 'X');
      assertSuggestInvocationGetter('d', 'X');
      assertSuggestInvocationGetter('_e', null);
      assertSuggestInvocationGetter('f', 'X');
      assertSuggestInvocationGetter('_g', null);
      assertSuggestInvocationMethod('m', 'A', null);
      assertSuggestInvocationMethod('_n', 'A', 'I');
      assertSuggestInvocationSetter('s1');
      assertSuggestInvocationSetter('_s2');
      assertNotSuggested('z');
      assertNotSuggested('I');
      assertNotSuggested('A');
      assertNotSuggested('X');
      assertNotSuggested('Object');
      assertNotSuggested('==');
    });
  }

  test_TopLevelVariableDeclaration_typed_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} B ^');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_TopLevelVariableDeclaration_untyped_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} var ^');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_TypeArgumentList() {
    // SimpleIdentifier  BinaryExpression  ExpressionStatement
    addSource('/testA.dart', '''
      class C1 {int x;}
      F1() => 0;
      typedef String T1(int blat);''');
    addTestSource('''
      import "/testA.dart";'
      class C2 {int x;}
      F2() => 0;
      typedef int T2(int blat);
      class C<E> {}
      main() { C<^> c; }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
      assertSuggestImportedClass('Object');
      assertSuggestImportedClass('C1');
      assertSuggestImportedFunctionTypeAlias('T1', 'String');
      assertSuggestLocalClass('C2');
      assertSuggestLocalFunctionTypeAlias('T2', 'int');
      assertNotSuggested('F1');
      assertNotSuggested('F2');
    });
  }

  test_TypeArgumentList2() {
    // TypeName  TypeArgumentList  TypeName
    addSource('/testA.dart', '''
      class C1 {int x;}
      F1() => 0;
      typedef String T1(int blat);''');
    addTestSource('''
      import "/testA.dart";'
      class C2 {int x;}
      F2() => 0;
      typedef int T2(int blat);
      class C<E> {}
      main() { C<C^> c; }''');
    computeFast();
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset - 1);
      expect(request.replacementLength, 1);
      assertSuggestImportedClass('C1');
      assertSuggestLocalClass('C2');
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
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_VariableDeclarationList_final() {
    // VariableDeclarationList  VariableDeclarationStatement  Block
    addTestSource('main() {final ^} class C { }');
    computeFast();
    return computeFull((bool result) {
      assertSuggestImportedClass('Object');
      assertSuggestLocalClass('C');
      assertNotSuggested('==');
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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
    return computeFull((bool result) {
      expect(request.replacementOffset, completionOffset);
      expect(request.replacementLength, 0);
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

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.util;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide Element, ElementKind;
import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl, ReplacementRange;
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_context.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/dart.dart';
import 'package:test/test.dart';

import '../../../abstract_context.dart';
import '../../correction/flutter_util.dart';

int suggestionComparator(CompletionSuggestion s1, CompletionSuggestion s2) {
  String c1 = s1.completion.toLowerCase();
  String c2 = s2.completion.toLowerCase();
  return c1.compareTo(c2);
}

abstract class DartCompletionContributorTest extends AbstractContextTest {
  static const String _UNCHECKED = '__UNCHECKED__';
  Index index;
  SearchEngineImpl searchEngine;
  String testFile = '/completionTest.dart';
  Source testSource;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  DartCompletionContributor contributor;
  DartCompletionRequest request;
  List<CompletionSuggestion> suggestions;

  /**
   * If `true` and `null` is specified as the suggestion's expected returnType
   * then the actual suggestion is expected to have a `dynamic` returnType.
   * Newer tests return `false` so that they can distinguish between
   * `dynamic` and `null`.
   * Eventually all tests should be converted and this getter removed.
   */
  bool get isNullExpectedReturnTypeConsideredDynamic => true;

  void addTestSource(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    testSource = addSource(testFile, content);
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
      if (suggestions.length > 0) {
        failedCompletion('Expected no suggestions', suggestions);
      }
      return;
    }
    CompletionSuggestion suggestion = suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.kind == kind,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  void assertNotSuggested(String completion) {
    CompletionSuggestion suggestion = suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.completion == completion,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  CompletionSuggestion assertSuggest(String completion,
      {CompletionSuggestionKind csKind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      protocol.ElementKind elemKind: null,
      bool isDeprecated: false,
      bool isPotential: false,
      String elemFile,
      int elemOffset,
      String paramName,
      String paramType,
      String defaultArgListString: _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    CompletionSuggestion cs =
        getSuggest(completion: completion, csKind: csKind, elemKind: elemKind);
    if (cs == null) {
      failedCompletion('expected $completion $csKind $elemKind', suggestions);
    }
    expect(cs.kind, equals(csKind));
    if (isDeprecated) {
      expect(cs.relevance, equals(DART_RELEVANCE_LOW));
    } else {
      expect(cs.relevance, equals(relevance), reason: completion);
    }
    expect(cs.importUri, importUri);
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
    if (cs.element != null) {
      expect(cs.element.location, isNotNull);
      expect(cs.element.location.file, isNotNull);
      expect(cs.element.location.offset, isNotNull);
      expect(cs.element.location.length, isNotNull);
      expect(cs.element.location.startColumn, isNotNull);
      expect(cs.element.location.startLine, isNotNull);
    }
    if (elemFile != null) {
      expect(cs.element.location.file, elemFile);
    }
    if (elemOffset != null) {
      expect(cs.element.location.offset, elemOffset);
    }
    if (paramName != null) {
      expect(cs.parameterName, paramName);
    }
    if (paramType != null) {
      expect(cs.parameterType, paramType);
    }
    if (defaultArgListString != _UNCHECKED) {
      expect(cs.defaultArgumentListString, defaultArgListString);
    }
    if (defaultArgumentListTextRanges != null) {
      expect(cs.defaultArgumentListTextRanges, defaultArgumentListTextRanges);
    }
    return cs;
  }

  CompletionSuggestion assertSuggestClass(String name,
      {int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false,
      String elemFile,
      String elemName,
      int elemOffset}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated,
        elemFile: elemFile,
        elemOffset: elemOffset);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS));
    expect(element.name, equals(elemName ?? name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestClassTypeAlias(String name,
      {int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION}) {
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
      {int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      int elemOffset,
      String defaultArgListString: _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    CompletionSuggestion cs = assertSuggest(name,
        relevance: relevance,
        importUri: importUri,
        elemOffset: elemOffset,
        defaultArgListString: defaultArgListString,
        defaultArgumentListTextRanges: defaultArgumentListTextRanges);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CONSTRUCTOR));
    int index = name.indexOf('.');
    expect(element.name, index >= 0 ? name.substring(index + 1) : '');
    return cs;
  }

  CompletionSuggestion assertSuggestEnum(String completion,
      {bool isDeprecated: false}) {
    CompletionSuggestion suggestion =
        assertSuggest(completion, isDeprecated: isDeprecated);
    expect(suggestion.isDeprecated, isDeprecated);
    expect(suggestion.element.kind, protocol.ElementKind.ENUM);
    return suggestion;
  }

  CompletionSuggestion assertSuggestEnumConst(String completion,
      {int relevance: DART_RELEVANCE_DEFAULT, bool isDeprecated: false}) {
    CompletionSuggestion suggestion = assertSuggest(completion,
        relevance: relevance, isDeprecated: isDeprecated);
    expect(suggestion.completion, completion);
    expect(suggestion.isDeprecated, isDeprecated);
    expect(suggestion.element.kind, protocol.ElementKind.ENUM_CONSTANT);
    return suggestion;
  }

  CompletionSuggestion assertSuggestField(String name, String type,
      {int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
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
      bool isDeprecated: false,
      int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      String defaultArgListString: _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated,
        defaultArgListString: defaultArgListString,
        defaultArgumentListTextRanges: defaultArgumentListTextRanges);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(cs.returnType, 'dynamic');
    }
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    String param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    if (returnType != null) {
      expect(element.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(element.returnType, 'dynamic');
    }
    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestFunctionTypeAlias(
      String name, String returnType,
      {bool isDeprecated: false,
      int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      String importUri}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(cs.returnType, 'dynamic');
    } else {
      expect(cs.returnType, isNull);
    }
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
      String importUri,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
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

  CompletionSuggestion assertSuggestMethod(
      String name, String declaringType, String returnType,
      {int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      bool isDeprecated: false,
      String defaultArgListString: _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated,
        defaultArgListString: defaultArgListString,
        defaultArgumentListTextRanges: defaultArgumentListTextRanges);
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

  CompletionSuggestion assertSuggestName(String name,
      {int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind: CompletionSuggestionKind.IDENTIFIER,
      bool isDeprecated: false}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated);
    expect(cs.completion, equals(name));
    expect(cs.element, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestSetter(String name,
      {int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
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
      {int relevance: DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      String importUri}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: kind, relevance: relevance, importUri: importUri);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(cs.returnType, 'dynamic');
    }
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.TOP_LEVEL_VARIABLE));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    if (returnType != null) {
      expect(element.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(element.returnType, 'dynamic');
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  /**
   * Return a [Future] that completes with the containing library information
   * after it is accessible via [context.getLibrariesContaining].
   */
  Future<Null> computeLibrariesContaining([int times = 200]) {
    if (enableNewAnalysisDriver) {
      return driver.getResult(testFile).then((result) => null);
    }
    List<Source> libraries = context.getLibrariesContaining(testSource);
    if (libraries.isNotEmpty) {
      return new Future.value(null);
    }
    if (times == 0) {
      fail('failed to determine libraries containing $testSource');
    }
    context.performAnalysisTask();
    // We use a delayed future to allow microtask events to finish. The
    // Future.value or Future() constructors use scheduleMicrotask themselves and
    // would therefore not wait for microtask callbacks that are scheduled after
    // invoking this method.
    return new Future.delayed(
        Duration.ZERO, () => computeLibrariesContaining(times - 1));
  }

  Future computeSuggestions({int times = 200, IdeOptions options}) async {
    AnalysisResult analysisResult = null;
    if (enableNewAnalysisDriver) {
      analysisResult = await driver.getResult(testFile);
      testSource = analysisResult.unit.element.source;
    } else {
      context.analysisPriorityOrder = [testSource];
    }
    CompletionRequestImpl baseRequest = new CompletionRequestImpl(
        analysisResult,
        enableNewAnalysisDriver ? null : context,
        provider,
        searchEngine,
        testSource,
        completionOffset,
        new CompletionPerformance(),
        options);

    // Build the request
    Completer<DartCompletionRequest> requestCompleter =
        new Completer<DartCompletionRequest>();
    DartCompletionRequestImpl
        .from(baseRequest)
        .then((DartCompletionRequest request) {
      requestCompleter.complete(request);
    });
    request = await performAnalysis(times, requestCompleter);

    var range = new ReplacementRange.compute(request.offset, request.target);
    replacementOffset = range.offset;
    replacementLength = range.length;
    Completer<List<CompletionSuggestion>> suggestionCompleter =
        new Completer<List<CompletionSuggestion>>();

    // Request completions
    contributor
        .computeSuggestions(request)
        .then((List<CompletionSuggestion> computedSuggestions) {
      suggestionCompleter.complete(computedSuggestions);
    });

    // Perform analysis until the suggestions have been computed
    // or the max analysis cycles ([times]) has been reached
    suggestions = await performAnalysis(times, suggestionCompleter);
    expect(suggestions, isNotNull, reason: 'expected suggestions');
  }

  /**
   * Configures the [SourceFactory] to have the `flutter` package in
   * `/packages/flutter/lib` folder.
   */
  void configureFlutterPkg(Map<String, String> pathToCode) {
    pathToCode.forEach((path, code) {
      provider.newFile('$flutterPkgLibPath/$path', code);
    });
    // configure SourceFactory
    Folder myPkgFolder = provider.getResource(flutterPkgLibPath);
    UriResolver pkgResolver = new PackageMapUriResolver(provider, {
      'flutter': [myPkgFolder]
    });
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), pkgResolver, resourceResolver]);
    if (enableNewAnalysisDriver) {
      driver.configure(sourceFactory: sourceFactory);
    } else {
      context.sourceFactory = sourceFactory;
    }
    // force 'flutter' resolution
    addSource(
        '/tmp/other.dart',
        pathToCode.keys
            .map((path) => "import 'package:flutter/$path';")
            .join('\n'));
  }

  DartCompletionContributor createContributor();

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
    fail(sb.toString());
  }

  CompletionSuggestion getSuggest(
      {String completion: null,
      CompletionSuggestionKind csKind: null,
      protocol.ElementKind elemKind: null}) {
    CompletionSuggestion cs;
    if (suggestions != null) {
      suggestions.forEach((CompletionSuggestion s) {
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
              suggestions.where((s) => s.completion == completion));
        }
      });
    }
    return cs;
  }

  Future/*<E>*/ performAnalysis/*<E>*/(
      int times, Completer/*<E>*/ completer) async {
    if (completer.isCompleted) {
      return completer.future;
    }
    if (enableNewAnalysisDriver) {
      // Just wait.
    } else {
      if (times == 0 || context == null) {
        return new Future.value();
      }
      context.performAnalysisTask();
    }
    // We use a delayed future to allow microtask events to finish. The
    // Future.value or Future() constructors use scheduleMicrotask themselves and
    // would therefore not wait for microtask callbacks that are scheduled after
    // invoking this method.
    return new Future.delayed(
        Duration.ZERO, () => performAnalysis(times - 1, completer));
  }

  void resolveSource(String path, String content) {
    Source libSource = addSource(path, content);
    if (!enableNewAnalysisDriver) {
      var target = new LibrarySpecificUnit(libSource, libSource);
      context.computeResult(target, RESOLVED_UNIT);
    }
  }

  @override
  void setUp() {
    super.setUp();
    index = createMemoryIndex();
    searchEngine =
        new SearchEngineImpl(index, (_) => new AstProviderForContext(context));
    contributor = createContributor();
  }
}

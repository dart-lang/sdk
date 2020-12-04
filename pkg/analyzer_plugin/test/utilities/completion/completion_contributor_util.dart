// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:test/test.dart';

import '../../support/abstract_context.dart';

int suggestionComparator(CompletionSuggestion s1, CompletionSuggestion s2) {
  var c1 = s1.completion.toLowerCase();
  var c2 = s2.completion.toLowerCase();
  return c1.compareTo(c2);
}

abstract class DartCompletionContributorTest extends AbstractContextTest {
  static const String _UNCHECKED = '__UNCHECKED__';
  String testFile;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  CompletionContributor contributor;
  DartCompletionRequest request;
  List<CompletionSuggestion> suggestions;

  /// If `true` and `null` is specified as the suggestion's expected returnType
  /// then the actual suggestion is expected to have a `dynamic` returnType.
  /// Newer tests return `false` so that they can distinguish between
  /// `dynamic` and `null`.
  /// Eventually all tests should be converted and this getter removed.
  bool get isNullExpectedReturnTypeConsideredDynamic => true;

  void addTestSource(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    addSource(testFile, content);
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

  void assertNoSuggestions({CompletionSuggestionKind kind}) {
    if (kind == null) {
      if (suggestions.isNotEmpty) {
        failedCompletion('Expected no suggestions', suggestions);
      }
      return;
    }
    var suggestion = suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.kind == kind,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  void assertNotSuggested(String completion) {
    var suggestion = suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.completion == completion,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  CompletionSuggestion assertSuggest(String completion,
      {CompletionSuggestionKind csKind = CompletionSuggestionKind.INVOCATION,
      int relevance = DART_RELEVANCE_DEFAULT,
      ElementKind elemKind,
      bool isDeprecated = false,
      bool isPotential = false,
      String elemFile,
      int elemOffset,
      int selectionOffset,
      String paramName,
      String paramType,
      String defaultArgListString = _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    var cs =
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
    expect(cs.selectionOffset, equals(selectionOffset ?? completion.length));
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
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false,
      String elemFile,
      String elemName,
      int elemOffset}) {
    var cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        isDeprecated: isDeprecated,
        elemFile: elemFile,
        elemOffset: elemOffset);
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.CLASS));
    expect(element.name, equals(elemName ?? name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestClassTypeAlias(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    var cs = assertSuggest(name, csKind: kind, relevance: relevance);
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.CLASS_TYPE_ALIAS));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestConstructor(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      int elemOffset,
      String defaultArgListString = _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    var cs = assertSuggest(name,
        relevance: relevance,
        elemOffset: elemOffset,
        defaultArgListString: defaultArgListString,
        defaultArgumentListTextRanges: defaultArgumentListTextRanges);
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.CONSTRUCTOR));
    var index = name.indexOf('.');
    expect(element.name, index >= 0 ? name.substring(index + 1) : '');
    return cs;
  }

  CompletionSuggestion assertSuggestEnum(String completion,
      {bool isDeprecated = false}) {
    var suggestion = assertSuggest(completion, isDeprecated: isDeprecated);
    expect(suggestion.isDeprecated, isDeprecated);
    expect(suggestion.element.kind, ElementKind.ENUM);
    return suggestion;
  }

  CompletionSuggestion assertSuggestEnumConst(String completion,
      {int relevance = DART_RELEVANCE_DEFAULT, bool isDeprecated = false}) {
    var suggestion = assertSuggest(completion,
        relevance: relevance, isDeprecated: isDeprecated);
    expect(suggestion.completion, completion);
    expect(suggestion.isDeprecated, isDeprecated);
    expect(suggestion.element.kind, ElementKind.ENUM_CONSTANT);
    return suggestion;
  }

  CompletionSuggestion assertSuggestField(String name, String type,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false}) {
    var cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        elemKind: ElementKind.FIELD,
        isDeprecated: isDeprecated);
    // The returnType represents the type of a field
    expect(cs.returnType, type ?? 'dynamic');
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.FIELD));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    // The returnType represents the type of a field
    expect(element.returnType, type ?? 'dynamic');
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestFunction(String name, String returnType,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT,
      String defaultArgListString = _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    var cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        isDeprecated: isDeprecated,
        defaultArgListString: defaultArgListString,
        defaultArgumentListTextRanges: defaultArgumentListTextRanges);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(cs.returnType, 'dynamic');
    }
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.FUNCTION));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    var param = element.parameters;
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
      {bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    var cs = assertSuggest(name,
        csKind: kind, relevance: relevance, isDeprecated: isDeprecated);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(cs.returnType, 'dynamic');
    } else {
      expect(cs.returnType, isNull);
    }
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.FUNCTION_TYPE_ALIAS));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    // TODO (danrubel) Determine why params are null
    //    String param = element.parameters;
    //    expect(param, isNotNull);
    //    expect(param[0], equals('('));
    //    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, equals(returnType ?? 'dynamic'));
    // TODO (danrubel) Determine why param info is missing
    //    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestGetter(String name, String returnType,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false}) {
    var cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        elemKind: ElementKind.GETTER,
        isDeprecated: isDeprecated);
    expect(cs.returnType, returnType ?? 'dynamic');
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.GETTER));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, equals(returnType ?? 'dynamic'));
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestMethod(
      String name, String declaringType, String returnType,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false,
      String defaultArgListString = _UNCHECKED,
      List<int> defaultArgumentListTextRanges}) {
    var cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        isDeprecated: isDeprecated,
        defaultArgListString: defaultArgListString,
        defaultArgumentListTextRanges: defaultArgumentListTextRanges);
    expect(cs.declaringType, equals(declaringType));
    expect(cs.returnType, returnType ?? 'dynamic');
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.METHOD));
    expect(element.name, equals(name));
    var param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, returnType ?? 'dynamic');
    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestName(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.IDENTIFIER,
      bool isDeprecated = false}) {
    var cs = assertSuggest(name,
        csKind: kind, relevance: relevance, isDeprecated: isDeprecated);
    expect(cs.completion, equals(name));
    expect(cs.element, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestSetter(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    var cs = assertSuggest(name,
        csKind: kind, relevance: relevance, elemKind: ElementKind.SETTER);
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.SETTER));
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
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    var cs = assertSuggest(name, csKind: kind, relevance: relevance);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else if (isNullExpectedReturnTypeConsideredDynamic) {
      expect(cs.returnType, 'dynamic');
    }
    var element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(ElementKind.TOP_LEVEL_VARIABLE));
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

  Future<void> computeLibrariesContaining() {
    return resolveFile(testFile).then((result) => null);
  }

  Future computeSuggestions() async {
    var result = await resolveFile(testFile);
    request =
        DartCompletionRequestImpl(resourceProvider, completionOffset, result);

    var target =
        CompletionTarget.forOffset(request.result.unit, request.offset);
    var range = target.computeReplacementRange(request.offset);
    replacementOffset = range.offset;
    replacementLength = range.length;

    // Request completions
    var collector = CompletionCollectorImpl();
    await contributor.computeSuggestions(request, collector);
    suggestions = collector.suggestions;
    expect(suggestions, isNotNull, reason: 'expected suggestions');
  }

  CompletionContributor createContributor();

  void failedCompletion(String message,
      [Iterable<CompletionSuggestion> completions]) {
    var sb = StringBuffer(message);
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
      {String completion,
      CompletionSuggestionKind csKind,
      ElementKind elemKind}) {
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
          var element = s.element;
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

  Future<E> performAnalysis<E>(int times, Completer<E> completer) async {
    if (completer.isCompleted) {
      return completer.future;
    }
    // We use a delayed future to allow microtask events to finish. The
    // Future.value or Future() constructors use scheduleMicrotask themselves and
    // would therefore not wait for microtask callbacks that are scheduled after
    // invoking this method.
    return Future.delayed(
        Duration.zero, () => performAnalysis(times - 1, completer));
  }

  void resolveSource(String path, String content) {
    addSource(path, content);
  }

  @override
  void setUp() {
    super.setUp();
    testFile = convertPath('/home/test/lib/test.dart');
    contributor = createContributor();
  }
}

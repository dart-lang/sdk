// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:meta/meta.dart';

typedef CompletionSuggestionChecker = void Function(
  CompletionSuggestionTarget suggestion,
);

typedef CompletionSuggestionTarget
    = CheckTarget<CompletionSuggestionForTesting>;

class CompletionResponseForTesting {
  final int requestOffset;
  final int replacementOffset;
  final int replacementLength;
  final bool isIncomplete;
  final List<CompletionSuggestion> suggestions;

  CompletionResponseForTesting({
    required this.requestOffset,
    required this.replacementOffset,
    required this.replacementLength,
    required this.isIncomplete,
    required this.suggestions,
  });

  factory CompletionResponseForTesting.legacy(
    int requestOffset,
    CompletionResultsParams parameters,
  ) {
    return CompletionResponseForTesting(
      requestOffset: requestOffset,
      replacementOffset: parameters.replacementOffset,
      replacementLength: parameters.replacementLength,
      isIncomplete: false,
      suggestions: parameters.results,
    );
  }
}

/// A completion suggestion with the response for context.
class CompletionSuggestionForTesting {
  final CompletionResponseForTesting response;
  final CompletionSuggestion suggestion;

  CompletionSuggestionForTesting({
    required this.response,
    required this.suggestion,
  });

  /// Return the effective replacement length.
  int get replacementLength =>
      suggestion.replacementLength ?? response.replacementLength;

  /// Return the effective replacement offset.
  int get replacementOffset =>
      suggestion.replacementOffset ?? response.replacementOffset;

  @override
  String toString() => '(completion: ${suggestion.completion})';
}

extension CompletionResponseExtension
    on CheckTarget<CompletionResponseForTesting> {
  @useResult
  CheckTarget<bool> get isIncomplete {
    return nest(
      value.isIncomplete,
      (selected) => 'has isIncomplete ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<int> get replacementLength {
    return nest(
      value.replacementLength,
      (selected) => 'has replacementLength ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<int> get replacementOffset {
    return nest(
      value.replacementOffset,
      (selected) => 'has replacementOffset ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<List<CompletionSuggestionForTesting>> get suggestions {
    var suggestions = value.suggestions.map((e) {
      return CompletionSuggestionForTesting(
        response: value,
        suggestion: e,
      );
    }).toList();
    return nest(
      suggestions,
      (selected) => 'suggestions ${valueStr(selected)}',
    );
  }

  void assertComplete() {
    isIncomplete.isFalse;
  }

  void assertIncomplete() {
    isIncomplete.isTrue;
  }

  /// Check that the replacement offset is the completion request offset,
  /// and the length of the replacement is zero.
  void hasEmptyReplacement() {
    hasReplacement(left: 0, right: 0);
  }

  /// Check that the replacement offset is the completion request offset
  /// minus [left], and the length of the replacement is `left + right`.
  void hasReplacement({int left = 0, int right = 0}) {
    replacementOffset.isEqualTo(value.requestOffset - left);
    replacementLength.isEqualTo(left + right);
  }
}

extension CompletionSuggestionExtension
    on CheckTarget<CompletionSuggestionForTesting> {
  @useResult
  CheckTarget<String> get completion {
    return nest(
      value.suggestion.completion,
      (selected) => 'has completion ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get defaultArgumentListString {
    return nest(
      value.suggestion.defaultArgumentListString,
      (selected) => 'has defaultArgumentListString ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<List<int>?> get defaultArgumentListTextRanges {
    return nest(
      value.suggestion.defaultArgumentListTextRanges,
      (selected) => 'has defaultArgumentListTextRanges ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get docComplete {
    return nest(
      value.suggestion.docComplete,
      (selected) => 'has docComplete ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get docSummary {
    return nest(
      value.suggestion.docSummary,
      (selected) => 'has docSummary ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<Element?> get element {
    return nest(
      value.suggestion.element,
      (selected) => 'has element ${valueStr(selected)}',
    );
  }

  void get isClass {
    kind.isIdentifier;
    element.isNotNull.kind.isClass;
  }

  void get isConstructorInvocation {
    kind.isInvocation;
    element.isNotNull.kind.isConstructor;
  }

  void get isEnum {
    kind.isIdentifier;
    element.isNotNull.kind.isEnum;
  }

  void get isEnumConstant {
    kind.isIdentifier;
    element.isNotNull.kind.isEnumConstant;
  }

  void get isField {
    kind.isIdentifier;
    element.isNotNull.kind.isField;
  }

  void get isFunctionReference {
    kind.isIdentifier;
    element.isNotNull.kind.isFunction;
  }

  void get isGetter {
    kind.isIdentifier;
    element.isNotNull.kind.isGetter;
  }

  void get isImportPrefix {
    kind.isIdentifier;
    element.isNotNull.kind.isPrefix;
  }

  void get isKeywordAny {
    kind.isKeyword;
  }

  void get isMethodInvocation {
    kind.isInvocation;
    element.isNotNull.kind.isMethod;
  }

  void get isMixin {
    kind.isIdentifier;
    element.isNotNull.kind.isMixin;
  }

  void get isNamedArgument {
    kind.isNamedArgument;
    element.isNull;
  }

  @useResult
  CheckTarget<bool?> get isNotImported {
    return nest(
      value.suggestion.isNotImported,
      (selected) => 'has isNotImported ${valueStr(selected)}',
    );
  }

  void get isParameter {
    kind.isIdentifier;
    element.isNotNull.kind.isParameter;
  }

  void get isSetter {
    kind.isIdentifier;
    element.isNotNull.kind.isSetter;
  }

  void get isTopLevelVariable {
    kind.isIdentifier;
    element.isNotNull.kind.isTopLevelVariable;
  }

  @useResult
  CheckTarget<CompletionSuggestionKind> get kind {
    return nest(
      value.suggestion.kind,
      (selected) => 'has kind ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get libraryUri {
    return nest(
      value.suggestion.libraryUri,
      (selected) => 'has libraryUri ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get libraryUriToImport {
    return nest(
      value.suggestion.isNotImported == true
          ? value.suggestion.libraryUri
          : null,
      (selected) => 'has libraryUriToImport ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get parameterType {
    return nest(
      value.suggestion.parameterType,
      (selected) => 'has parameterType ${valueStr(selected)}',
    );
  }

  /// Return the effective replacement length.
  @useResult
  CheckTarget<int> get replacementLength {
    return nest(
      value.replacementLength,
      (selected) => 'has replacementLength ${valueStr(selected)}',
    );
  }

  /// Return the effective replacement offset.
  @useResult
  CheckTarget<int> get replacementOffset {
    return nest(
      value.replacementOffset,
      (selected) => 'has replacementOffset ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String?> get returnType {
    return nest(
      value.suggestion.returnType,
      (selected) => 'has returnType ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<int> get selectionLength {
    return nest(
      value.suggestion.selectionLength,
      (selected) => 'has selectionLength ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<int> get selectionOffset {
    return nest(
      value.suggestion.selectionOffset,
      (selected) => 'has selectionOffset ${valueStr(selected)}',
    );
  }

  /// Check that the effective replacement offset is the completion request
  /// offset, and the length of the replacement is zero.
  void hasEmptyReplacement() {
    hasReplacement(left: 0, right: 0);
  }

  /// Check that the effective replacement offset is the completion request
  /// offset minus [left], and the length of the replacement is `left + right`.
  void hasReplacement({int left = 0, int right = 0}) {
    replacementOffset.isEqualTo(value.response.requestOffset - left);
    replacementLength.isEqualTo(left + right);
  }

  void hasSelection({required int offset, int length = 0}) {
    selectionOffset.isEqualTo(offset);
    selectionLength.isEqualTo(length);
  }

  void isKeyword(Keyword keyword) {
    kind.isKeyword;
    completion.isEqualTo(keyword.lexeme);
  }
}

extension CompletionSuggestionKindExtension
    on CheckTarget<CompletionSuggestionKind> {
  void get isIdentifier {
    isEqualTo(CompletionSuggestionKind.IDENTIFIER);
  }

  void get isInvocation {
    isEqualTo(CompletionSuggestionKind.INVOCATION);
  }

  void get isKeyword {
    isEqualTo(CompletionSuggestionKind.KEYWORD);
  }

  void get isNamedArgument {
    isEqualTo(CompletionSuggestionKind.NAMED_ARGUMENT);
  }
}

extension CompletionSuggestionsExtension
    on CheckTarget<Iterable<CompletionSuggestionForTesting>> {
  @useResult
  CheckTarget<List<String>> get completions {
    return nest(
      value.map((e) => e.suggestion.completion).toList(),
      (selected) => 'completions ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<Iterable<CompletionSuggestionForTesting>> get namedArguments {
    var result = value
        .where((suggestion) =>
            suggestion.suggestion.kind ==
            CompletionSuggestionKind.NAMED_ARGUMENT)
        .toList();
    return nest(
      result,
      (selected) => 'named arguments ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<Iterable<CompletionSuggestionForTesting>> get withElementClass {
    return nest(
      value.where((e) {
        return e.suggestion.element?.kind == ElementKind.CLASS;
      }).toList(),
      (selected) => 'withElementClass ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<Iterable<CompletionSuggestionForTesting>> get withKindKeyword {
    var result = value
        .where((suggestion) =>
            suggestion.suggestion.kind == CompletionSuggestionKind.KEYWORD)
        .toList();
    return nest(
      result,
      (selected) => 'withKindKeyword ${valueStr(selected)}',
    );
  }
}

extension ElementExtension on CheckTarget<Element> {
  @useResult
  CheckTarget<ElementKind> get kind {
    return nest(
      value.kind,
      (selected) => 'has kind ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String> get name {
    return nest(
      value.name,
      (selected) => 'has name ${valueStr(selected)}',
    );
  }
}

extension ElementKindExtension on CheckTarget<ElementKind> {
  void get isClass {
    isEqualTo(ElementKind.CLASS);
  }

  void get isConstructor {
    isEqualTo(ElementKind.CONSTRUCTOR);
  }

  void get isEnum {
    isEqualTo(ElementKind.ENUM);
  }

  void get isEnumConstant {
    isEqualTo(ElementKind.ENUM_CONSTANT);
  }

  void get isField {
    isEqualTo(ElementKind.FIELD);
  }

  void get isFunction {
    isEqualTo(ElementKind.FUNCTION);
  }

  void get isGetter {
    isEqualTo(ElementKind.GETTER);
  }

  void get isMethod {
    isEqualTo(ElementKind.METHOD);
  }

  void get isMixin {
    isEqualTo(ElementKind.MIXIN);
  }

  void get isParameter {
    isEqualTo(ElementKind.PARAMETER);
  }

  void get isPrefix {
    isEqualTo(ElementKind.PREFIX);
  }

  void get isSetter {
    isEqualTo(ElementKind.SETTER);
  }

  void get isTopLevelVariable {
    isEqualTo(ElementKind.TOP_LEVEL_VARIABLE);
  }
}

extension KeywordsExtension on Iterable<Keyword> {
  List<CompletionSuggestionChecker> get asKeywordChecks {
    return map((e) => (CompletionSuggestionTarget suggestion) =>
        suggestion.isKeyword(e)).toList();
  }
}

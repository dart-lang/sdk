// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

/// Information about a code completion suggestion that might or might not be
/// sent to the client (that is, one that is a candidate for being sent).
///
/// The candidate contains the information needed to
/// - determine whether the suggestion should be sent to the client, and
/// - to create the suggestion if it is to be sent.
///
/// A [SuggestionBuilder] will be used to convert a candidate into a concrete
/// suggestion based on the wire protocol being used.
sealed class CandidateSuggestion {
  /// Return the text to be inserted by the completion suggestion.
  String get completion;
}

/// The information about a candidate suggestion based on a constructor.
final class ConstructorSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final ConstructorElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ConstructorSuggestion(this.element);

  @override
  String get completion => element.displayName;
}

/// The information about a candidate suggestion based on an executable element,
/// either a method or function.
sealed class ExecutableSuggestion extends CandidateSuggestion {
  /// The kind of suggestion to be made, either
  /// [CompletionSuggestionKind.IDENTIFIER] or
  /// [CompletionSuggestionKind.INVOCATION].
  final CompletionSuggestionKind kind;

  /// Initialize a newly created suggestion to use the given [kind] of
  /// suggestion.
  ExecutableSuggestion(this.kind)
      : assert(kind == CompletionSuggestionKind.IDENTIFIER ||
            kind == CompletionSuggestionKind.INVOCATION);
}

/// The information about a candidate suggestion based on a field.
final class FieldSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final FieldElement element;

  /// The class from which the field is being referenced, or `null` if the class
  /// is not being referenced from within a class.
  final ClassElement? referencingClass;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  FieldSuggestion(this.element, this.referencingClass);

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a formal parameter.
final class FormalParameterSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final ParameterElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  FormalParameterSuggestion(this.element);

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on an identifier being
/// guessed for a declaration site.
final class IdentifierSuggestion extends CandidateSuggestion {
  /// The identifier to be inserted.
  final String identifier;

  /// Initialize a newly created candidate suggestion to suggest the
  /// [identifier].
  IdentifierSuggestion({required this.identifier});

  @override
  String get completion => identifier;
}

/// The information about a candidate suggestion based on a keyword.
final class KeywordSuggestion extends CandidateSuggestion {
  /// The text to be inserted.
  @override
  final String completion;

  /// The offset, from the beginning of the inserted text, where the cursor
  /// should be positioned.
  final int selectionOffset;

  /// Initialize a newly created candidate suggestion to suggest the [keyword].
  factory KeywordSuggestion.fromKeyword(Keyword keyword) {
    var lexeme = keyword.lexeme;
    return KeywordSuggestion._(
        completion: lexeme, selectionOffset: lexeme.length);
  }

  /// Return a newly created candidate suggestion to suggest the [keyword]
  /// followed by the [annotatedText]. The annotated text is used in cases where
  /// there is boilerplace that always follows the keyword that should also be
  /// suggested.
  ///
  /// If the annotated text contains a caret (`^`), then the completion will use
  /// the annotated text with the caret removed and the index of the caret will
  /// be used as the selection offset. If the text doesn't contain a caret, then
  /// the insert text will be the annotated text and the selection offset will
  /// be at the end of the text.
  factory KeywordSuggestion.fromKeywordAndText(
      Keyword keyword, String annotatedText) {
    var lexeme = keyword.lexeme;
    var caretIndex = annotatedText.indexOf('^');
    String completion;
    int selectionOffset;
    if (caretIndex < 0) {
      completion = lexeme + annotatedText;
      selectionOffset = completion.length;
    } else {
      completion = lexeme +
          annotatedText.substring(0, caretIndex) +
          annotatedText.substring(caretIndex + 1);
      selectionOffset = lexeme.length + caretIndex;
    }
    return KeywordSuggestion._(
      completion: completion,
      selectionOffset: selectionOffset,
    );
  }

  /// Initialize a newly created candidate suggestion to suggest the [keyword].
  factory KeywordSuggestion.fromPseudoKeyword(String keyword) {
    return KeywordSuggestion._(
        completion: keyword, selectionOffset: keyword.length);
  }

  /// Initialize a newly created candidate suggestion to suggest a keyword.
  KeywordSuggestion._(
      {required this.completion, required this.selectionOffset});
}

/// The information about a candidate suggestion based on a label.
final class LabelSuggestion extends CandidateSuggestion {
  /// The label on which the suggestion is based.
  final Label label;

  /// Initialize a newly created candidate suggestion to suggest the [label].
  LabelSuggestion(this.label);

  @override
  String get completion => label.label.name;
}

/// The information about a candidate suggestion based on a local function.
final class LocalFunctionSuggestion extends ExecutableSuggestion {
  /// The element on which the suggestion is based.
  final FunctionElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  LocalFunctionSuggestion(super.kind, this.element);

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a local variable.
final class LocalVariableSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final LocalVariableElement element;

  /// The number of local variables between the completion location and the
  /// declaration of this variable.
  final int distance;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  LocalVariableSuggestion(this.element, this.distance);

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a method.
final class MethodSuggestion extends ExecutableSuggestion {
  /// The element on which the suggestion is based.
  final MethodElement element;

  final ClassElement? referencingClass;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  MethodSuggestion(super.kind, this.element, this.referencingClass);

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a method.
final class PropertyAccessSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final PropertyAccessorElement element;

  final ClassElement? referencingClass;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  PropertyAccessSuggestion(this.element, this.referencingClass);

  @override
  String get completion => element.name;
}

extension SuggestionBuilderExtension on SuggestionBuilder {
  // TODO(brianwilkerson) Move these to `SuggestionBuilder`, possibly as part
  //  of splitting it into a legacy builder and an LSP builder.

  /// Add a suggestion based on the candidate [suggestion].
  void suggestFromCandidate(CandidateSuggestion suggestion) {
    switch (suggestion) {
      case ConstructorSuggestion():
        suggestConstructor(suggestion.element);
      case FieldSuggestion():
        suggestField(suggestion.element,
            inheritanceDistance: _inheritanceDistance(
                suggestion.referencingClass,
                suggestion.element.enclosingElement));
      case FormalParameterSuggestion():
        suggestParameter(suggestion.element);
      case IdentifierSuggestion():
        suggestName(suggestion.identifier);
      case KeywordSuggestion():
        suggestKeyword(suggestion.completion,
            offset: suggestion.selectionOffset);
      case LabelSuggestion():
        suggestLabel(suggestion.label);
      case LocalFunctionSuggestion():
        suggestTopLevelFunction(suggestion.element);
      case LocalVariableSuggestion():
        // TODO(brianwilkerson) Enhance `suggestLocalVariable` to allow the
        //  distance to be passed in.
        suggestLocalVariable(suggestion.element);
      case MethodSuggestion():
        // TODO(brianwilkerson) Correctly set the kind of suggestion in cases
        //  where `isFunctionalArgument` would return `true` so we can stop
        //  using the `request.target`.
        var kind = request.target.isFunctionalArgument()
            ? CompletionSuggestionKind.IDENTIFIER
            : suggestion.kind;
        suggestMethod(
          suggestion.element,
          kind: kind,
          inheritanceDistance: _inheritanceDistance(
              suggestion.referencingClass, suggestion.element.enclosingElement),
        );
      case PropertyAccessSuggestion():
        var inheritanceDistance = 0.0;
        var referencingClass = suggestion.referencingClass;
        var declaringClass = suggestion.element.enclosingElement;
        if (referencingClass != null && declaringClass is InterfaceElement) {
          inheritanceDistance = request.featureComputer
              .inheritanceDistanceFeature(referencingClass, declaringClass);
        }
        suggestAccessor(
          suggestion.element,
          inheritanceDistance: inheritanceDistance,
        );
    }
  }

  /// Add a suggestion for each of the candidate [suggestions].
  void suggestFromCandidates(List<CandidateSuggestion> suggestions) {
    for (var suggestion in suggestions) {
      suggestFromCandidate(suggestion);
    }
  }

  /// Returns the inheritance distance from the [referencingClass] to the
  /// [declaringClass].
  double _inheritanceDistance(
      ClassElement? referencingClass, Element? declaringClass) {
    var distance = 0.0;
    if (referencingClass != null && declaringClass is InterfaceElement) {
      distance = request.featureComputer
          .inheritanceDistanceFeature(referencingClass, declaringClass);
    }
    return distance;
  }
}

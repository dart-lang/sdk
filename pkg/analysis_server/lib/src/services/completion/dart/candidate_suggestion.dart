// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';

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

/// The information about a candidate suggestion based on a class.
final class ClassSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final ClassElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ClassSuggestion({required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// The information about a candidate suggestion based on a constructor.
final class ClosureSuggestion extends CandidateSuggestion {
  /// The type that the closure must conform to.
  final FunctionType functionType;

  /// Whether a trailing comma should be included in the suggestion.
  final bool includeTrailingComma;

  /// Initialize a newly created candidate suggestion to suggest a closure that
  /// conforms to the given [functionType].
  ///
  /// If [includeTrailingComma] is `true`, then the replacement will include a
  /// trailing comma.
  ClosureSuggestion(
      {required this.functionType, required this.includeTrailingComma});

  @override
  // TODO(brianwilkerson): Fix this.
  String get completion => '() {}${includeTrailingComma ? ', ' : ''}';
}

/// The information about a candidate suggestion based on a constructor.
final class ConstructorSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final ConstructorElement element;

  /// Whether the class name is already, implicitly or explicitly, at the call
  /// site. That is, whether we are completing after a period.
  final bool hasClassName;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ConstructorSuggestion(
      {required super.importData,
      required this.element,
      required this.hasClassName});

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a static field in a
/// location where the name of the field must be qualified by the name of the
/// enclosing element.
final class EnumConstantSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final FieldElement element;

  /// Whether the name of the enum should be included in the completion.
  final bool includeEnumName;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  EnumConstantSuggestion(
      {required super.importData,
      required this.element,
      this.includeEnumName = true});

  @override
  String get completion {
    if (includeEnumName) {
      var enclosingElement = element.enclosingElement;
      return '$completionPrefix${enclosingElement.name}.${element.name}';
    } else {
      return element.name;
    }
  }
}

/// The information about a candidate suggestion based on an enum.
final class EnumSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final EnumElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  EnumSuggestion({required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
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
  ExecutableSuggestion({required this.kind})
      : assert(kind == CompletionSuggestionKind.IDENTIFIER ||
            kind == CompletionSuggestionKind.INVOCATION);
}

/// The information about a candidate suggestion based on an extension.
final class ExtensionSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final ExtensionElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ExtensionSuggestion({required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name!}';
}

/// The information about a candidate suggestion based on an extension type.
final class ExtensionTypeSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final ExtensionTypeElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ExtensionTypeSuggestion({required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// The information about a candidate suggestion based on a field.
final class FieldSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final FieldElement element;

  /// The class from which the field is being referenced, or `null` if the class
  /// is not being referenced from within a class.
  final ClassElement? referencingClass;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  FieldSuggestion({required this.element, required this.referencingClass});

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a formal parameter.
final class FormalParameterSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final ParameterElement element;

  /// The number of local variable declarations between the completion location
  /// and [element].
  final int distance;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  FormalParameterSuggestion({
    required this.element,
    required this.distance,
  });

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on the method `call`
/// defined on the class `Function`.
final class FunctionCall extends CandidateSuggestion {
  /// Initialize a newly created candidate suggestion to suggest the method
  /// `call` defined on the class `Function`.
  FunctionCall();

  @override
  String get completion => 'call()';
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

/// The information about a candidate suggestion based on a declaration that can
/// be imported, or a static member of such a declaration.
sealed class ImportableSuggestion extends CandidateSuggestion {
  /// Information about the import used to make this suggestion visible.
  final ImportData? importData;

  ImportableSuggestion({required this.importData});

  String get completionPrefix => prefix == null ? '' : '$prefix.';

  /// The URI of the library from which the suggested element would be imported.
  String? get libraryUriStr => importData?.libraryUriStr;

  /// The prefix to be used in order to access the element.
  String? get prefix => importData?.prefix;
}

/// Data representing an import of a library.
final class ImportData {
  /// The URI of the library from which the suggested element would be imported.
  final String libraryUriStr;

  /// The prefix to be used in order to access the element, or `null` if no
  /// prefix is required.
  final String? prefix;

  /// Initialize data representing an import of a library, using the
  /// [libraryUriStr], with the [prefix].
  ImportData({required this.libraryUriStr, required this.prefix});
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
  factory KeywordSuggestion.fromKeyword({required Keyword keyword}) {
    var lexeme = keyword.lexeme;
    return KeywordSuggestion._(
        completion: lexeme, selectionOffset: lexeme.length);
  }

  /// Initialize a newly created candidate suggestion to suggest the [keyword].
  ///
  /// If [annotatedText] is provided. The annotated text is used in cases where
  /// there is boilerplate that always follows the keyword that should also be
  /// suggested.
  ///
  /// If the annotated text contains a caret (`^`), then the completion will use
  /// the annotated text with the caret removed and the index of the caret will
  /// be used as the selection offset. If the text doesn't contain a caret, then
  /// the insert text will be the annotated text and the selection offset will
  /// be at the end of the text.
  factory KeywordSuggestion.fromKeywordAndText(
      {required Keyword keyword, String? annotatedText}) {
    String completion;
    int selectionOffset;
    var lexeme = keyword.lexeme;
    if (annotatedText == null) {
      completion = lexeme;
      selectionOffset = completion.length;
    } else {
      var caretIndex = annotatedText.indexOf('^');
      if (caretIndex < 0) {
        completion = lexeme + annotatedText;
        selectionOffset = completion.length;
      } else {
        completion = lexeme +
            annotatedText.substring(0, caretIndex) +
            annotatedText.substring(caretIndex + 1);
        selectionOffset = lexeme.length + caretIndex;
      }
    }
    return KeywordSuggestion._(
      completion: completion,
      selectionOffset: selectionOffset,
    );
  }

  /// Initialize a newly created candidate suggestion to suggest the [keyword].
  factory KeywordSuggestion.fromPseudoKeyword({required String keyword}) {
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
  LabelSuggestion({required this.label});

  @override
  String get completion => label.label.name;
}

/// The information about a candidate suggestion based on a local function.
final class LocalFunctionSuggestion extends ExecutableSuggestion {
  /// The element on which the suggestion is based.
  final FunctionElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  LocalFunctionSuggestion({required super.kind, required this.element});

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
  LocalVariableSuggestion({required this.element, required this.distance});

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a method.
final class MethodSuggestion extends ExecutableSuggestion {
  /// The element on which the suggestion is based.
  final MethodElement element;

  final ClassElement? referencingClass;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  MethodSuggestion(
      {required super.kind,
      required this.element,
      required this.referencingClass});

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a mixin.
final class MixinSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final MixinElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  MixinSuggestion({required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// Suggest the name of a named parameter in the argument list of an invocation.
final class NamedArgumentSuggestion extends CandidateSuggestion {
  /// The parameter whose name is to be suggested.
  final ParameterElement parameter;

  /// Whether a colon should be appended after the name.
  final bool appendColon;

  /// Whether a comma should be appended after the suggestion.
  final bool appendComma;

  /// The number of characters that should be replaced, or `null` if the default
  /// doesn't need to be overridden.
  final int? replacementLength;

  NamedArgumentSuggestion(
      {required this.parameter,
      required this.appendColon,
      required this.appendComma,
      this.replacementLength});

  @override
  String get completion =>
      '${parameter.name}${appendColon ? ': ' : ''}${appendComma ? ',' : ''}';
}

/// The information about a candidate suggestion based on a getter or setter.
final class NameSuggestion extends CandidateSuggestion {
  /// The name being suggested.
  final String name;

  /// Initialize a newly created candidate suggestion to suggest the [name].
  NameSuggestion({required this.name});

  @override
  String get completion => name;
}

/// The information about a candidate suggestion to create an override of an
/// inherited method.
final class OverrideSuggestion extends CandidateSuggestion {
  /// The method to be overridden.
  final ExecutableElement element;

  /// Whether `super` should be invoked in the body of the override.
  final bool shouldInvokeSuper;

  /// The soruce range that should be replaced by the override.
  final SourceRange replacementRange;

  /// Initialize a newly created candidate suggestion to suggest the [element] by
  /// inserting the [shouldInvokeSuper].
  OverrideSuggestion(
      {required this.element,
      required this.shouldInvokeSuper,
      required this.replacementRange});

  @override
  // TODO(brianwilkerson): This needs to be replaced with code to compute the
  //  actual completion when we remove SuggestionBuilder.
  String get completion => '@override ${element.displayName}';
}

/// The information about a candidate suggestion based on a getter or setter.
final class PropertyAccessSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final PropertyAccessorElement element;

  final ClassElement? referencingClass;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  PropertyAccessSuggestion(
      {required this.element, required this.referencingClass});

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a field in a record
/// type.
final class RecordFieldSuggestion extends CandidateSuggestion {
  /// The field on which the suggestion is based.
  final RecordTypeField field;

  /// The name of the field.
  final String name;

  /// Initialize a newly created candidate suggestion to suggest the [field] by
  /// inserting the [name].
  RecordFieldSuggestion({required this.field, required this.name});

  @override
  String get completion => name;
}

/// The information about a candidate suggestion based on a static field in a
/// location where the name of the field must be qualified by the name of the
/// enclosing element.
final class StaticFieldSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final FieldElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  StaticFieldSuggestion({required super.importData, required this.element});

  @override
  String get completion {
    var enclosingElement = element.enclosingElement;
    return '$completionPrefix${enclosingElement.name}.${element.name}';
  }
}

/// The information about a candidate suggestion based on a parameter from a
/// super constructor.
final class SuperParameterSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final ParameterElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  SuperParameterSuggestion({required this.element});

  @override
  String get completion => element.name;
}

/// The information about a candidate suggestion based on a top-level getter or
/// setter.
final class TopLevelFunctionSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final FunctionElement element;

  /// The kind of suggestion to be made, either
  /// [CompletionSuggestionKind.IDENTIFIER] or
  /// [CompletionSuggestionKind.INVOCATION].
  final CompletionSuggestionKind kind;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelFunctionSuggestion(
      {required super.importData, required this.element, required this.kind})
      : assert(kind == CompletionSuggestionKind.IDENTIFIER ||
            kind == CompletionSuggestionKind.INVOCATION);

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// The information about a candidate suggestion based on a top-level getter or
/// setter.
final class TopLevelPropertyAccessSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final PropertyAccessorElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelPropertyAccessSuggestion(
      {required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// The information about a candidate suggestion based on a top-level variable.
final class TopLevelVariableSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final TopLevelVariableElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelVariableSuggestion(
      {required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// The information about a candidate suggestion based on a type alias.
final class TypeAliasSuggestion extends ImportableSuggestion {
  /// The element on which the suggestion is based.
  final TypeAliasElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TypeAliasSuggestion({required super.importData, required this.element});

  @override
  String get completion => '$completionPrefix${element.name}';
}

/// The information about a candidate suggestion based on a type parameter.
final class TypeParameterSuggestion extends CandidateSuggestion {
  /// The element on which the suggestion is based.
  final TypeParameterElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TypeParameterSuggestion({required this.element});

  @override
  String get completion => element.name;
}

extension SuggestionBuilderExtension on SuggestionBuilder {
  // TODO(brianwilkerson): Move these to `SuggestionBuilder`, possibly as part
  //  of splitting it into a legacy builder and an LSP builder.

  /// Add a suggestion based on the candidate [suggestion].
  void suggestFromCandidate(CandidateSuggestion suggestion) {
    switch (suggestion) {
      case ClassSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestInterface(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case ClosureSuggestion():
        suggestClosure(suggestion.functionType,
            includeTrailingComma: suggestion.includeTrailingComma);
      case ConstructorSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestConstructor(suggestion.element,
            hasClassName: suggestion.hasClassName, prefix: suggestion.prefix);
        libraryUriStr = null;
      case EnumSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestInterface(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case EnumConstantSuggestion():
        if (suggestion.includeEnumName) {
          libraryUriStr = suggestion.libraryUriStr;
          suggestEnumConstant(suggestion.element, prefix: suggestion.prefix);
          libraryUriStr = null;
        } else {
          suggestField(suggestion.element, inheritanceDistance: 0.0);
        }
      case ExtensionSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestExtension(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case ExtensionTypeSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestInterface(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case FieldSuggestion():
        var fieldElement = suggestion.element;
        if (fieldElement.isEnumConstant) {
          suggestEnumConstant(fieldElement);
        } else {
          suggestField(fieldElement,
              inheritanceDistance: _inheritanceDistance(
                  suggestion.referencingClass,
                  suggestion.element.enclosingElement));
        }
      case FormalParameterSuggestion():
        suggestFormalParameter(
          element: suggestion.element,
          distance: suggestion.distance,
        );
      case FunctionCall():
        suggestFunctionCall();
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
        suggestLocalVariable(
          element: suggestion.element,
          distance: suggestion.distance,
        );
      case MethodSuggestion():
        // TODO(brianwilkerson): Correctly set the kind of suggestion in cases
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
      case MixinSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestInterface(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case NamedArgumentSuggestion():
        suggestNamedArgument(suggestion.parameter,
            appendColon: suggestion.appendColon,
            appendComma: suggestion.appendComma,
            replacementLength: suggestion.replacementLength);
      case NameSuggestion():
        suggestName(suggestion.name);
      case OverrideSuggestion():
        suggestOverride2(suggestion.element, suggestion.shouldInvokeSuper,
            suggestion.replacementRange);
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
      case RecordFieldSuggestion():
        suggestRecordField(field: suggestion.field, name: suggestion.name);
      case StaticFieldSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestStaticField(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case SuperParameterSuggestion():
        suggestSuperFormalParameter(suggestion.element);
      case TopLevelFunctionSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestTopLevelFunction(suggestion.element,
            kind: suggestion.kind, prefix: suggestion.prefix);
        libraryUriStr = null;
      case TopLevelPropertyAccessSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestTopLevelPropertyAccessor(suggestion.element,
            prefix: suggestion.prefix);
        libraryUriStr = null;
      case TopLevelVariableSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestTopLevelVariable(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case TypeAliasSuggestion():
        libraryUriStr = suggestion.libraryUriStr;
        suggestTypeAlias(suggestion.element, prefix: suggestion.prefix);
        libraryUriStr = null;
      case TypeParameterSuggestion():
        suggestTypeParameter(suggestion.element);
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

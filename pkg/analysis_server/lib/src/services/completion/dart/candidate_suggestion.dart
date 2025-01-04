// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/utilities/completion_matcher.dart';
library;

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
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
  /// The score computed by a [CompletionMatcher] for this suggestion.
  final double matcherScore;

  /// The relevance score for this suggestion.
  ///
  /// The relevance score isn't computed until after the list of candidate
  /// suggestions has been completed.
  int relevanceScore = -1;

  CandidateSuggestion({required this.matcherScore}) : assert(matcherScore >= 0);

  /// The text to be inserted by the completion suggestion.
  String get completion;

  @override
  String toString() {
    return completion;
  }
}

/// The information about a candidate suggestion based on a class.
final class ClassSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final ClassElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ClassSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.name3}';
}

/// The information about a candidate suggestion based on a constructor.
final class ClosureSuggestion extends CandidateSuggestion with SuggestionData {
  /// The type that the closure must conform to.
  final FunctionType functionType;

  /// Whether a trailing comma should be included in the suggestion.
  final bool includeTrailingComma;

  /// Whether the code for the closure is a block or an expression.
  final bool useBlockStatement;

  /// Whether types should be specified whenever possible.
  final bool includeTypes;

  /// The identation to be used for a multi-line completion.
  final String indent;

  /// Initialize a newly created candidate suggestion to suggest a closure that
  /// conforms to the given [functionType].
  ///
  /// If [includeTrailingComma] is `true`, then the replacement will include a
  /// trailing comma.
  ClosureSuggestion({
    required this.functionType,
    required this.includeTrailingComma,
    required super.matcherScore,
    required this.includeTypes,
    required this.indent,
    this.useBlockStatement = true,
  });

  @override
  String get completion {
    _init();
    return _data!.completion;
  }

  @override
  void _init() {
    if (_data != null) {
      return;
    }
    var parametersString = buildClosureParameters(
      functionType,
      includeTypes: includeTypes,
      includeKeywords: true,
    );
    // Build a short version of the parameter string without keywords or types
    // for the completion label because they're less useful there and may push
    // the end of the completion (`=>` vs `() {}`) off the end.
    var parametersDisplayString = buildClosureParameters(
      functionType,
      includeKeywords: false,
      includeTypes: false,
    );

    var stringBuffer = StringBuffer(parametersString);
    String displayText;
    int selectionOffset;
    if (useBlockStatement) {
      displayText = '$parametersDisplayString {}';
      stringBuffer.writeln(' {');
      stringBuffer.write('$indent  ');
      selectionOffset = stringBuffer.length;
      stringBuffer.writeln();
      stringBuffer.write('$indent}');
    } else {
      displayText = '$parametersDisplayString =>';
      stringBuffer.write(' => ');
      selectionOffset = stringBuffer.length;
    }
    if (includeTrailingComma) {
      stringBuffer.write(',');
    }
    var completion = stringBuffer.toString();
    _data = _Data(completion, selectionOffset, displayText: displayText);
  }
}

/// The information about a candidate suggestion based on a constructor.
final class ConstructorSuggestion extends ExecutableSuggestion
    implements ElementBasedSuggestion {
  @override
  final ConstructorElement2 element;

  /// Whether the class name is already, implicitly or explicitly, at the call
  /// site. That is, whether we are completing after a period.
  final bool hasClassName;

  /// Whether a tear-off should be suggested, not an invocation.
  /// Mutually exclusive with [isRedirect].
  final bool isTearOff;

  /// Whether the unnamed constructor should be suggested.
  final bool suggestUnnamedAsNew;

  /// Whether a redirect should be suggested, not an invocation.
  /// Mutually exclusive with [isTearOff].
  ///
  /// When `true`, the unnamed constructor reference is `ClassName`.
  /// OTOH, if [isTearOff] is `true`, we get `ClassName.new`.
  final bool isRedirect;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ConstructorSuggestion({
    required super.importData,
    required this.element,
    required this.hasClassName,
    required this.isTearOff,
    required this.isRedirect,
    required this.suggestUnnamedAsNew,
    required super.matcherScore,
  }) : assert((isTearOff ? 1 : 0) | (isRedirect ? 1 : 0) < 2),
       super(
         kind:
             isTearOff || isRedirect
                 ? CompletionSuggestionKind.IDENTIFIER
                 : CompletionSuggestionKind.INVOCATION,
       );

  @override
  String get completion {
    var enclosingClass = element.enclosingElement2;

    var className = enclosingClass.displayName;

    // TODO(scheglov): Wrong, if no name, should be no completion.
    var completion = element.name3 ?? '';
    if (suggestUnnamedAsNew) {
      if (completion.isEmpty) {
        completion = 'new';
      }
    } else {
      if (completion == 'new') {
        completion = '';
      }
    }
    if (!hasClassName) {
      if (completion.isEmpty) {
        completion = className;
      } else {
        completion = '$className.$completion';
      }
    }
    return completion;
  }
}

abstract interface class ElementBasedSuggestion {
  /// The element on which the suggestion is based.
  Element2 get element;
}

/// The information about a candidate suggestion based on a static field in a
/// location where the name of the field must be qualified by the name of the
/// enclosing element.
final class EnumConstantSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final FieldElement2 element;

  /// Whether the name of the enum should be included in the completion.
  final bool includeEnumName;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  EnumConstantSuggestion({
    required super.importData,
    required this.element,
    this.includeEnumName = true,
    required super.matcherScore,
  });

  @override
  String get completion {
    if (includeEnumName) {
      var enclosingElement = element.enclosingElement2;
      return '$completionPrefix${enclosingElement.displayName}.${element.displayName}';
    } else {
      return element.displayName;
    }
  }
}

/// The information about a candidate suggestion based on an enum.
final class EnumSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final EnumElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  EnumSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on an executable element,
/// either a method or function.
sealed class ExecutableSuggestion extends ImportableSuggestion {
  /// The kind of suggestion to be made, either
  /// [CompletionSuggestionKind.IDENTIFIER] or
  /// [CompletionSuggestionKind.INVOCATION].
  final CompletionSuggestionKind kind;

  /// Initialize a newly created suggestion to use the given [kind] of
  /// suggestion.
  ExecutableSuggestion({
    required super.importData,
    required this.kind,
    required super.matcherScore,
  }) : assert(
         kind == CompletionSuggestionKind.IDENTIFIER ||
             kind == CompletionSuggestionKind.INVOCATION,
       );
}

/// The information about a candidate suggestion based on an extension.
final class ExtensionSuggestion extends ExecutableSuggestion
    implements ElementBasedSuggestion {
  @override
  final ExtensionElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ExtensionSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
    super.kind = CompletionSuggestionKind.INVOCATION,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on an extension type.
final class ExtensionTypeSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final ExtensionTypeElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  ExtensionTypeSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a field.
final class FieldSuggestion extends CandidateSuggestion with MemberSuggestion {
  @override
  final FieldElement2 element;

  /// The element defined by the declaration in which the suggestion is to be
  /// applied, or `null` if the completion is in a static context.
  @override
  final InterfaceElement2? referencingInterface;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  FieldSuggestion({
    required this.element,
    required super.matcherScore,
    required this.referencingInterface,
  });

  @override
  String get completion {
    if (element.isEnumConstant) {
      var constantName = element.name3;
      var enumName = element.enclosingElement2.displayName;
      return '$enumName.$constantName';
    }
    return element.displayName;
  }
}

/// The information about a candidate suggestion based on a formal parameter.
final class FormalParameterSuggestion extends CandidateSuggestion
    implements ElementBasedSuggestion {
  @override
  final FormalParameterElement element;

  /// The number of local variable declarations between the completion location
  /// and [element].
  final int distance;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  FormalParameterSuggestion({
    required this.element,
    required this.distance,
    required super.matcherScore,
  });

  @override
  String get completion => element.displayName;
}

/// The information about a candidate suggestion based on the method `call`
/// defined on the class `Function`.
final class FunctionCall extends CandidateSuggestion {
  /// Initialize a newly created candidate suggestion to suggest the method
  /// `call` defined on the class `Function`.
  FunctionCall({required super.matcherScore});

  @override
  String get completion => 'call()';
}

/// The information about a candidate suggestion based on a getter.
final class GetterSuggestion extends ImportableSuggestion
    with MemberSuggestion {
  @override
  final GetterElement element;

  /// The element defined by the declaration in which the suggestion is to be
  /// applied, or `null` if the completion is in a static context.
  @override
  final InterfaceElement2? referencingInterface;

  /// Whether the accessor is being invoked with a target.
  final bool withEnclosingName;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  GetterSuggestion({
    required this.element,
    required super.importData,
    required this.referencingInterface,
    required super.matcherScore,
    this.withEnclosingName = false,
  });

  @override
  String get completion {
    var prefix = _enclosingPrefix;
    if (prefix.isNotEmpty) {
      return '$prefix${element.displayName}';
    }
    return element.displayName;
  }

  /// Return the name of the enclosing class or extension.
  ///
  /// The enclosing element must be either a class, or extension; otherwise
  /// we either fail with assertion, or return `null`.
  String? get _enclosingClassOrExtensionName {
    var enclosing = element.enclosingElement2;
    if (enclosing is InterfaceElement2) {
      return enclosing.displayName;
    } else if (enclosing is ExtensionElement2) {
      return enclosing.displayName;
    } else {
      assert(false, 'Expected ClassElement or ExtensionElement');
      return null;
    }
  }

  String get _enclosingPrefix {
    if (withEnclosingName) {
      var enclosingName = _enclosingClassOrExtensionName;
      return enclosingName != null ? '$enclosingName.' : '';
    }
    return '';
  }
}

/// The information about a candidate suggestion based on an identifier being
/// guessed for a declaration site.
final class IdentifierSuggestion extends CandidateSuggestion {
  /// The identifier to be inserted.
  final String identifier;

  /// Whether an empty body should be included in the completion string.
  final bool includeBody;

  /// Initialize a newly created candidate suggestion to suggest the
  /// [identifier].
  ///
  /// If [includeBody] is `true`, then empty curly braces will be included in
  /// the suggestion.
  IdentifierSuggestion({
    required this.identifier,
    required this.includeBody,
    required super.matcherScore,
  });

  @override
  String get completion => identifier + (includeBody ? ' {}' : '');

  /// The offset, from the beginning of the inserted text, where the cursor
  /// should be positioned.
  int get selectionOffset => identifier.length + (includeBody ? 2 : 0);
}

/// The information about a candidate suggestion based on a declaration that can
/// be imported, or a static member of such a declaration.
sealed class ImportableSuggestion extends CandidateSuggestion {
  /// Information about the import used to make this suggestion visible.
  final ImportData? importData;

  ImportableSuggestion({required this.importData, required super.matcherScore});

  /// The text to add before the name of the element when it is being imported
  /// using an import prefix.
  String get completionPrefix {
    var prefixName = prefix;
    return prefixName == null ? '' : '$prefixName.';
  }

  /// Whether this is suggesing an element that is not yet imported into the
  /// library in which completion was requested.
  bool get isNotImported => importData?.isNotImported ?? false;

  /// The prefix to be used in order to access the element.
  String? get prefix => importData?.prefix;
}

/// Data representing an import of a library.
final class ImportData {
  /// Whether the library needs to be imported in order for the suggestion to be
  /// accessible.
  ///
  /// This will return `false` when the library is already imported but the
  /// import needs to be updated, such as by adding the element to a `show`
  /// clause.
  final bool isNotImported;

  /// The URI of the library from which the suggested element would be imported.
  final Uri libraryUri;

  /// The prefix to be used in order to access the element, or `null` if no
  /// prefix is required.
  final String? prefix;

  /// Initialize data representing an import of a library, using the
  /// [libraryUri], with the [prefix].
  ImportData({
    required this.libraryUri,
    required this.prefix,
    required this.isNotImported,
  });
}

/// A suggestion based on an import prefix.
final class ImportPrefixSuggestion extends CandidateSuggestion
    implements ElementBasedSuggestion {
  final LibraryElement2 libraryElement;

  final PrefixElement2 prefixElement;

  ImportPrefixSuggestion({
    required this.libraryElement,
    required this.prefixElement,
    required super.matcherScore,
  });

  @override
  String get completion => prefixElement.displayName;

  @override
  Element2 get element => prefixElement;
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
  factory KeywordSuggestion.fromKeyword({
    required Keyword keyword,
    required String? annotatedText,
    required double matcherScore,
  }) {
    var completion = keyword.lexeme;
    var selectionOffset = completion.length;

    if (annotatedText != null) {
      var (rawText, caretIndex) = annotatedText.withoutCaret;
      completion += rawText;
      selectionOffset += caretIndex ?? rawText.length;
    }

    return KeywordSuggestion._(
      completion: completion,
      selectionOffset: selectionOffset,
      matcherScore: matcherScore,
    );
  }

  /// If [annotatedText] contains a caret (`^`), then the completion will use
  /// the annotated text with the caret removed and the index of the caret will
  /// be used as the selection offset. If the text doesn't contain a caret, then
  /// the insert text will be the annotated text and the selection offset will
  /// be at the end of the text.
  factory KeywordSuggestion.fromText(
    String annotatedText, {
    required double matcherScore,
  }) {
    var (rawText, caretIndex) = annotatedText.withoutCaret;
    return KeywordSuggestion._(
      completion: rawText,
      selectionOffset: caretIndex ?? rawText.length,
      matcherScore: matcherScore,
    );
  }

  /// Initialize a newly created candidate suggestion to suggest a keyword.
  KeywordSuggestion._({
    required this.completion,
    required this.selectionOffset,
    required super.matcherScore,
  });
}

/// The information about a candidate suggestion based on a label.
final class LabelSuggestion extends CandidateSuggestion {
  /// The label on which the suggestion is based.
  final Label label;

  /// Initialize a newly created candidate suggestion to suggest the [label].
  LabelSuggestion({required this.label, required super.matcherScore});

  @override
  String get completion => label.label.name;
}

/// The suggestion for `loadLibrary()`.
final class LoadLibraryFunctionSuggestion extends ExecutableSuggestion
    implements ElementBasedSuggestion {
  @override
  final TopLevelFunctionElement element;

  LoadLibraryFunctionSuggestion({
    required super.kind,
    required this.element,
    required super.matcherScore,
  }) : super(importData: null);

  @override
  String get completion => element.displayName;
}

/// The information about a candidate suggestion based on a local function.
final class LocalFunctionSuggestion extends ExecutableSuggestion
    implements ElementBasedSuggestion {
  @override
  final LocalFunctionElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  LocalFunctionSuggestion({
    required super.kind,
    required this.element,
    required super.matcherScore,
  }) : super(importData: null);

  @override
  String get completion => element.displayName;
}

/// The information about a candidate suggestion based on a local variable.
final class LocalVariableSuggestion extends CandidateSuggestion
    implements ElementBasedSuggestion {
  @override
  final LocalVariableElement2 element;

  /// The number of local variables between the completion location and the
  /// declaration of this variable.
  final int distance;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  LocalVariableSuggestion({
    required this.element,
    required this.distance,
    required super.matcherScore,
  });

  @override
  String get completion => element.displayName;
}

/// Behavior common to suggestions that are for members of a class, enum, mixin,
/// etc.
mixin MemberSuggestion implements ElementBasedSuggestion {
  /// The element defined by the declaration in which the suggestion is to be
  /// applied, or `null` if the completion is in a static context.
  InterfaceElement2? get referencingInterface;

  /// Returns the value of the inheritance distance feature.
  ///
  /// Uses the [featureComputer] to compute the value.
  double inheritanceDistance(FeatureComputer featureComputer) {
    var inheritanceDistance = 0.0;
    var element = this.element;
    if (!(element is FieldElement2 && element.isEnumConstant)) {
      var declaringClass = element.enclosingElement2;
      var referencingInterface = this.referencingInterface;
      if (referencingInterface != null && declaringClass is InterfaceElement2) {
        inheritanceDistance = featureComputer.inheritanceDistanceFeature(
          referencingInterface,
          declaringClass,
        );
      }
    }
    return inheritanceDistance;
  }
}

/// The information about a candidate suggestion based on a method.
final class MethodSuggestion extends ExecutableSuggestion
    with MemberSuggestion {
  @override
  final MethodElement2 element;

  /// The element defined by the declaration in which the suggestion is to be
  /// applied, or `null` if the completion is in a static context.
  @override
  final InterfaceElement2? referencingInterface;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  MethodSuggestion({
    required super.kind,
    required this.element,
    required super.importData,
    required this.referencingInterface,
    required super.matcherScore,
  });

  @override
  String get completion => element.displayName;
}

/// The information about a candidate suggestion based on a mixin.
final class MixinSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final MixinElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  MixinSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// Suggest the name of a named parameter in the argument list of an invocation.
final class NamedArgumentSuggestion extends CandidateSuggestion
    with SuggestionData {
  /// The parameter whose name is to be suggested.
  final FormalParameterElement parameter;

  /// Whether a colon should be appended after the name.
  final bool appendColon;

  /// Whether a comma should be appended after the suggestion.
  final bool appendComma;

  /// The number of characters that should be replaced, or `null` if the default
  /// doesn't need to be overridden.
  final int? replacementLength;

  final bool isWidget;

  String preferredQuoteForStrings;

  NamedArgumentSuggestion({
    required this.parameter,
    required this.appendColon,
    required this.appendComma,
    this.replacementLength,
    required super.matcherScore,
    required this.preferredQuoteForStrings,
    this.isWidget = false,
  });

  @override
  String get completion {
    _init();
    return _data!.completion;
  }

  @override
  String get displayText => completion;

  @override
  void _init() {
    if (_data != null) {
      return;
    }
    var completion = parameter.displayName;
    if (appendColon) {
      completion += ': ';
    }
    var selectionOffset = completion.length;

    // Optionally add Flutter child widget details.
    // TODO(pq): revisit this special casing; likely it can be generalized away.
    if (isWidget && appendColon) {
      var defaultValue = getDefaultStringParameterValue(
        parameter,
        preferredQuoteForStrings,
      );
      // TODO(devoncarew): Should we remove the check here? We would then
      // suggest values for param types like closures.
      if (defaultValue != null && defaultValue.text == '[]') {
        var completionLength = completion.length;
        completion += defaultValue.text;
        var cursorPosition = defaultValue.cursorPosition;
        if (cursorPosition != null) {
          selectionOffset = completionLength + cursorPosition;
        }
      }
    }
    if (appendComma) {
      completion += ',';
    }
    _data = _Data(completion, selectionOffset);
  }
}

/// The information about a candidate suggestion based on a getter or setter.
final class NameSuggestion extends CandidateSuggestion {
  /// The name being suggested.
  final String name;

  /// Initialize a newly created candidate suggestion to suggest the [name].
  NameSuggestion({required this.name, required super.matcherScore});

  @override
  String get completion => name;
}

/// Additional information needed for an [OverrideSuggestion]. This should be
/// computed when the [CandidateSuggestion] is converted over to the completion
/// item.
class OverrideData {
  final String completion;
  final String displayText;
  final Set<Uri> imports;
  final int selectionOffset;
  final int selectionLength;

  OverrideData(
    this.completion,
    this.displayText,
    this.imports,
    this.selectionOffset,
    this.selectionLength,
  );
}

/// The information about a candidate suggestion to create an override of an
/// inherited method.
final class OverrideSuggestion extends CandidateSuggestion
    implements ElementBasedSuggestion {
  @override
  final ExecutableElement2 element;

  /// Whether `super` should be invoked in the body of the override.
  final bool shouldInvokeSuper;

  /// If `true`, `@override` is already present, at least partially.
  /// So, `@` is already present, and the override text does not need it.
  final bool skipAt;

  /// The source range that should be replaced by the override.
  final SourceRange replacementRange;

  /// Data required for the suggestion, computed when [CandidateSuggestion]
  /// is converted to a completion item as per the protocol.
  OverrideData? data;

  /// Initialize a newly created candidate suggestion to suggest the [element]
  /// by inserting the [shouldInvokeSuper].
  OverrideSuggestion({
    required this.element,
    required this.shouldInvokeSuper,
    required this.skipAt,
    required this.replacementRange,
    required super.matcherScore,
  });

  @override
  String get completion =>
      data?.completion ?? '@override ${element.displayName}';
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
  RecordFieldSuggestion({
    required this.field,
    required this.name,
    required super.matcherScore,
  });

  @override
  String get completion => name;
}

/// The information about a candidate suggestion based on a named field of
/// a record type.
final class RecordLiteralNamedFieldSuggestion extends CandidateSuggestion
    with SuggestionData {
  final RecordTypeNamedField field;
  final bool appendColon;
  final bool appendComma;

  RecordLiteralNamedFieldSuggestion.newField({
    required this.field,
    required this.appendComma,
    required super.matcherScore,
  }) : appendColon = true;

  RecordLiteralNamedFieldSuggestion.onlyName({
    required this.field,
    required super.matcherScore,
  }) : appendColon = false,
       appendComma = false;

  @override
  String get completion {
    _init();
    return _data!.completion;
  }

  @override
  String get displayText => completion;

  @override
  void _init() {
    if (_data != null) {
      return;
    }
    var name = field.name;

    var completion = name;
    if (appendColon) {
      completion += ': ';
    }
    var selectionOffset = completion.length;

    if (appendComma) {
      completion += ',';
    }
    _data = _Data(completion, selectionOffset);
  }
}

/// The information about a candidate suggestion for Flutter's `setState` method.
final class SetStateMethodSuggestion extends ExecutableSuggestion
    with MemberSuggestion, SuggestionData {
  @override
  final MethodElement2 element;

  /// The element defined by the declaration in which the suggestion is to be
  /// applied, or `null` if the completion is in a static context.
  @override
  final InterfaceElement2? referencingInterface;

  /// The identation to be used for a multi-line completion.
  final String indent;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  SetStateMethodSuggestion({
    required this.element,
    required super.importData,
    required this.referencingInterface,
    required super.matcherScore,
    required this.indent,
    super.kind = CompletionSuggestionKind.INVOCATION,
  });

  @override
  String get completion {
    _init();
    return _data!.completion;
  }

  @override
  void _init() {
    if (_data != null) {
      return;
    }
    // Build the completion and the selection offset.
    var buffer = StringBuffer();
    buffer.writeln('setState(() {');
    buffer.write('$indent  ');
    var selectionOffset = buffer.length;
    buffer.writeln();
    buffer.write('$indent});');
    var completion = buffer.toString();
    _data = _Data(completion, selectionOffset, displayText: 'setState(() {});');
  }
}

/// The information about a candidate suggestion based on a setter.
final class SetterSuggestion extends ImportableSuggestion
    with MemberSuggestion {
  @override
  final SetterElement element;

  /// The element defined by the declaration in which the suggestion is to be
  /// applied, or `null` if the completion is in a static context.
  @override
  final InterfaceElement2? referencingInterface;

  /// Whether the accessor is being invoked with a target.
  final bool withEnclosingName;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  SetterSuggestion({
    required this.element,
    required super.importData,
    required this.referencingInterface,
    required super.matcherScore,
    this.withEnclosingName = false,
  });

  @override
  String get completion {
    var prefix = _enclosingPrefix;
    if (prefix.isNotEmpty) {
      return '$prefix${element.displayName}';
    }
    return element.displayName;
  }

  /// Return the name of the enclosing class or extension.
  ///
  /// The enclosing element must be either a class, or extension; otherwise
  /// we either fail with assertion, or return `null`.
  String? get _enclosingClassOrExtensionName {
    var enclosing = element.enclosingElement2;
    if (enclosing is InterfaceElement2) {
      return enclosing.displayName;
    } else if (enclosing is ExtensionElement2) {
      return enclosing.displayName;
    } else {
      assert(false, 'Expected ClassElement or ExtensionElement');
      return null;
    }
  }

  String get _enclosingPrefix {
    if (withEnclosingName) {
      var enclosingName = _enclosingClassOrExtensionName;
      return enclosingName != null ? '$enclosingName.' : '';
    }
    return '';
  }
}

/// The information about a candidate suggestion based on a static field in a
/// location where the name of the field must be qualified by the name of the
/// enclosing element.
final class StaticFieldSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final FieldElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  StaticFieldSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion {
    var enclosingElement = element.enclosingElement2;
    return '$completionPrefix${enclosingElement.displayName}.${element.displayName}';
  }
}

/// Behavior common to suggestions where completion text, [selectionOffset],
/// and [displayText] is computed.
mixin SuggestionData {
  _Data? _data;

  /// Text to be displayed in a completion pop-up.
  String get displayText {
    _init();
    return _data!.displayText;
  }

  /// The offset, from the beginning of the inserted text, where the cursor
  /// should be positioned.
  int get selectionOffset {
    _init();
    return _data!.selectionOffset;
  }

  void _init();
}

/// The information about a candidate suggestion based on a parameter from a
/// super constructor.
final class SuperParameterSuggestion extends CandidateSuggestion
    implements ElementBasedSuggestion {
  @override
  final FormalParameterElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  SuperParameterSuggestion({
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => element.displayName;
}

/// The information about a candidate suggestion based on a top-level getter or
/// setter.
final class TopLevelFunctionSuggestion extends ExecutableSuggestion
    implements ElementBasedSuggestion {
  @override
  final TopLevelFunctionElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelFunctionSuggestion({
    required super.importData,
    required this.element,
    required super.kind,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a top-level getter.
final class TopLevelGetterSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final GetterElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelGetterSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a top-level setter.
final class TopLevelSetterSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final SetterElement element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelSetterSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a top-level variable.
final class TopLevelVariableSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final TopLevelVariableElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TopLevelVariableSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a type alias.
final class TypeAliasSuggestion extends ImportableSuggestion
    implements ElementBasedSuggestion {
  @override
  final TypeAliasElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TypeAliasSuggestion({
    required super.importData,
    required this.element,
    required super.matcherScore,
  });

  @override
  String get completion => '$completionPrefix${element.displayName}';
}

/// The information about a candidate suggestion based on a type parameter.
final class TypeParameterSuggestion extends CandidateSuggestion
    implements ElementBasedSuggestion {
  @override
  final TypeParameterElement2 element;

  /// Initialize a newly created candidate suggestion to suggest the [element].
  TypeParameterSuggestion({required this.element, required super.matcherScore});

  @override
  String get completion => element.displayName;
}

/// The URI suggestion.
final class UriSuggestion extends CandidateSuggestion {
  final String uriStr;

  UriSuggestion({required this.uriStr, required super.matcherScore});

  @override
  String get completion => uriStr;
}

/// Information computed for some the code completion suggestions.
class _Data {
  String displayText;

  int selectionOffset;

  String completion;

  _Data(this.completion, this.selectionOffset, {this.displayText = ''});
}

extension on String {
  (String, int?) get withoutCaret {
    var caretIndex = indexOf('^');
    if (caretIndex < 0) {
      return (this, null);
    } else {
      var rawText = substring(0, caretIndex) + substring(caretIndex + 1);
      return (rawText, caretIndex);
    }
  }
}

extension SuggestionBuilderExtension on SuggestionBuilder {
  // TODO(brianwilkerson): Move these to `SuggestionBuilder`, possibly as part
  //  of splitting it into a legacy builder and an LSP builder.

  /// Add a suggestion based on the candidate [suggestion].
  Future<void> suggestFromCandidate(CandidateSuggestion suggestion) async {
    if (suggestion is ImportableSuggestion) {
      var importData = suggestion.importData;
      if (importData != null) {
        var uri = importData.libraryUri;
        if (importData.isNotImported) {
          isNotImportedLibrary = true;
          requiredImports = [uri];
        }
        libraryUriStr = uri.toString();
      }
    }

    var relevance = relevanceComputer.computeRelevance(suggestion);
    switch (suggestion) {
      case ClassSuggestion():
        suggestInterface(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case ClosureSuggestion():
        suggestClosure(
          completion: suggestion.completion,
          displayText: suggestion.displayText,
          selectionOffset: suggestion.selectionOffset,
        );
      case ConstructorSuggestion():
        var completion = suggestion.completion;
        if (completion.isEmpty) {
          break;
        }
        suggestConstructor(
          suggestion.element,
          hasClassName: suggestion.hasClassName,
          completion: completion,
          kind: suggestion.kind,
          prefix: suggestion.prefix,
          suggestUnnamedAsNew: suggestion.suggestUnnamedAsNew,
          relevance: relevance,
        );
      case EnumSuggestion():
        suggestInterface(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case EnumConstantSuggestion():
        if (suggestion.includeEnumName) {
          suggestEnumConstant(
            suggestion.element,
            suggestion.completion,
            relevance: relevance,
          );
        } else {
          suggestField(
            suggestion.element,
            inheritanceDistance: 0.0,
            relevance: relevance,
          );
        }
      case ExtensionSuggestion():
        suggestExtension(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
          kind: suggestion.kind,
        );
      case ExtensionTypeSuggestion():
        suggestInterface(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case FieldSuggestion():
        var fieldElement = suggestion.element;
        if (fieldElement.isEnumConstant) {
          suggestEnumConstant(
            fieldElement,
            suggestion.completion,
            relevance: relevance,
          );
        } else {
          var inheritanceDistance = suggestion.inheritanceDistance(
            request.featureComputer,
          );
          suggestField(
            fieldElement,
            inheritanceDistance: inheritanceDistance,
            relevance: relevance,
          );
        }
      case FormalParameterSuggestion():
        suggestFormalParameter(
          element: suggestion.element,
          distance: suggestion.distance,
          relevance: relevance,
        );
      case FunctionCall():
        suggestFunctionCall();
      case GetterSuggestion():
        var inheritanceDistance = suggestion.inheritanceDistance(
          request.featureComputer,
        );
        suggestGetter(
          suggestion.element,
          inheritanceDistance: inheritanceDistance,
          relevance: relevance,
          completion: suggestion.completion,
        );
      case IdentifierSuggestion():
        suggestName(
          suggestion.completion,
          selectionOffset: suggestion.selectionOffset,
        );
      case ImportPrefixSuggestion():
        suggestPrefix(
          suggestion.libraryElement,
          suggestion.prefixElement.displayName,
          relevance: relevance,
        );
      case KeywordSuggestion():
        suggestKeyword(
          suggestion.completion,
          offset: suggestion.selectionOffset,
          relevance: relevance,
        );
      case LabelSuggestion():
        suggestLabel(suggestion.label);
      case LoadLibraryFunctionSuggestion():
        suggestLoadLibraryFunction(suggestion.element, kind: suggestion.kind);
      case LocalFunctionSuggestion():
        suggestLocalFunction(
          suggestion.element,
          relevance: relevance,
          kind: suggestion.kind,
        );
      case LocalVariableSuggestion():
        suggestLocalVariable(
          element: suggestion.element,
          distance: suggestion.distance,
          relevance: relevance,
        );
      case MethodSuggestion():
        // TODO(brianwilkerson): Correctly set the kind of suggestion in cases
        //  where `isFunctionalArgument` would return `true` so we can stop
        //  using the `request.target`.
        var kind =
            request.target.isFunctionalArgument()
                ? CompletionSuggestionKind.IDENTIFIER
                : suggestion.kind;
        var inheritanceDistance = suggestion.inheritanceDistance(
          request.featureComputer,
        );
        suggestMethod(
          suggestion.element,
          kind: kind,
          inheritanceDistance: inheritanceDistance,
          relevance: relevance,
        );
      case MixinSuggestion():
        suggestInterface(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case NamedArgumentSuggestion():
        suggestNamedArgument(
          suggestion.parameter,
          appendColon: suggestion.appendColon,
          appendComma: suggestion.appendComma,
          replacementLength: suggestion.replacementLength,
          completion: suggestion.completion,
          selectionOffset: suggestion.selectionOffset,
          relevance: relevance,
        );
      case NameSuggestion():
        suggestName(suggestion.name);
      case OverrideSuggestion():
        await suggestOverride(
          element: suggestion.element,
          invokeSuper: suggestion.shouldInvokeSuper,
          replacementRange: suggestion.replacementRange,
          skipAt: suggestion.skipAt,
        );
      case RecordFieldSuggestion():
        suggestRecordField(
          field: suggestion.field,
          name: suggestion.name,
          relevance: relevance,
        );
      case RecordLiteralNamedFieldSuggestion():
        suggestNamedRecordField(
          suggestion.field,
          appendColon: suggestion.appendColon,
          appendComma: suggestion.appendComma,
        );
      case SetStateMethodSuggestion():
        var inheritanceDistance = suggestion.inheritanceDistance(
          request.featureComputer,
        );
        suggestSetStateMethod(
          suggestion.element,
          kind: suggestion.kind,
          completion: suggestion.completion,
          displayText: suggestion.displayText,
          selectionOffset: suggestion.selectionOffset,
          inheritanceDistance: inheritanceDistance,
          relevance: relevance,
        );
      case SetterSuggestion():
        var inheritanceDistance = suggestion.inheritanceDistance(
          request.featureComputer,
        );
        suggestSetter(
          suggestion.element,
          inheritanceDistance: inheritanceDistance,
          relevance: relevance,
          completion: suggestion.completion,
        );
      case StaticFieldSuggestion():
        suggestStaticField(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
          completion: suggestion.completion,
        );
      case SuperParameterSuggestion():
        suggestSuperFormalParameter(suggestion.element);
      case TopLevelFunctionSuggestion():
        suggestTopLevelFunction(
          suggestion.element,
          kind: suggestion.kind,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case TopLevelGetterSuggestion():
        suggestTopLevelGetter(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case TopLevelSetterSuggestion():
        suggestTopLevelSetter(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case TopLevelVariableSuggestion():
        suggestTopLevelVariable(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case TypeAliasSuggestion():
        suggestTypeAlias(
          suggestion.element,
          prefix: suggestion.prefix,
          relevance: relevance,
        );
      case TypeParameterSuggestion():
        suggestTypeParameter(suggestion.element, relevance: relevance);
      case UriSuggestion():
        suggestUri(suggestion.uriStr);
    }
    isNotImportedLibrary = false;
    libraryUriStr = null;
    requiredImports = [];
  }

  /// Add a suggestion for each of the candidate [suggestions].
  Future<void> suggestFromCandidates(
    List<CandidateSuggestion> suggestions,
    bool preferConstants,
    String? completionLocation,
  ) async {
    relevanceComputer.preferConstants =
        preferConstants || request.inConstantContext;
    relevanceComputer.completionLocation = completionLocation;
    for (var suggestion in suggestions) {
      await suggestFromCandidate(suggestion);
    }
  }
}

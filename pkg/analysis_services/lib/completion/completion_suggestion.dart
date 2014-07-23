// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion;

import 'package:analysis_services/json.dart';
import 'package:analysis_services/constants.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A single completion suggestion.
 */
class CompletionSuggestion implements HasToJson {
  final CompletionSuggestionKind kind;
  final CompletionRelevance relevance;
  final String completion;
  final int selectionOffset;
  final int selectionLength;
  final bool isDeprecated;
  final bool isPotential;

  CompletionSuggestion(this.kind, this.relevance, this.completion,
      this.selectionOffset, this.selectionLength, this.isDeprecated,
      this.isPotential);

  factory CompletionSuggestion.fromJson(Map<String, Object> json) {
    return new CompletionSuggestion(
        CompletionSuggestionKind.valueOf(json[KIND]),
        CompletionRelevance.value(json[RELEVANCE]),
        json[COMPLETION],
        json[SELECTION_OFFSET],
        json[SELECTION_LENGTH],
        json[IS_DEPRECATED],
        json[IS_POTENTIAL]);
  }

  @override
  Map<String, Object> toJson() {
    return {
      KIND: kind.name,
      RELEVANCE: relevance.name,
      COMPLETION: completion,
      SELECTION_OFFSET: selectionOffset,
      SELECTION_LENGTH: selectionLength,
      IS_DEPRECATED: isDeprecated,
      IS_POTENTIAL: isPotential
    };
  }
}

/**
 * An enumeration of the kinds of elements that can be included
 * in a completion suggestion.
 */
class CompletionSuggestionKind {
  static const CompletionSuggestionKind CLASS =
      const CompletionSuggestionKind('CLASS');
  static const CompletionSuggestionKind CLASS_ALIAS =
      const CompletionSuggestionKind('CLASS_ALIAS');
  static const CompletionSuggestionKind CONSTRUCTOR =
      const CompletionSuggestionKind('CONSTRUCTOR');
  static const CompletionSuggestionKind FIELD =
      const CompletionSuggestionKind('FIELD');
  static const CompletionSuggestionKind FUNCTION =
      const CompletionSuggestionKind('FUNCTION');
  static const CompletionSuggestionKind FUNCTION_ALIAS =
      const CompletionSuggestionKind('FUNCTION_ALIAS');
  static const CompletionSuggestionKind GETTER =
      const CompletionSuggestionKind('GETTER');
  static const CompletionSuggestionKind IMPORT =
      const CompletionSuggestionKind('IMPORT');
  static const CompletionSuggestionKind LIBRARY_PREFIX =
      const CompletionSuggestionKind('LIBRARY_PREFIX');
  static const CompletionSuggestionKind METHOD =
      const CompletionSuggestionKind('METHOD');
  static const CompletionSuggestionKind METHOD_NAME =
      const CompletionSuggestionKind('METHOD_NAME');
  static const CompletionSuggestionKind PARAMETER =
      const CompletionSuggestionKind('PARAMETER');
  static const CompletionSuggestionKind SETTER =
      const CompletionSuggestionKind('SETTER');
  static const CompletionSuggestionKind VARIABLE =
      const CompletionSuggestionKind('VARIABLE');
  static const CompletionSuggestionKind TYPE_PARAMETER =
      const CompletionSuggestionKind('TYPE_PARAMETER');
  static const CompletionSuggestionKind ARGUMENT_LIST =
      const CompletionSuggestionKind('ARGUMENT_LIST');
  static const CompletionSuggestionKind OPTIONAL_ARGUMENT =
      const CompletionSuggestionKind('OPTIONAL_ARGUMENT');
  static const CompletionSuggestionKind NAMED_ARGUMENT =
      const CompletionSuggestionKind('NAMED_ARGUMENT');
  static const CompletionSuggestionKind TOP_LEVEL_VARIABLE =
      const CompletionSuggestionKind('TOP_LEVEL_VARIABLE');

  final String name;

  const CompletionSuggestionKind(this.name);

  @override
  String toString() => name;

  static CompletionSuggestionKind valueOf(String name) {
    if (CLASS.name == name) return CLASS;
    if (CLASS_ALIAS.name == name) return CLASS_ALIAS;
    if (CONSTRUCTOR.name == name) return CONSTRUCTOR;
    if (FIELD.name == name) return FIELD;
    if (FUNCTION.name == name) return FUNCTION;
    if (FUNCTION_ALIAS.name == name) return FUNCTION_ALIAS;
    if (GETTER.name == name) return GETTER;
    if (IMPORT.name == name) return IMPORT;
    if (LIBRARY_PREFIX.name == name) return LIBRARY_PREFIX;
    if (METHOD.name == name) return METHOD;
    if (METHOD_NAME.name == name) return METHOD_NAME;
    if (PARAMETER.name == name) return PARAMETER;
    if (SETTER.name == name) return SETTER;
    if (VARIABLE.name == name) return VARIABLE;
    if (TYPE_PARAMETER.name == name) return TYPE_PARAMETER;
    if (ARGUMENT_LIST.name == name) return ARGUMENT_LIST;
    if (OPTIONAL_ARGUMENT.name == name) return OPTIONAL_ARGUMENT;
    if (NAMED_ARGUMENT.name == name) return NAMED_ARGUMENT;
    if (TOP_LEVEL_VARIABLE.name == name) return TOP_LEVEL_VARIABLE;
    throw new ArgumentError('Unknown CompletionSuggestionKind: $name');
  }

  static CompletionSuggestionKind fromElementKind(ElementKind kind) {
    //    ElementKind.ANGULAR_FORMATTER,
    //    ElementKind.ANGULAR_COMPONENT,
    //    ElementKind.ANGULAR_CONTROLLER,
    //    ElementKind.ANGULAR_DIRECTIVE,
    //    ElementKind.ANGULAR_PROPERTY,
    //    ElementKind.ANGULAR_SCOPE_PROPERTY,
    //    ElementKind.ANGULAR_SELECTOR,
    //    ElementKind.ANGULAR_VIEW,
    if (kind == ElementKind.CLASS) return CLASS;
    //    ElementKind.COMPILATION_UNIT,
    if (kind == ElementKind.CONSTRUCTOR) return CONSTRUCTOR;
    //    ElementKind.DYNAMIC,
    //    ElementKind.EMBEDDED_HTML_SCRIPT,
    //    ElementKind.ERROR,
    //    ElementKind.EXPORT,
    //    ElementKind.EXTERNAL_HTML_SCRIPT,
    if (kind == ElementKind.FIELD) return FIELD;
    if (kind == ElementKind.FUNCTION) return FUNCTION;
    if (kind == ElementKind.GETTER) return GETTER;
    //    ElementKind.HTML,
    if (kind == ElementKind.IMPORT) return IMPORT;
    //    ElementKind.LABEL,
    //    ElementKind.LIBRARY,
    //    ElementKind.LOCAL_VARIABLE,
    if (kind == ElementKind.METHOD) return METHOD;
    //    ElementKind.METHOD,
    //    ElementKind.NAME,
    if (kind == ElementKind.PARAMETER) return PARAMETER;
    //    ElementKind.POLYMER_ATTRIBUTE,
    //    ElementKind.POLYMER_TAG_DART,
    //    ElementKind.POLYMER_TAG_HTML,
    //    ElementKind.PREFIX,
    if (kind == ElementKind.SETTER) return SETTER;
    if (kind == ElementKind.TOP_LEVEL_VARIABLE) return TOP_LEVEL_VARIABLE;
    //    ElementKind.FUNCTION_TYPE_ALIAS,
    //    ElementKind.TYPE_PARAMETER,
    //    ElementKind.UNIVERSE
    throw new ArgumentError('Unknown CompletionSuggestionKind for: $kind');
  }
}

/**
 * An enumeration of the relevance of a completion suggestion.
 */
class CompletionRelevance {
  static const CompletionRelevance LOW = const CompletionRelevance('LOW');
  static const CompletionRelevance DEFAULT =
      const CompletionRelevance('DEFAULT');
  static const CompletionRelevance HIGH = const CompletionRelevance('HIGH');

  final String name;

  const CompletionRelevance(this.name);

  static CompletionRelevance value(String name) {
    if (LOW.name == name) return LOW;
    if (DEFAULT.name == name) return DEFAULT;
    if (HIGH.name == name) return HIGH;
    throw new ArgumentError('Unknown CompletionRelevance: $name');
  }
}

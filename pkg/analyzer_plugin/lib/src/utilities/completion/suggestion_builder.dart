// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/documentation.dart';
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:analyzer_plugin/utilities/completion/suggestion_builder.dart';

/// An object used to build code completion suggestions for Dart code.
class SuggestionBuilderImpl implements SuggestionBuilder {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The converter used to convert analyzer objects to protocol objects.
  final AnalyzerConverter converter = AnalyzerConverter();

  /// Initialize a newly created suggestion builder.
  SuggestionBuilderImpl(this.resourceProvider);

  /// Add default argument list text and ranges based on the given
  /// [requiredParams] and [namedParams].
  void addDefaultArgDetails(
      CompletionSuggestion suggestion,
      Element element,
      Iterable<ParameterElement> requiredParams,
      Iterable<ParameterElement> namedParams) {
    // Copied from analysis_server/lib/src/services/completion/dart/suggestion_builder.dart
    var buffer = StringBuffer();
    var ranges = <int>[];

    int offset;

    for (var param in requiredParams) {
      if (buffer.isNotEmpty) {
        buffer.write(', ');
      }
      offset = buffer.length;
      var name = param.name;
      buffer.write(name);
      ranges.addAll([offset, name.length]);
    }

    for (var param in namedParams) {
      if (param.hasRequired || param.isRequiredNamed) {
        if (buffer.isNotEmpty) {
          buffer.write(', ');
        }
        var name = param.name;
        buffer.write('$name: ');
        offset = buffer.length;
        buffer.write(name);
        ranges.addAll([offset, name.length]);
      }
    }

    suggestion.defaultArgumentListString =
        buffer.isNotEmpty ? buffer.toString() : null;
    suggestion.defaultArgumentListTextRanges =
        ranges.isNotEmpty ? ranges : null;
  }

  @override
  CompletionSuggestion forElement(Element element,
      {String completion,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      int relevance = DART_RELEVANCE_DEFAULT}) {
    // Copied from analysis_server/lib/src/services/completion/dart/suggestion_builder.dart
    if (element == null) {
      return null;
    }
    if (element is ExecutableElement && element.isOperator) {
      // Do not include operators in suggestions
      return null;
    }
    completion ??= element.displayName;
    var isDeprecated = element.hasDeprecated;
    var suggestion = CompletionSuggestion(
        kind,
        isDeprecated ? DART_RELEVANCE_LOW : relevance,
        completion,
        completion.length,
        0,
        isDeprecated,
        false);

    // Attach docs.
    var doc = removeDartDocDelimiters(element.documentationComment);
    suggestion.docComplete = doc;
    suggestion.docSummary = getDartDocSummary(doc);

    suggestion.element = converter.convertElement(element);
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      suggestion.declaringType = enclosingElement.displayName;
    }
    suggestion.returnType = getReturnTypeString(element);
    if (element is ExecutableElement && element is! PropertyAccessorElement) {
      suggestion.parameterNames = element.parameters
          .map((ParameterElement parameter) => parameter.name)
          .toList();
      suggestion.parameterTypes =
          element.parameters.map((ParameterElement parameter) {
        var paramType = parameter.type;
        // Gracefully degrade if type not resolved yet
        return paramType != null
            ? paramType.getDisplayString(withNullability: false)
            : 'var';
      }).toList();

      var requiredParameters = element.parameters
          .where((ParameterElement param) => param.isRequiredPositional);
      suggestion.requiredParameterCount = requiredParameters.length;

      var namedParameters =
          element.parameters.where((ParameterElement param) => param.isNamed);
      suggestion.hasNamedParameters = namedParameters.isNotEmpty;

      addDefaultArgDetails(
          suggestion, element, requiredParameters, namedParameters);
    }
    return suggestion;
  }

  String getReturnTypeString(Element element) {
    // Copied from analysis_server/lib/src/protocol_server.dart
    if (element is ExecutableElement) {
      if (element.kind == ElementKind.SETTER) {
        return null;
      } else {
        return element.returnType?.getDisplayString(withNullability: false);
      }
    } else if (element is VariableElement) {
      var type = element.type;
      return type != null
          ? type.getDisplayString(withNullability: false)
          : 'dynamic';
    } else if (element is TypeAliasElement) {
      var aliasedElement = element.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        var returnType = aliasedElement.returnType;
        return returnType.getDisplayString(withNullability: false);
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}

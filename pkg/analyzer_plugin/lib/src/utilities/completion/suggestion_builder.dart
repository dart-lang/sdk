// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/documentation.dart';
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:analyzer_plugin/utilities/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/source.dart' show Source, UriKind;

/**
 * An object used to build code completion suggestions for Dart code.
 */
class SuggestionBuilderImpl implements SuggestionBuilder {
  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * The converter used to convert analyzer objects to protocol objects.
   */
  final AnalyzerConverter converter = new AnalyzerConverter();

  /**
   * Initialize a newly created suggestion builder.
   */
  SuggestionBuilderImpl(this.resourceProvider);

  /**
   * Add default argument list text and ranges based on the given [requiredParams]
   * and [namedParams].
   */
  void addDefaultArgDetails(
      CompletionSuggestion suggestion,
      Element element,
      Iterable<ParameterElement> requiredParams,
      Iterable<ParameterElement> namedParams) {
    // Copied from analysis_server/lib/src/services/completion/dart/suggestion_builder.dart
    StringBuffer buffer = new StringBuffer();
    List<int> ranges = <int>[];

    int offset;

    for (ParameterElement param in requiredParams) {
      if (buffer.isNotEmpty) {
        buffer.write(', ');
      }
      offset = buffer.length;
      String name = param.name;
      buffer.write(name);
      ranges.addAll([offset, name.length]);
    }

    for (ParameterElement param in namedParams) {
      if (param.isRequired) {
        if (buffer.isNotEmpty) {
          buffer.write(', ');
        }
        String name = param.name;
        buffer.write('$name: ');
        offset = buffer.length;
        String defaultValue = 'null'; // originally _getDefaultValue(param)
        buffer.write(defaultValue);
        ranges.addAll([offset, defaultValue.length]);
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
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT,
      Source importForSource}) {
    // Copied from analysis_server/lib/src/services/completion/dart/suggestion_builder.dart
    if (element == null) {
      return null;
    }
    if (element is ExecutableElement && element.isOperator) {
      // Do not include operators in suggestions
      return null;
    }
    if (completion == null) {
      completion = element.displayName;
    }
    bool isDeprecated = element.isDeprecated;
    CompletionSuggestion suggestion = new CompletionSuggestion(
        kind,
        isDeprecated ? DART_RELEVANCE_LOW : relevance,
        completion,
        completion.length,
        0,
        isDeprecated,
        false);

    // Attach docs.
    String doc = removeDartDocDelimiters(element.documentationComment);
    suggestion.docComplete = doc;
    suggestion.docSummary = getDartDocSummary(doc);

    suggestion.element = converter.convertElement(element);
    Element enclosingElement = element.enclosingElement;
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
        DartType paramType = parameter.type;
        // Gracefully degrade if type not resolved yet
        return paramType != null ? paramType.displayName : 'var';
      }).toList();

      Iterable<ParameterElement> requiredParameters = element.parameters.where(
          (ParameterElement param) =>
              param.parameterKind == ParameterKind.REQUIRED);
      suggestion.requiredParameterCount = requiredParameters.length;

      Iterable<ParameterElement> namedParameters = element.parameters.where(
          (ParameterElement param) =>
              param.parameterKind == ParameterKind.NAMED);
      suggestion.hasNamedParameters = namedParameters.isNotEmpty;

      addDefaultArgDetails(
          suggestion, element, requiredParameters, namedParameters);
    }
    if (importForSource != null) {
      String srcPath =
          resourceProvider.pathContext.dirname(importForSource.fullName);
      LibraryElement libElem = element.library;
      if (libElem != null) {
        Source libSource = libElem.source;
        if (libSource != null) {
          UriKind uriKind = libSource.uriKind;
          if (uriKind == UriKind.DART_URI) {
            suggestion.importUri = libSource.uri.toString();
          } else if (uriKind == UriKind.PACKAGE_URI) {
            suggestion.importUri = libSource.uri.toString();
          } else if (uriKind == UriKind.FILE_URI &&
              element.source.uriKind == UriKind.FILE_URI) {
            try {
              suggestion.importUri = resourceProvider.pathContext
                  .relative(libSource.fullName, from: srcPath);
            } catch (_) {
              // ignored
            }
          }
        }
      }
      if (suggestion.importUri == null) {
        // Do not include out of scope suggestions
        // for which we cannot determine an import
        return null;
      }
    }
    return suggestion;
  }

  String getReturnTypeString(Element element) {
    // Copied from analysis_server/lib/src/protocol_server.dart
    if (element is ExecutableElement) {
      if (element.kind == ElementKind.SETTER) {
        return null;
      } else {
        return element.returnType?.toString();
      }
    } else if (element is VariableElement) {
      DartType type = element.type;
      return type != null ? type.displayName : 'dynamic';
    } else if (element is FunctionTypeAliasElement) {
      return element.returnType.toString();
    } else {
      return null;
    }
  }
}

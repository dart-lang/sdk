// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion;
import 'package:analyzer/dart/element/element.dart';

/// An extension of [CompletionSuggestion] that includes additional
/// Dart-specific fields that are not part of the JSON protocol.
class DartCompletionSuggestion extends CompletionSuggestion {
  final ElementLocation? elementLocation;
  final List<Uri> requiredImports;
  final String? colorHex;

  DartCompletionSuggestion(
    super.kind,
    super.relevance,
    super.completion,
    super.selectionOffset,
    super.selectionLength,
    super.isDeprecated,
    super.isPotential, {
    super.displayText,
    super.replacementOffset,
    super.replacementLength,
    super.docSummary,
    super.docComplete,
    super.declaringType,
    super.defaultArgumentListString,
    super.defaultArgumentListTextRanges,
    super.element,
    super.returnType,
    super.parameterNames,
    super.parameterTypes,
    super.requiredParameterCount,
    super.hasNamedParameters,
    super.parameterName,
    super.parameterType,
    super.libraryUri,
    super.isNotImported,
    required this.elementLocation,
    this.requiredImports = const [],
    this.colorHex,
  });
}

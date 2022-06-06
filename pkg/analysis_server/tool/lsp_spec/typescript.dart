// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'typescript_parser.dart';

/// Improves types in generated code, including:
///
/// - Fixes up some enum types that are not as specific as they could be in the
///   spec. For example, Diagnostic.severity is typed "number" but can be mapped
///   to the DiagnosticSeverity enum class.
///
/// - Narrows unions to single types where they're only generated on the server
///   and we know we always use a specific type. This avoids wrapping a lot
///   of code in `EitherX<Y,Z>.tX()` and simplifies the testing of them.
TypeBase? getImprovedType(String interfaceName, String? fieldName) {
  const improvedTypeMappings = <String, Map<String, String>>{
    'Diagnostic': {
      'severity': 'DiagnosticSeverity',
      'code': 'String',
      'data': 'object',
    },
    'TextDocumentSyncOptions': {
      'change': 'TextDocumentSyncKind',
    },
    'TextDocumentChangeRegistrationOptions': {
      'syncKind': 'TextDocumentSyncKind',
    },
    'FileSystemWatcher': {
      'kind': 'WatchKind',
    },
    'CompletionItem': {
      'kind': 'CompletionItemKind',
      'data': 'CompletionItemResolutionInfo',
    },
    'CallHierarchyItem': {
      'data': 'object',
    },
    'DocumentHighlight': {
      'kind': 'DocumentHighlightKind',
    },
    'FoldingRange': {
      'kind': 'FoldingRangeKind',
    },
    'SymbolInformation': {
      'kind': 'SymbolKind',
    },
    'ParameterInformation': {
      'label': 'String',
    },
    'ProgressParams': {
      'value': 'object',
    },
    'ServerCapabilities': {
      'changeNotifications': 'bool',
    },
    'TextDocumentEdit': {
      'edits': 'TextDocumentEditEdits',
    }
  };

  final interface = improvedTypeMappings[interfaceName];

  final improvedTypeName = interface != null ? interface[fieldName] : null;

  return improvedTypeName != null
      ? improvedTypeName.endsWith('[]')
          ? ArrayType(Type.identifier(
              improvedTypeName.substring(0, improvedTypeName.length - 2)))
          : improvedTypeName.endsWith('?')
              ? UnionType.nullable(Type.identifier(
                  improvedTypeName.substring(0, improvedTypeName.length - 1)))
              : Type.identifier(improvedTypeName)
      : null;
}

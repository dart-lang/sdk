// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'typescript_parser.dart';

/// Removes types that are in the spec that we don't want in other signatures.
bool allowTypeInSignatures(TypeBase type) {
  // Don't allow arrays of MarkedStrings, but do allow simple MarkedStrings.
  // The only place that uses these are Hovers and we only send one value
  // (to match the MarkupString equiv) so the array just makes the types
  // unnecessarily complicated.
  if (type is ArrayType) {
    final elementType = type.elementType;
    if (elementType is Type && elementType.name == 'MarkedString') {
      return false;
    }
  }
  return true;
}

String cleanComment(String comment) {
  // Remove the start/end comment markers.
  if (comment.startsWith('/**') && comment.endsWith('*/')) {
    comment = comment.substring(3, comment.length - 2);
  } else if (comment.startsWith('//')) {
    comment = comment.substring(2);
  }

  final commentLinePrefixes = RegExp(r'\n\s*\* ?');
  final nonConcurrentNewlines = RegExp(r'\n(?![\n\s\-*])');
  final newLinesThatRequireReinserting = RegExp(r'\n (\w)');
  // Remove any Windows newlines from the source.
  comment = comment.replaceAll('\r', '');
  // Remove the * prefixes.
  comment = comment.replaceAll(commentLinePrefixes, '\n');
  // Remove and newlines that look like wrapped text.
  comment = comment.replaceAll(nonConcurrentNewlines, ' ');
  // The above will remove one of the newlines when there are two, so we need
  // to re-insert newlines for any block that starts immediately after a newline.
  comment = comment.replaceAllMapped(
      newLinesThatRequireReinserting, (m) => '\n\n${m.group(1)}');
  return comment.trim();
}

/// Improves types in generated code, including:
///
/// - Fixes up some enum types that are not as specific as they could be in the
///   spec. For example, Diagnostic.severity is typed "number" but can be mapped
///   to the DiagnosticSeverity enum class.
///
/// - Narrows unions to single types where they're only generated on the server
///   and we know we always use a specific type. This avoids wrapping a lot
///   of code in `EitherX<Y,Z>.tX()` and simplifies the testing of them.
String? getImprovedType(String interfaceName, String? fieldName) {
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

  return interface != null ? interface[fieldName] : null;
}

/// Removes types that are in the spec that we don't want to emit.
bool includeTypeDefinitionInOutput(AstNode node) {
  const ignoredTypes = {
    // InitializeError is not used for v3.0 (Feb 2017) and by dropping it we don't
    // have to handle any cases where both a namespace and interfaces are declared
    // with the same name.
    'InitializeError',
    // We don't use `InitializeErrorCodes` as it contains only one error code
    // that has been deprecated and we've never used.
    'InitializeErrorCodes',
    // Handled in custom classes now in preperation for JSON meta model which
    // does not specify them.
    'Message',
    'RequestMessage',
    'NotificationMessage',
    'ResponseMessage',
    'ResponseError',
  };
  const ignoredPrefixes = {
    // We don't emit MarkedString because it gets mapped to a simple String
    // when getting the .dartType for it.
    'MarkedString'
  };
  final shouldIgnore = ignoredTypes.contains(node.name) ||
      ignoredPrefixes.any((ignore) => node.name.startsWith(ignore));
  return !shouldIgnore;
}

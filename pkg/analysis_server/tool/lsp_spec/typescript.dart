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
  if (comment == null) {
    return null;
  }

  // Remove the start/end comment markers.
  if (comment.startsWith('/**') && comment.endsWith('*/')) {
    comment = comment.substring(3, comment.length - 2);
  } else if (comment.startsWith('//')) {
    comment = comment.substring(2);
  }

  final _commentLinePrefixes = RegExp(r'\n\s*\* ?');
  final _nonConcurrentNewlines = RegExp(r'\n(?![\n\s\-*])');
  final _newLinesThatRequireReinserting = RegExp(r'\n (\w)');
  // Remove any Windows newlines from the source.
  comment = comment.replaceAll('\r', '');
  // Remove the * prefixes.
  comment = comment.replaceAll(_commentLinePrefixes, '\n');
  // Remove and newlines that look like wrapped text.
  comment = comment.replaceAll(_nonConcurrentNewlines, ' ');
  // The above will remove one of the newlines when there are two, so we need
  // to re-insert newlines for any block that starts immediately after a newline.
  comment = comment.replaceAllMapped(
      _newLinesThatRequireReinserting, (m) => '\n\n${m.group(1)}');
  return comment.trim();
}

/// Improves comments in generated code to support where types may have been
/// altered (for ex. with [getImprovedType] above).
String getImprovedComment(String interfaceName, String fieldName) {
  const _improvedComments = <String, Map<String, String>>{
    'ResponseError': {
      'data':
          '// A string that contains additional information about the error. Can be omitted.',
    },
  };

  final interface = _improvedComments[interfaceName];

  return interface != null ? interface[fieldName] : null;
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
String getImprovedType(String interfaceName, String fieldName) {
  const _improvedTypeMappings = <String, Map<String, String>>{
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
      'textEdit': 'TextEdit',
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
    'ResponseError': {
      'code': 'ErrorCodes',
      // This is dynamic normally, but since this class can be serialised
      // we will crash if it data is set to something that can't be converted to
      // JSON (for ex. Uri) so this forces anyone setting this to convert to a
      // String.
      'data': 'String',
    },
    'NotificationMessage': {
      'method': 'Method',
      'params': 'object',
    },
    'RequestMessage': {
      'method': 'Method',
      'params': 'object',
    },
    'SymbolInformation': {
      'kind': 'SymbolKind',
    },
    'ParameterInformation': {
      'label': 'String',
    },
    'ServerCapabilities': {
      'changeNotifications': 'bool',
    }
  };

  final interface = _improvedTypeMappings[interfaceName];

  return interface != null ? interface[fieldName] : null;
}

List<String> getSpecialBaseTypes(Interface interface) {
  if (interface.name == 'RequestMessage' ||
      interface.name == 'NotificationMessage') {
    return ['IncomingMessage'];
  } else {
    return [];
  }
}

/// Removes types that are in the spec that we don't want to emit.
bool includeTypeDefinitionInOutput(AstNode node) {
  // These types are not used for v3.0 (Feb 2017) and by dropping them we don't
  // have to handle any cases where both a namespace and interfaces are declared
  // with the same name.
  return node.name != 'InitializeError' &&
      // We don't emit MarkedString because it gets mapped to a simple String
      // when getting the .dartType for it.
      // .startsWith() because there are inline types that will be generated.
      !node.name.startsWith('MarkedString');
}

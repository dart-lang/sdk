// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/session_logger/entry_keys.dart' as key;
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer_plugin/protocol/protocol_common.dart' show ElementKind;
import 'package:meta/meta.dart';

/// A shorthand for the type of a map produced by the JSON decoder.
typedef JsonMap = Map<String, Object?>;

/// An identifier kind used during log sanitization to classify Dart symbols.
@visibleForTesting
enum IdentifierKind {
  typeDeclaration(
    elementKinds: [
      ElementKind.CLASS,
      ElementKind.CLASS_TYPE_ALIAS,
      ElementKind.ENUM,
      ElementKind.EXTENSION,
      ElementKind.EXTENSION_TYPE,
      ElementKind.MIXIN,
      ElementKind.TYPE_ALIAS,
      ElementKind.TYPE_PARAMETER,
    ],
    symbolKinds: [
      lsp.SymbolKind.Class,
      lsp.SymbolKind.Enum,
      lsp.SymbolKind.Interface,
      lsp.SymbolKind.Struct,
      lsp.SymbolKind.TypeParameter,
    ],
    completionItemKinds: [
      lsp.CompletionItemKind.Class,
      lsp.CompletionItemKind.Enum,
      lsp.CompletionItemKind.Interface,
      lsp.CompletionItemKind.Struct,
      lsp.CompletionItemKind.TypeParameter,
    ],
    prefix: 'C',
  ),
  method(
    elementKinds: [
      ElementKind.CONSTRUCTOR,
      ElementKind.FUNCTION,
      ElementKind.METHOD,
      ElementKind.UNIT_TEST_GROUP,
      ElementKind.UNIT_TEST_TEST,
    ],
    symbolKinds: [
      lsp.SymbolKind.Constructor,
      lsp.SymbolKind.Function,
      lsp.SymbolKind.Method,
    ],
    completionItemKinds: [
      lsp.CompletionItemKind.Constructor,
      lsp.CompletionItemKind.Function,
      lsp.CompletionItemKind.Method,
    ],
    prefix: 'm',
  ),
  variable(
    elementKinds: [
      ElementKind.ENUM_CONSTANT,
      ElementKind.FIELD,
      ElementKind.GETTER,
      ElementKind.LOCAL_VARIABLE,
      ElementKind.PARAMETER,
      ElementKind.SETTER,
      ElementKind.TOP_LEVEL_VARIABLE,
    ],
    symbolKinds: [
      lsp.SymbolKind.Constant,
      lsp.SymbolKind.EnumMember,
      lsp.SymbolKind.Field,
      lsp.SymbolKind.Property,
      lsp.SymbolKind.Variable,
    ],
    completionItemKinds: [
      lsp.CompletionItemKind.Constant,
      lsp.CompletionItemKind.EnumMember,
      lsp.CompletionItemKind.Field,
      lsp.CompletionItemKind.Property,
      lsp.CompletionItemKind.Variable,
    ],
    prefix: 'v',
  ),
  unknown(
    elementKinds: [],
    symbolKinds: [],
    completionItemKinds: [],
    prefix: 'a',
  );

  static final Map<String, IdentifierKind> _byElementKindName = {
    for (var value in values)
      for (var kind in value.elementKinds) kind.name.toUpperCase(): value,
  };

  static final Map<lsp.SymbolKind, IdentifierKind> _bySymbolKind = {
    for (var value in values)
      for (var kind in value.symbolKinds) kind: value,
  };

  static final Map<lsp.CompletionItemKind, IdentifierKind>
  _byCompletionItemKind = {
    for (var value in values)
      for (var kind in value.completionItemKinds) kind: value,
  };

  /// The DAS protocol element kinds that map to this [IdentifierKind].
  final List<ElementKind> elementKinds;

  /// The LSP symbol kinds that map to this [IdentifierKind].
  final List<lsp.SymbolKind> symbolKinds;

  /// The LSP completion item kinds that map to this [IdentifierKind].
  final List<lsp.CompletionItemKind> completionItemKinds;

  /// The prefix character used in sanitized identifiers of this kind.
  final String prefix;

  /// Creates a new identifier kind with the given [elementKinds],
  /// [symbolKinds], and [completionItemKinds].
  new({
    required this.elementKinds,
    required this.symbolKinds,
    required this.completionItemKinds,
    required this.prefix,
  });

  /// Returns the [IdentifierKind] associated with [kind], or [unknown] if none
  /// match.
  factory forKind(String? kind) {
    if (kind == null) return unknown;
    return _byElementKindName[kind.toUpperCase()] ?? unknown;
  }

  /// Returns the [IdentifierKind] for the given LSP [completionItemKind], or
  /// [unknown] if none match.
  factory forLspCompletionItemKind(Object? completionItemKind) {
    return switch (completionItemKind) {
      lsp.CompletionItemKind() =>
        _byCompletionItemKind[completionItemKind] ?? unknown,
      int() =>
        _byCompletionItemKind[lsp.CompletionItemKind.fromJson(
              completionItemKind,
            )] ??
            unknown,
      _ => unknown,
    };
  }

  /// Returns the [IdentifierKind] for the given LSP [symbolKind], or
  /// [unknown] if none match.
  factory forLspSymbolKind(Object? symbolKind) {
    return switch (symbolKind) {
      lsp.SymbolKind() => _bySymbolKind[symbolKind] ?? unknown,
      int() => _bySymbolKind[lsp.SymbolKind.fromJson(symbolKind)] ?? unknown,
      _ => unknown,
    };
  }
}

/// A utility for sanitizing and scrubbing sensitive data (such as file paths,
/// Dart code identifier names, and source contents) in session logs.
class LogSanitizer {
  /// The header indicator added as the first entry to a sanitized log.
  @visibleForTesting
  static const JsonMap sanitizedIndicator = {
    'comment': 'This session log has been sanitized.',
  };

  /// Set of file extensions that are preserved during path sanitization.
  ///
  /// All other file extensions are discarded to avoid leaking potentially
  /// confidential file types.
  static const Set<String> _preservedFileExtensions = {'.dart', '.yaml'};

  /// Set of core SDK types that should not be sanitized.
  static const Set<String> _coreSdkTypes = {
    'bool',
    'DateTime',
    'double',
    'Duration',
    'Error',
    'Exception',
    'Future',
    'int',
    'Iterable',
    'Iterator',
    'List',
    'Map',
    'Never',
    'Null',
    'num',
    'Object',
    'Record',
    'RegExp',
    'Set',
    'StackTrace',
    'Stream',
    'String',
    'StringBuffer',
    'Symbol',
    'Type',
    'Uri',
  };

  static final _drivePattern = RegExp(r'^([a-zA-Z]:)([/\\]?)');

  static final _leadingSlashPattern = RegExp(r'^[/\\]+');
  static final _pathSeparatorPattern = RegExp(r'[/\\]');
  static final _identifierPattern = RegExp(r'\b[a-zA-Z_$][a-zA-Z0-9_$]*\b');
  static final _nonAlphanumericPattern = RegExp(r'^[^a-zA-Z0-9]+$');
  static final _whitespacePattern = RegExp(r'\s');
  static final _quotedIdentifierPattern = RegExp(
    r"(['`])([a-zA-Z_$][a-zA-Z0-9_$]*)(['`])",
  );
  static final _pathsInTextPattern = RegExp(
    r'(file:///[^\s",:]+|[a-zA-Z]:[/\\][^\s",:]+|/[a-zA-Z0-9_.-]+/[^\s",:]+)',
  );

  /// A map from original path segment to sanitized name.
  final Map<String, String> _pathSegments = {};

  /// Next integer ID for path segments.
  int _nextPathId = 0;

  /// A map from original identifier name to sanitized name.
  final Map<String, String> _identifiers = {};

  /// Next integer ID for classes/types.
  int _nextClassId = 1;

  /// Next integer ID for methods/functions.
  int _nextMethodId = 1;

  /// Next integer ID for variables/fields/parameters.
  int _nextVariableId = 1;

  /// Next integer ID for unclassified or general identifiers (used as a
  /// fallback when an identifier cannot be classified as a class ('C'),
  /// method ('m'), or variable/field ('v')).
  int _nextIdentifierId = 1;

  /// Mapping from request ID to request method name.
  final Map<Object, String> _requestMethods = {};

  /// Sanitizes a list of log [entries].
  ///
  /// Adds an initial indicator entry explaining that the log has been
  /// sanitized.
  List<JsonMap> sanitize(Iterable<Object?> entries) {
    return [
      {...sanitizedIndicator},
      for (var entry in entries)
        if (entry is LogEntry)
          sanitizeEntry(entry.map)
        else if (entry is JsonMap)
          sanitizeEntry(entry),
    ];
  }

  /// Sanitizes a single log [entry].
  JsonMap sanitizeEntry(JsonMap entry) {
    var sanitizedEntry = Map.of(entry);
    var kind = sanitizedEntry[key.kind] as String?;

    if (kind == EntryKind.commandLine.name) {
      sanitizedEntry.updateIfType<List<Object?>>(key.argList, (argList) {
        return [
          for (var arg in argList)
            arg is String ? _sanitizeCommandLineArg(arg) : arg,
        ];
      });
    } else if (kind == EntryKind.message.name) {
      sanitizedEntry.updateIfType(key.message, sanitizeMessage);
    } else if (kind == EntryKind.exception.name) {
      sanitizedEntry.updateIfType(key.message, _sanitizePathsInText);
      sanitizedEntry.updateIfType(key.stackTrace, _sanitizePathsInText);
    } else if (kind == EntryKind.info.name) {
      sanitizedEntry.updateIfType(key.message, _sanitizePathsInText);
    }

    return sanitizedEntry;
  }

  /// Sanitizes a Dart code identifier [name] while keeping replacements
  /// consistent.
  String sanitizeIdentifier(
    String name, {
    IdentifierKind kind = IdentifierKind.unknown,
  }) {
    if (name.isEmpty) return name;

    // Do not sanitize Dart keywords or core SDK types.
    if (name.isDartKeyword || _coreSdkTypes.contains(name)) return name;

    // If identifier was already mapped, return the mapped name.
    if (_identifiers[name] case var mapped?) return mapped;

    // Handle compound identifiers like 'Foo.bar' or 'Foo.baz'.
    if (name.contains('.')) {
      var parts = name.split('.');
      var sanitizedParts = <String>[];
      for (var i = 0; i < parts.length; i++) {
        var part = parts[i];
        if (part.isEmpty) {
          sanitizedParts.add('');
        } else if (i == 0) {
          sanitizedParts.add(
            sanitizeIdentifier(part, kind: IdentifierKind.typeDeclaration),
          );
        } else {
          sanitizedParts.add(
            sanitizeIdentifier(part, kind: IdentifierKind.method),
          );
        }
      }
      return _identifiers[name] = sanitizedParts.join('.');
    }

    var id = switch (kind) {
      IdentifierKind.typeDeclaration => _nextClassId++,
      IdentifierKind.method => _nextMethodId++,
      IdentifierKind.variable => _nextVariableId++,
      IdentifierKind.unknown => _nextIdentifierId++,
    };
    var result = '${kind.prefix}$id';
    _identifiers[name] = result;
    return result;
  }

  /// Sanitizes a single message object [message].
  JsonMap sanitizeMessage(JsonMap message) {
    var sanitized = Map.of(message);
    var method = sanitized['method'] as String?;
    var id = sanitized['id'];

    if (id != null && method != null) {
      _requestMethods[id] = method;
    }

    if (method != null) {
      // Request or notification
      if (sanitized['params'] case JsonMap params) {
        sanitized['params'] = _sanitizeParams(method, params);
      } else if (sanitized['params'] case List<Object?> paramsList) {
        sanitized['params'] = paramsList.map(_sanitizeJsonValue).toList();
      }
    } else if (id != null) {
      // Response
      var requestMethod = _requestMethods[id];
      if (sanitized.containsKey('result')) {
        sanitized['result'] = _sanitizeResult(
          requestMethod,
          sanitized['result'],
        );
      }
    }

    return sanitized;
  }

  /// Sanitizes a path or URI while preserving file suffixes and keeping
  /// components consistent across invocations.
  String sanitizePath(String path) {
    if (path.isEmpty) return path;

    // Handle standard Dart SDK URIs.
    if (path.startsWith('dart:')) return path;

    var prefix = '';
    var remainder = path;

    // Preserve placeholders like '{{workspaceFolder-0}}' or
    // '{{rootPath:filePath}}'.
    if (remainder.startsWith('{{')) {
      var closingIndex = remainder.indexOf('}}');
      if (closingIndex != -1) {
        prefix = remainder.substring(0, closingIndex + 2);
        remainder = remainder.substring(closingIndex + 2);
      }
    }

    // Handle URI schemes.
    if (remainder.startsWith('file:///')) {
      prefix += 'file:///';
      remainder = remainder.substring(8);
    } else if (remainder.startsWith('file://')) {
      prefix += 'file://';
      remainder = remainder.substring(7);
    } else if (remainder.startsWith('package:')) {
      prefix += 'package:';
      remainder = remainder.substring(8);
    }

    // Handle Windows drive letter (e.g., C: or C:/ or C:\).
    var driveMatch = _drivePattern.firstMatch(remainder);
    if (driveMatch != null) {
      prefix += driveMatch.group(1)! + (driveMatch.group(2) ?? '');
      remainder = remainder.substring(driveMatch.group(0)!.length);
    } else if (remainder.startsWith('/') || remainder.startsWith(r'\')) {
      // Preserve leading slash(es).
      var slashMatch = _leadingSlashPattern.firstMatch(remainder);
      if (slashMatch != null) {
        prefix += slashMatch.group(0)!;
        remainder = remainder.substring(slashMatch.group(0)!.length);
      }
    }

    if (remainder.isEmpty) return prefix;

    var segments = remainder.split(_pathSeparatorPattern);
    var sanitizedSegments = <String>[];
    for (var segment in segments) {
      if (segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.startsWith('{{') && segment.endsWith('}}')) {
        sanitizedSegments.add(segment);
        continue;
      }

      // Sanitize segment while preserving allowed file extensions ('.dart',
      // '.yaml').
      var dotIndex = segment.lastIndexOf('.');
      if (dotIndex > 0) {
        var ext = segment.substring(dotIndex);
        if (_preservedFileExtensions.contains(ext)) {
          var baseName = segment.substring(0, dotIndex);
          var sanitizedBase = _pathSegments.putIfAbsent(
            baseName,
            () => 'p${_nextPathId++}',
          );
          sanitizedSegments.add('$sanitizedBase$ext');
          continue;
        }
      }

      var sanitizedBase = _pathSegments.putIfAbsent(
        segment,
        () => 'p${_nextPathId++}',
      );
      sanitizedSegments.add(sanitizedBase);
    }

    var separator = remainder.contains(r'\') && !remainder.contains('/')
        ? r'\'
        : '/';
    return prefix + sanitizedSegments.join(separator);
  }

  /// Sanitizes [type], a display String for a type annotation and signature.
  String sanitizeTypeString(
    String type, {
    IdentifierKind kind = IdentifierKind.unknown,
  }) {
    if (type.isEmpty) return type;

    return type.replaceAllMapped(_identifierPattern, (match) {
      var token = match[0]!;
      if (token.isDartKeyword || _coreSdkTypes.contains(token)) return token;

      return sanitizeIdentifier(token, kind: kind);
    });
  }

  /// Replace source content with a character length comment.
  String scrubContent(String content) {
    return '/* ${content.length} characters */';
  }

  String _sanitizeClosingLabel(String label) {
    if (label.isEmpty) return label;
    if (label.contains('(')) {
      var openParen = label.indexOf('(');
      var funcName = label.substring(0, openParen);
      var sanitizedFuncName = sanitizeIdentifier(
        funcName,
        kind: IdentifierKind.method,
      );
      return '$sanitizedFuncName(...)';
    }
    return sanitizeIdentifier(label, kind: IdentifierKind.typeDeclaration);
  }

  String _sanitizeCodeActionTitle(String title) {
    // Sanitize any single/double quoted identifiers in action title.
    return title.replaceAllMapped(_quotedIdentifierPattern, (match) {
      var quote1 = match.group(1)!;
      var ident = match.group(2)!;
      var quote2 = match.group(3)!;
      return '$quote1${sanitizeIdentifier(ident)}$quote2';
    });
  }

  JsonMap _sanitizeCommand(JsonMap command) => Map.of(command)
    ..updateIfType<List<Object?>>(
      'arguments',
      (args) => args.map(_sanitizeJsonValue).toList(),
    );

  String _sanitizeCommandLineArg(String arg) {
    if (arg.startsWith('--') && arg.contains('=')) {
      var eq = arg.indexOf('=');
      var flag = arg.substring(0, eq);
      var value = arg.substring(eq + 1);
      return (value.looksLikePath) ? '$flag=${sanitizePath(value)}' : arg;
    } else if (arg.looksLikePath) {
      return sanitizePath(arg);
    }
    return arg.startsWith('--') ? arg : '...';
  }

  JsonMap _sanitizeCompletionItem(JsonMap item) {
    var sanitized = Map.of(item);
    var kind = IdentifierKind.forLspCompletionItemKind(
      sanitized['kind'] as int?,
    );
    sanitized.updateIfType<String>(
      'label',
      (label) => sanitizeIdentifier(label, kind: kind),
    );
    sanitized.updateIfType<String>('detail', (_) => '<sanitized>');
    sanitized.updateIfType<JsonMap>('labelDetails', _sanitizeLabelDetails);
    sanitized.updateIfType('documentation', _sanitizeDocumentation);
    sanitized.updateIfType<JsonMap>('textEdit', (textEdit) {
      return Map.of(textEdit)
        ..updateIfType<String>('newText', sanitizeIdentifier);
    });
    sanitized.updateIfType<String>('textEditText', sanitizeIdentifier);
    sanitized.updateIfType<String>('filterText', sanitizeIdentifier);
    sanitized.updateIfType<String>('insertText', sanitizeIdentifier);
    sanitized.updateIfType<JsonMap>('data', _sanitizeCompletionItemData);
    return sanitized;
  }

  JsonMap _sanitizeCompletionItemData(JsonMap data) {
    var sanitized = Map.of(data);
    sanitized.updateIfType<String>('file', sanitizePath);
    sanitized.updateIfType<List<Object?>>('importUris', (uris) {
      return uris.map((u) => u is String ? sanitizePath(u) : u).toList();
    });
    sanitized.updateIfType<String>('ref', (ref) {
      var parts = ref.split(';');
      if (parts.isEmpty) return ref;
      var sanitizedParts = <String>[];
      sanitizedParts.add(sanitizePath(parts[0]));
      for (var i = 1; i < parts.length; i++) {
        sanitizedParts.add(sanitizeIdentifier(parts[i]));
      }
      return sanitizedParts.join(';');
    });
    return sanitized;
  }

  Object? _sanitizeDocumentation(Object? doc) {
    if (doc is String) return _sanitizeHoverValue(doc);
    if (doc is JsonMap) {
      return Map.of(doc)..updateIfType<String>('value', _sanitizeHoverValue);
    }
    return doc;
  }

  JsonMap _sanitizeDocumentSymbol(JsonMap symbol) {
    var sanitizedSymbol = Map.of(symbol);
    var kind = IdentifierKind.forLspSymbolKind(sanitizedSymbol['kind'] as int?);
    sanitizedSymbol.updateIfType<String>(
      'name',
      (name) => sanitizeIdentifier(name, kind: kind),
    );
    sanitizedSymbol.updateIfType<String>(
      'containerName',
      (containerName) => sanitizeIdentifier(
        containerName,
        kind: IdentifierKind.typeDeclaration,
      ),
    );
    sanitizedSymbol.updateIfType<String>('detail', (_) => '<sanitized>');
    sanitizedSymbol.updateIfType<List<Object?>>(
      'children',
      (children) => children
          .map((c) => c is JsonMap ? _sanitizeDocumentSymbol(c) : c)
          .toList(),
    );
    return sanitizedSymbol;
  }

  JsonMap _sanitizeFlutterOutline(JsonMap flutterOutline) =>
      Map.of(flutterOutline)
        ..updateIfType<String>(
          'className',
          (className) => sanitizeIdentifier(
            className,
            kind: IdentifierKind.typeDeclaration,
          ),
        )
        ..updateIfType<String>(
          'variableName',
          (variableName) =>
              sanitizeIdentifier(variableName, kind: IdentifierKind.variable),
        )
        ..updateIfType('label', _sanitizeClosingLabel)
        ..updateIfType<List<Object?>>('children', (children) {
          return children
              .map((c) => c is JsonMap ? _sanitizeFlutterOutline(c) : c)
              .toList();
        });

  String _sanitizeHoverValue(String value) => '<${value.length} chars>';

  Object? _sanitizeJsonValue(Object? value) {
    return switch (value) {
      String() => value.looksLikePath ? sanitizePath(value) : '...',
      List<Object?>() => value.map(_sanitizeJsonValue).toList(),
      JsonMap() => {
        for (var MapEntry(:key, :value) in value.entries)
          (key.looksLikePath ? sanitizePath(key) : key): _sanitizeJsonValue(
            value,
          ),
      },
      _ => value,
    };
  }

  JsonMap _sanitizeLabelDetails(JsonMap labelDetails) => Map.of(labelDetails)
    ..updateIfType<String>('detail', (_) => '<sanitized>')
    ..updateIfType<String>(
      'description',
      (desc) => desc.looksLikePath ? sanitizePath(desc) : desc,
    );

  JsonMap _sanitizeOutline(JsonMap outline) {
    var sanitized = Map.of(outline);
    sanitized.updateIfType<JsonMap>('element', (element) {
      return Map.of(element)
        ..updateIfType<String>(
          'name',
          (name) => sanitizeIdentifier(
            name,
            kind: IdentifierKind.forKind(element['kind'] as String?),
          ),
        )
        ..updateIfType<String>(
          'returnType',
          (returnType) => sanitizeTypeString(
            returnType,
            kind: IdentifierKind.typeDeclaration,
          ),
        )
        ..updateIfType('parameters', sanitizeTypeString)
        ..updateIfType<String>(
          'typeParameters',
          (typeParameters) => sanitizeTypeString(
            typeParameters,
            kind: IdentifierKind.typeDeclaration,
          ),
        );
    });
    sanitized.updateIfType<List<Object?>>(
      'children',
      (children) => children
          .map((child) => child is JsonMap ? _sanitizeOutline(child) : child)
          .toList(),
    );
    return sanitized;
  }

  JsonMap _sanitizeParams(String method, JsonMap params) {
    var sanitized = Map.of(params);

    switch (method) {
      case 'command/resolve':
      case 'workspace/executeCommand':
        sanitized = _sanitizeCommand(sanitized);

      case 'completionItem/resolve':
        sanitized = _sanitizeCompletionItem(sanitized);

      case 'initialize':
        sanitized.updateIfType('rootPath', sanitizePath);
        sanitized.updateIfType('rootUri', sanitizePath);
        sanitized.updateIfType<List<Object?>>('workspaceFolders', (folders) {
          return folders.map((folder) {
            if (folder is! JsonMap) return folder;
            return Map.of(folder)
              ..updateIfType('uri', sanitizePath)
              ..updateIfType('name', sanitizePath);
          }).toList();
        });

      case 'textDocument/didOpen':
        sanitized.updateIfType<JsonMap>('textDocument', (textDoc) {
          return Map.of(textDoc)
            ..updateIfType('uri', sanitizePath)
            ..updateIfType('text', scrubContent);
        });

      case 'textDocument/didChange':
        sanitized.updateIfType<JsonMap>('textDocument', (textDoc) {
          return Map.of(textDoc)..updateIfType('uri', sanitizePath);
        });
        sanitized.updateIfType<List<Object?>>('contentChanges', (changes) {
          return changes.map((change) {
            if (change is! JsonMap) return change;
            return Map.of(change)..updateIfType<String>(
              'text',
              (text) => _nonAlphanumericPattern.hasMatch(text)
                  ? text
                  : _whitespacePattern.hasMatch(text)
                  ? scrubContent(text)
                  : sanitizeIdentifier(text),
            );
          }).toList();
        });

      case 'textDocument/publishDiagnostics':
        sanitized.updateIfType('uri', sanitizePath);
        sanitized.updateIfType<List<Object?>>('diagnostics', (diagnostics) {
          return diagnostics.map((d) {
            if (d is! JsonMap) return d;
            return Map.of(d)..updateIfType('message', _sanitizePathsInText);
          }).toList();
        });

      case 'textDocument/rename':
        sanitized.updateIfType<JsonMap>(
          'textDocument',
          (textDoc) => Map.of(textDoc)..updateIfType('uri', sanitizePath),
        );
        sanitized.updateIfType('newName', sanitizeIdentifier);

      case 'textDocument/prepareRename':
      case 'textDocument/codeAction':
      case 'textDocument/codeLens':
      case 'textDocument/completion':
      case 'textDocument/hover':
      case 'textDocument/documentHighlight':
      case 'textDocument/documentSymbol':
      case 'textDocument/semanticTokens/full':
      case 'textDocument/semanticTokens/range':
      case 'textDocument/foldingRange':
      case 'textDocument/formatting':
      case 'textDocument/inlayHint':
      case 'textDocument/documentLink':
      case 'textDocument/documentColor':
      case 'textDocument/didClose':
      case 'textDocument/didSave':
        sanitized.updateIfType<JsonMap>(
          'textDocument',
          (textDoc) => Map.of(textDoc)..updateIfType('uri', sanitizePath),
        );

      case 'dart/textDocument/publishOutline':
        sanitized.updateIfType('uri', sanitizePath);
        sanitized.updateIfType('outline', _sanitizeOutline);

      case 'dart/textDocument/publishFlutterOutline':
        sanitized.updateIfType('uri', sanitizePath);
        sanitized.updateIfType('outline', _sanitizeFlutterOutline);

      case 'dart/textDocument/publishClosingLabels':
        sanitized.updateIfType('uri', sanitizePath);
        sanitized.updateIfType<List<Object?>>('labels', (labels) {
          return labels.map((label_) {
            if (label_ is! JsonMap) return label_;
            return Map.of(label_)..updateIfType('label', _sanitizeClosingLabel);
          }).toList();
        });

      // Legacy analysis server protocol methods
      case 'analysis.updateContent':
        sanitized.updateIfType<JsonMap>('files', (files) {
          var sanitizedFiles = <String, Object?>{};
          for (var MapEntry(:key, :value) in files.entries) {
            var sanitizedFilePath = sanitizePath(key);
            if (value is JsonMap) {
              sanitizedFiles[sanitizedFilePath] = Map.of(value)
                ..updateIfType('content', scrubContent);
            } else {
              sanitizedFiles[sanitizedFilePath] = value;
            }
          }
          return sanitizedFiles;
        });

      case 'analysis.setAnalysisRoots':
        sanitized.updateIfType<List<Object?>>(
          'included',
          (included) =>
              included.map((p) => p is String ? sanitizePath(p) : p).toList(),
        );
        sanitized.updateIfType<List<Object?>>(
          'excluded',
          (excluded) =>
              excluded.map((p) => p is String ? sanitizePath(p) : p).toList(),
        );
        sanitized.updateIfType<JsonMap>('packageRoots', (packageRoots) {
          return {
            for (var MapEntry(:key, :value) in packageRoots.entries)
              sanitizePath(key): value is String ? sanitizePath(value) : value,
          };
        });

      // Unhandled message types
      case r'$/analyzerStatus':
      case r'$/cancelRequest':
      case r'$/logTrace':
      case r'$/progress':
      case r'$/setTrace':
      case 'callHierarchy/incomingCalls':
      case 'callHierarchy/outgoingCalls':
      case 'client/registerCapability':
      case 'client/unregisterCapability':
      case 'codeAction/resolve':
      case 'codeLens/resolve':
      case 'dart/connectToDtd':
      case 'dart/diagnosticServer':
      case 'dart/openUri':
      case 'dart/reanalyze':
      case 'dart/textDocument/augmentation':
      case 'dart/textDocument/augmented':
      case 'dart/textDocument/editArgument':
      case 'dart/textDocument/editableArguments':
      case 'dart/textDocument/getFlutterWidgetPreviews':
      case 'dart/textDocument/imports':
      case 'dart/textDocument/summary':
      case 'dart/textDocument/super':
      case 'dart/updateDiagnosticInformation':
      case 'dart/workspace/analysis/complete':
      case 'dart/workspace/fixes/get':
      case 'dart/workspace/getFlutterWidgetPreviews':
      case 'dart/workspace/migrate':
      case 'documentLink/resolve':
      case 'exit':
      case 'experimental/echo':
      case 'initialized':
      case 'inlayHint/resolve':
      case 'notebookDocument/didChange':
      case 'notebookDocument/didClose':
      case 'notebookDocument/didOpen':
      case 'notebookDocument/didSave':
      case 'shutdown':
      case 'telemetry/event':
      case 'textDocument/colorPresentation':
      case 'textDocument/declaration':
      case 'textDocument/definition':
      case 'textDocument/diagnostic':
      case 'textDocument/implementation':
      case 'textDocument/inlineCompletion':
      case 'textDocument/inlineValue':
      case 'textDocument/linkedEditingRange':
      case 'textDocument/moniker':
      case 'textDocument/onTypeFormatting':
      case 'textDocument/prepareCallHierarchy':
      case 'textDocument/prepareTypeHierarchy':
      case 'textDocument/rangeFormatting':
      case 'textDocument/rangesFormatting':
      case 'textDocument/references':
      case 'textDocument/selectionRange':
      case 'textDocument/semanticTokens':
      case 'textDocument/semanticTokens/full/delta':
      case 'textDocument/signatureHelp':
      case 'textDocument/typeDefinition':
      case 'textDocument/willSave':
      case 'textDocument/willSaveWaitUntil':
      case 'typeHierarchy/subtypes':
      case 'typeHierarchy/supertypes':
      case 'window/logMessage':
      case 'window/showDocument':
      case 'window/showMessage':
      case 'window/showMessageRequest':
      case 'window/workDoneProgress/cancel':
      case 'window/workDoneProgress/create':
      case 'workspace/applyEdit':
      case 'workspace/codeLens/refresh':
      case 'workspace/configuration':
      case 'workspace/diagnostic':
      case 'workspace/diagnostic/refresh':
      case 'workspace/didChangeConfiguration':
      case 'workspace/didChangeWatchedFiles':
      case 'workspace/didChangeWorkspaceFolders':
      case 'workspace/didCreateFiles':
      case 'workspace/didDeleteFiles':
      case 'workspace/didRenameFiles':
      case 'workspace/foldingRange/refresh':
      case 'workspace/inlayHint/refresh':
      case 'workspace/inlineValue/refresh':
      case 'workspace/semanticTokens/refresh':
      case 'workspace/symbol':
      case 'workspace/textDocumentContent':
      case 'workspace/textDocumentContent/refresh':
      case 'workspace/willCreateFiles':
      case 'workspace/willDeleteFiles':
      case 'workspace/willRenameFiles':
      case 'workspace/workspaceFolders':
      case 'workspaceSymbol/resolve':
      default:
        return _sanitizeJsonValue(sanitized) as JsonMap;
    }

    return sanitized;
  }

  String _sanitizePathsInText(String text) {
    // Sanitize file URIs and absolute paths in text.
    return text.replaceAllMapped(
      _pathsInTextPattern,
      (match) => sanitizePath(match[0]!),
    );
  }

  Object? _sanitizeResult(String? requestMethod, Object? result) {
    if (result == null) return null;

    switch (requestMethod) {
      case 'command/resolve':
        if (result is JsonMap) return _sanitizeCommand(result);

      case 'completionItem/resolve':
        if (result is JsonMap) return _sanitizeCompletionItem(result);

      case 'textDocument/codeAction':
        if (result is List<Object?>) {
          return result.map((item) {
            if (item is! JsonMap) return item;
            return Map.of(item)
              ..updateIfType('title', _sanitizeCodeActionTitle)
              ..updateIfType<JsonMap>('edit', (edit) {
                return _sanitizeResult('textDocument/rename', edit);
              });
          }).toList();
        }

      case 'textDocument/codeLens' when result is List<Object?>:
        return result.map((item) {
          if (item is! JsonMap) return item;
          return Map.of(item)..updateIfType<JsonMap>(
            'command',
            (command) => Map.of(command)
              ..updateIfType<List<Object?>>(
                'arguments',
                (args) => args.map(_sanitizeJsonValue).toList(),
              ),
          );
        }).toList();

      case 'textDocument/completion':
        if (result is JsonMap) {
          return Map.of(result)..updateIfType<List<Object?>>(
            'items',
            (items) => items
                .map(
                  (item) =>
                      item is JsonMap ? _sanitizeCompletionItem(item) : item,
                )
                .toList(),
          );
        } else if (result is List<Object?>) {
          return result
              .map(
                (item) =>
                    item is JsonMap ? _sanitizeCompletionItem(item) : item,
              )
              .toList();
        }

      case 'textDocument/documentLink' when result is List<Object?>:
        return result.map((item) {
          if (item is! JsonMap) return item;
          return Map.of(item)..updateIfType('target', sanitizePath);
        }).toList();

      case 'textDocument/documentSymbol' when result is List<Object?>:
        return [
          for (var item in result)
            item is JsonMap ? _sanitizeDocumentSymbol(item) : item,
        ];

      case 'textDocument/hover':
        if (result is JsonMap) {
          return Map.of(result)..updateIfType<JsonMap>(
            'contents',
            (contents) =>
                Map.of(contents)..updateIfType('value', _sanitizeHoverValue),
          );
        }

      case 'textDocument/inlayHint':
        if (result is List<Object?>) {
          return result.map((item) {
            if (item is! JsonMap) return item;
            return Map.of(item)..updateIfType('label', sanitizeTypeString);
          }).toList();
        }

      case 'textDocument/prepareRename':
        if (result is JsonMap) {
          return Map.of(result)
            ..updateIfType('placeholder', sanitizeIdentifier);
        }

      case 'textDocument/rename' when result is JsonMap:
        var sanitized = Map.of(result);
        sanitized.updateIfType<JsonMap>('changes', (changes) {
          var sanitizedChanges = <String, Object?>{};
          for (var MapEntry(:key, :value) in changes.entries) {
            var sanitizedUri = sanitizePath(key);
            if (value is List<Object?>) {
              sanitizedChanges[sanitizedUri] = value.map((edit) {
                if (edit is! JsonMap) return edit;
                return Map.of(edit)
                  ..updateIfType('newText', sanitizeIdentifier);
              }).toList();
            } else {
              sanitizedChanges[sanitizedUri] = value;
            }
          }
          return sanitizedChanges;
        });
        sanitized.updateIfType<List<Object?>>('documentChanges', (docChanges) {
          return docChanges.map((docChange) {
            if (docChange is! JsonMap) return docChange;
            var sanitizedDocChange = Map.of(docChange);
            sanitizedDocChange.updateIfType(
              'textDocument',
              (JsonMap textDoc) =>
                  Map.of(textDoc)..updateIfType('uri', sanitizePath),
            );
            sanitizedDocChange.updateIfType<List<Object?>>('edits', (edits) {
              return edits.map((edit) {
                if (edit is! JsonMap) return edit;
                return Map.of(edit)
                  ..updateIfType('newText', sanitizeIdentifier);
              }).toList();
            });
            return sanitizedDocChange;
          }).toList();
        });
        return sanitized;

      case 'workspace/configuration' when result is List<Object?>:
        return [
          for (var item in result)
            item is JsonMap ? _sanitizeWorkspaceConfig(item) : item,
        ];

      default:
        return _sanitizeJsonValue(result);
    }

    return _sanitizeJsonValue(result);
  }

  JsonMap _sanitizeWorkspaceConfig(JsonMap config) {
    var sanitized = Map.of(config);
    for (var MapEntry(:key, :value) in sanitized.entries) {
      if (value is String) {
        sanitized[key] = value.looksLikePath ? sanitizePath(value) : '...';
      } else if (value is List<Object?>) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return item.looksLikePath ? sanitizePath(item) : '...';
          }
          return item;
        }).toList();
      }
    }
    return sanitized;
  }
}

extension<K, V> on Map<K, V> {
  /// Updates the value for the provided [key] with [update] if the value for
  /// [key] is of type [T].
  ///
  /// Does nothing if [key] is not present or if its value is not of type [T].
  void updateIfType<T>(K key, V Function(T value) update) {
    var value = this[key];
    if (value is T) {
      this[key] = update(value);
    }
  }
}

extension on String {
  static final RegExp _windowsDrivePathPattern = RegExp(r'^[a-zA-Z]:[/\\]');

  /// Extra pseudo-keywords or compiler directives not in [Keyword.keywords].
  static const Set<String> _extraKeywords = {'inline', 'macro', 'type'};

  bool get isDartKeyword =>
      Keyword.keywords.containsKey(this) || _extraKeywords.contains(this);

  bool get looksLikePath {
    if (isEmpty) return false;
    return startsWith('file://') ||
        startsWith('package:') ||
        startsWith('{{') ||
        _windowsDrivePathPattern.hasMatch(this) ||
        contains('/') ||
        contains(r'\');
  }
}

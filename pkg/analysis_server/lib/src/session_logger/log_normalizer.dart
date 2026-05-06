// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show InitializeParams;
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:path/path.dart' as path;

/// A utility for normalizing paths in log entries.
class LogNormalizer {
  final path.Context pathContext;

  /// A map from the path-to-be-replaced to the replacement string.
  ///
  /// Paths are canonicalized to lowercase and the replacement regex is
  /// case-insensitive.
  final Map<String, String> _replacements =
      CanonicalizedMap<String, String, String>((key) => key.toLowerCase());

  /// A cached regex for all current replacements to allow them to occur in a
  /// single pass.
  RegExp? _replacementPattern;

  LogNormalizer(this.pathContext);

  /// Extracts paths and URIs from an LSP initialize request and adds
  /// replacements for each.
  void addLspWorkspaceReplacements(Message message) {
    var params = message.params;
    if (params == null ||
        !InitializeParams.canParse(params, nullLspJsonReporter)) {
      return;
    }

    var initializeParams = InitializeParams.fromJson(params);

    if (initializeParams.rootPath case var rootPath?) {
      addPathReplacement(rootPath, '{{rootPath}}');
    }

    if (initializeParams.rootUri case var rootUri?) {
      if (rootUri.isScheme('file')) {
        addUriReplacement(rootUri, '{{rootUri}}');
      }
    }

    if (initializeParams.workspaceFolders case var workspaceFolders?) {
      for (var i = 0; i < workspaceFolders.length; i++) {
        var uri = workspaceFolders[i].uri;
        if (uri.isScheme('file')) {
          addUriReplacement(uri, '{{workspaceFolder-$i}}');
        }
      }
    }
  }

  /// Adds a replacement for the given [inputPath] in both path and URI form.
  ///
  /// Replacements assume the path (or URI) appear as quoted strings in the
  /// JSON (and therefore must be preceeded by a quote and followed by a
  /// path/uri separator or another quote).
  void addPathReplacement(String inputPath, String replacement) {
    if (inputPath.isEmpty) return;

    var uri = Uri.file(inputPath);
    var uriString = uri.toString();
    // VS Code always encodes colons in the path part so we need to handle
    //  file:///c:/foo and
    //  file:///c%3A/foo
    var uriStringWithEncodedColons = uri
        .replace(path: uri.path.replaceAll(':', '%3A'))
        .toString();

    void addWithQuotesAndTrailingSlash(String input, String separator) {
      _replacements['"$input"'] = '"$replacement"';
      _replacements['"$input$separator'] = '"$replacement$separator';
    }

    // All replacements must be in the map because we need to look up the values
    // during replacement so if the regex matches variations, we need to be able
    // to find them here.

    // TODO(dantup): If a client json encodes slightly differently to Dart, the
    //  encoded version here might not be a match. Perhaps we should instead
    //  build RegExp's here that handle encoded/unencoded versions of each
    //  character that might be different (and fold the special case for colon
    //  from above into it).

    // Paths
    var separator = pathContext.separator;
    addWithQuotesAndTrailingSlash(inputPath, separator);
    addWithQuotesAndTrailingSlash(_jsonEncode(inputPath), separator);

    // URIs
    separator = '/';
    addWithQuotesAndTrailingSlash(uriString, separator);
    addWithQuotesAndTrailingSlash(_jsonEncode(uriString), separator);
    addWithQuotesAndTrailingSlash(uriStringWithEncodedColons, separator);
    addWithQuotesAndTrailingSlash(
      _jsonEncode(uriStringWithEncodedColons),
      separator,
    );

    // Reset the cached pattern so it's built on the next call to normalize.
    _replacementPattern = null;
  }

  /// Adds a replacement for the given [inputUri] in both path and URI form, but raw
  /// and JSON encoded.
  void addUriReplacement(Uri uri, String replacement) {
    if (uri.isScheme('file')) {
      addPathReplacement(uri.toFilePath(), replacement);
    }
  }

  /// Returns the given [json] string after replacing any known paths with
  /// placeholders.
  String normalize(String json) {
    if (_replacements.isEmpty) return json;

    // Build a single regex that matches any of the replacements.
    var replacementPattern = _replacementPattern ??= RegExp(
      (_replacements.keys.toList()
            // Sort keys longest-to-shortest so that we always replace the
            // largest part of the path if there are nested workspace folders.
            ..sort((a, b) => b.length.compareTo(a.length)))
          .map(RegExp.escape)
          .join('|'),
      caseSensitive: false,
    );

    // Replace with the respective value from the replacement map.
    return json.replaceAllMapped(
      replacementPattern,
      (match) => _replacements[match[0]]!,
    );
  }

  /// Returns a JSON-encoded version of [inputString] without the surrounding
  /// quotes.
  String _jsonEncode(String inputString) {
    var encoded = json.encode(inputString);
    return encoded.substring(1, encoded.length - 1);
  }
}

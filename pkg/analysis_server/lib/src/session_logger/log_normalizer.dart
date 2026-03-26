// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show InitializeParams;
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';

/// A utility for normalizing paths in log entries.
class LogNormalizer {
  /// A map from the path-to-be-replaced to the replacement string.
  ///
  /// Paths are canonicalized to lowercase and the replacement regex is
  /// case-insensitive.
  final Map<String, String> _replacements =
      CanonicalizedMap<String, String, String>((key) => key.toLowerCase());

  /// A cached regex for all current replacements to allow them to occur in a
  /// single pass.
  RegExp? _replacementPattern;

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

  /// Adds a replacement for the given [inputPath] in both path and URI form, but raw
  /// and JSON encoded.
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

    // All replacements must be in the map because we need to look up the values
    // during replacement so if the regex matches variations, we need to be able
    // to find them here.
    _replacements[inputPath] = replacement;
    _replacements[_jsonEncode(inputPath)] = replacement;
    _replacements[uriString] = replacement;
    _replacements[_jsonEncode(uriString)] = replacement;
    _replacements[uriStringWithEncodedColons] = replacement;
    _replacements[_jsonEncode(uriStringWithEncodedColons)] = replacement;

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
      _replacements.keys.map(RegExp.escape).join('|'),
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

// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/session_logger/log_entry.dart';

/// A utility for normalizing paths in log entries.
class LogNormalizer {
  /// A map from the path-to-be-replaced to the replacement string.
  final Map<String, String> _replacements = {};

  /// Adds a replacement for the given [path].
  void addReplacement(String path, String replacement) {
    if (path.isEmpty) return;
    _replacements[path] = replacement;
    var encoded = json.encode(path);
    // Remove the surrounding quotes.
    encoded = encoded.substring(1, encoded.length - 1);
    if (encoded != path) {
      _replacements[encoded] = replacement;
    }
  }

  /// For a message with 'workspaceFolders' in its parameters, stores
  /// replacement mappings for the workspace folder paths.
  void addWorkspaceFolderReplacements(Message message) {
    if (message.params case {
      'workspaceFolders': List<Object?> workspaceFolders,
    }) {
      for (var i = 0; i < workspaceFolders.length; i++) {
        var folder = workspaceFolders[i] as Map<String, Object?>;
        if (folder case {'uri': String uriString}) {
          var uri = Uri.parse(uriString);
          if (uri.isScheme('file')) {
            addReplacement(uri.path, '{{workspaceFolder-$i}}');
          }
        }
      }
    }
  }

  /// Returns the given [json] string after replacing any known paths with
  /// placeholders.
  String normalize(String json) {
    var result = json;
    for (var MapEntry(key: path, value: replacement) in _replacements.entries) {
      result = result.replaceAll(path, replacement);
    }
    return result;
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Wraps the client (editor) configuration to provide stronger typing and
/// handling of default values where a setting has not been supplied.
class LspClientConfiguration {
  final Map<String, dynamic> _settings = <String, dynamic>{};

  List<String> get analysisExcludedFolders {
    // This setting is documented as a string array, but because editors are
    // unlikely to provide validation, support single strings for convenience.
    final value = _settings['analysisExcludedFolders'];
    if (value is String) {
      return [value];
    } else if (value is List && value.every((s) => s is String)) {
      return value.cast<String>();
    } else {
      return const [];
    }
  }

  bool get completeFunctionCalls => _settings['completeFunctionCalls'] ?? false;
  bool get enableSdkFormatter => _settings['enableSdkFormatter'] ?? true;
  int get lineLength => _settings['lineLength'];

  /// A preview flag for enabling commit characters for completions.
  ///
  /// This is a temporary setting to allow this feature to be tested without
  /// defaulting to on for everybody.
  bool get previewCommitCharacters =>
      _settings['previewCommitCharacters'] ?? false;

  /// Whether diagnostics should be generated for TODO comments.
  bool get showTodos => _settings['showTodos'] ?? false;

  /// Returns whether or not the provided new configuration changes any values
  /// that would require analysis roots to be updated.
  bool affectsAnalysisRoots(Map<String, dynamic> newConfig) {
    return _settings['analysisExcludedFolders'] !=
        newConfig['analysisExcludedFolders'];
  }

  void replace(Map<String, dynamic> newConfig) {
    _settings
      ..clear()
      ..addAll(newConfig);
  }
}

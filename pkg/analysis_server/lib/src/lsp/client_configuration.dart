// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// Provides access to both global and resource-specific client configuration.
///
/// Resource-specific config is currently only supported at the WorkspaceFolder
/// level so when looking up config for a resource, the nearest WorkspaceFolders
/// config will be used.
class LspClientConfiguration {
  /// Global settings for the workspace.
  ///
  /// Used as a fallback for resource settings if no specific config is found
  /// for the resource.
  LspGlobalClientConfiguration _globalSettings =
      LspGlobalClientConfiguration({});

  /// Settings for each resource.
  ///
  /// Keys are string paths without trailing path separators (eg. 'C:\foo').
  final Map<String, LspResourceClientConfiguration> _resourceSettings =
      <String, LspResourceClientConfiguration>{};

  /// Pattern for stripping trailing slashes that may be been provided by the
  /// client (in WorkspaceFolder URIs) for consistent comparisons.
  final _trailingSlashPattern = RegExp(r'[\/]+$');

  /// Returns the global configuration for the whole workspace.
  LspGlobalClientConfiguration get global => _globalSettings;

  /// Returns whether or not the provided new configuration changes any values
  /// that would require analysis roots to be updated.
  bool affectsAnalysisRoots(LspGlobalClientConfiguration otherConfig) {
    return _globalSettings.analysisExcludedFolders !=
        otherConfig.analysisExcludedFolders;
  }

  /// Returns config for a given resource.
  ///
  /// Because we only support config at the WorkspaceFolder level, this is done
  /// by finding the nearest WorkspaceFolder to [resourcePath] and using config
  /// for that.
  ///
  /// If no specific config is available, returns [global].
  LspResourceClientConfiguration forResource(String resourcePath) {
    final workspaceFolder = _getWorkspaceFolderPath(resourcePath);

    if (workspaceFolder == null) {
      return _globalSettings;
    }

    return _resourceSettings[_normaliseFolderPath(workspaceFolder)] ??
        _globalSettings;
  }

  /// Replaces all previously known configuration with updated values from the
  /// client.
  void replace(
    Map<String, Object?> globalConfig,
    Map<String, Map<String, Object?>> workspaceFolderConfig,
  ) {
    _globalSettings = LspGlobalClientConfiguration(globalConfig);

    _resourceSettings
      ..clear()
      ..addAll(workspaceFolderConfig.map(
        (key, value) => MapEntry(
          _normaliseFolderPath(key),
          LspResourceClientConfiguration(value, _globalSettings),
        ),
      ));
  }

  /// Gets the path for the WorkspaceFolder closest to [resourcePath].
  String? _getWorkspaceFolderPath(String resourcePath) {
    final candidates = _resourceSettings.keys
        .where((wfPath) =>
            wfPath == _normaliseFolderPath(resourcePath) ||
            path.isWithin(wfPath, resourcePath))
        .toList();
    candidates.sort((a, b) => -a.length.compareTo(b.length));
    return candidates.firstOrNull;
  }

  /// Normalises a folder path to never have a trailing path separator.
  String _normaliseFolderPath(String path) =>
      path.replaceAll(_trailingSlashPattern, '');
}

/// Wraps the client (editor) configuration to provide stronger typing and
/// handling of default values where a setting has not been supplied.
///
/// Settings in this class are only allowed to be configured at the workspace
/// level (they will be ignored at the resource level).
class LspGlobalClientConfiguration extends LspResourceClientConfiguration {
  LspGlobalClientConfiguration(Map<String, Object?> settings)
      : super(settings, null);

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

  /// Whether methods/functions in completion should include parens and argument
  /// placeholders when used in an invocation context.
  bool get completeFunctionCalls =>
      _settings['completeFunctionCalls'] as bool? ?? false;

  /// A preview flag for enabling commit characters for completions.
  ///
  /// This is a temporary setting to allow this feature to be tested without
  /// defaulting to on for everybody.
  bool get previewCommitCharacters =>
      _settings['previewCommitCharacters'] as bool? ?? false;

  /// Whether diagnostics should be generated for all TODO comments.
  bool get showAllTodos =>
      _settings['showTodos'] is bool ? _settings['showTodos'] as bool : false;

  /// A specific set of TODO comments that should generate diagnostics.
  ///
  /// Codes are all forced UPPERCASE regardless of what the client supplies.
  ///
  /// [showAllTodos] should be checked first, as this will return an empty
  /// set if `showTodos` is a boolean.
  Set<String> get showTodoTypes => _settings['showTodos'] is List
      ? (_settings['showTodos'] as List)
          .cast<String>()
          .map((kind) => kind.toUpperCase())
          .toSet()
      : const {};
}

/// Wraps the client (editor) configuration for a specific resource.
///
/// Settings in this class are only allowed to be configured either for a
/// resource or for the whole workspace.
///
/// Right now, we treat "resource" to always mean a WorkspaceFolder since no
/// known editors allow per-file configuration and it allows us to keep the
/// settings cached, invalidated only when WorkspaceFolders change.
class LspResourceClientConfiguration {
  final Map<String, Object?> _settings;
  final LspResourceClientConfiguration? _fallback;

  LspResourceClientConfiguration(this._settings, this._fallback);

  /// Whether to enable the SDK formatter.
  ///
  /// If this setting is `false`, the formatter will be unregistered with the
  /// client.
  bool get enableSdkFormatter =>
      _settings['enableSdkFormatter'] as bool? ??
      _fallback?.enableSdkFormatter ??
      true;

  /// The line length used when formatting documents.
  ///
  /// If null, the formatters default will be used.
  int? get lineLength =>
      _settings['lineLength'] as int? ?? _fallback?.lineLength;

  /// Whether to rename files when renaming classes inside them where the file
  /// and class name match.
  ///
  /// Values are "always", "prompt", "never". Any other values should be treated
  /// like "never".
  String get renameFilesWithClasses =>
      _settings['renameFilesWithClasses'] as String? ?? 'never';
}

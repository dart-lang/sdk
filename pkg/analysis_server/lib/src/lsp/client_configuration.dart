// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// Options for which parameter names to show Inlay Hints for.
enum InlayHintsParameterNamesMode {
  /// Never show hints for parameter names.
  none,

  /// Only show hints for parameter names with literal values, since if they
  /// are identifiers, they probably already describe the parameter.
  literal,

  /// Always show hints for parameter names.
  all,
}

/// Client configuration for Dart CodeLenses.
///
/// Defaults are set per-CodeLens but the user can override these by enabling
/// all, disabling all, or setting their own preferences.
///
/// ```js
/// "dart.codeLens": true, // Enables all CodeLens
///
/// "dart.codeLens": false, // Disables all CodeLens
///
/// "dart.codeLens": {
///   "augmented": false, // Disables augmented but otherwise keeps defaults.
/// }
/// ```
class LspClientCodeLensConfiguration {
  final bool? _boolean;
  final Map<String, Object?>? _map;

  LspClientCodeLensConfiguration(Object? userPreference)
    : _boolean = userPreference is bool ? userPreference : null,
      _map = userPreference is Map<String, Object?> ? userPreference : null;

  /// Whether the "Go to Augmentation" CodeLens is enabled.
  bool get augmentation => _getEnabled('augmentation', true);

  /// Whether the "Go to Augmented" CodeLens is enabled.
  bool get augmented => _getEnabled('augmented', true);

  bool _getEnabled(String name, bool defaultValue) {
    if (_boolean != null) {
      return _boolean;
    }

    return switch (_map?[name]) {
      bool enabled => enabled,
      _ => defaultValue,
    };
  }
}

/// Provides access to both global and resource-specific client configuration.
///
/// Resource-specific config is currently only supported at the WorkspaceFolder
/// level so when looking up config for a resource, the nearest WorkspaceFolders
/// config will be used.
///
/// Settings prefixed with 'preview' are things that may not be completed but
/// may be exposed to users as something they can try out.
///
/// Settings prefixed with 'experimental' are things that may be incomplete or
/// still in development and users are not encouraged to try (but may be useful
/// for Dart developers to enable for development/testing).
class LspClientConfiguration {
  final path.Context pathContext;

  /// Global settings for the workspace.
  ///
  /// Used as a fallback for resource settings if no specific config is found
  /// for the resource.
  LspGlobalClientConfiguration _globalSettings = LspGlobalClientConfiguration(
    {},
  );

  /// Settings for each resource.
  ///
  /// Keys are string paths without trailing path separators (eg. 'C:\foo').
  final Map<String, LspResourceClientConfiguration> _resourceSettings =
      <String, LspResourceClientConfiguration>{};

  /// Pattern for stripping trailing slashes that may be been provided by the
  /// client (in WorkspaceFolder URIs) for consistent comparisons.
  final _trailingSlashPattern = RegExp(r'[\/]+$');

  LspClientConfiguration(this.pathContext);

  /// Returns the global configuration for the whole workspace.
  LspGlobalClientConfiguration get global => _globalSettings;

  /// Returns whether or not the provided new configuration changes any values
  /// that would affect analysis results.
  bool affectsAnalysisResults(LspGlobalClientConfiguration otherConfig) {
    // Check whether `TODO` settings have changed.
    var oldFlag = _globalSettings.showAllTodos;
    var newFlag = otherConfig.showAllTodos;
    var oldTypes = _globalSettings.showTodoTypes;
    var newTypes = otherConfig.showTodoTypes;
    return newFlag != oldFlag ||
        !const SetEquality<String>().equals(oldTypes, newTypes);
  }

  /// Returns whether or not the provided new configuration changes any values
  /// that would require analysis roots to be updated.
  bool affectsAnalysisRoots(LspGlobalClientConfiguration otherConfig) {
    var oldExclusions = _globalSettings.analysisExcludedFolders;
    var newExclusions = otherConfig.analysisExcludedFolders;
    return !const ListEquality<String>().equals(oldExclusions, newExclusions);
  }

  /// Returns config for a given resource.
  ///
  /// Because we only support config at the WorkspaceFolder level, this is done
  /// by finding the nearest WorkspaceFolder to [resourcePath] and using config
  /// for that.
  ///
  /// If no specific config is available, returns [global].
  LspResourceClientConfiguration forResource(String resourcePath) {
    var workspaceFolder = _getWorkspaceFolderPath(resourcePath);

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
      ..addAll(
        workspaceFolderConfig.map(
          (key, value) => MapEntry(
            _normaliseFolderPath(key),
            LspResourceClientConfiguration(value, _globalSettings),
          ),
        ),
      );
  }

  /// Gets the path for the WorkspaceFolder closest to [resourcePath].
  String? _getWorkspaceFolderPath(String resourcePath) {
    var candidates = _resourceSettings.keys
        .where(
          (wfPath) =>
              wfPath == _normaliseFolderPath(resourcePath) ||
              pathContext.isWithin(wfPath, resourcePath),
        )
        .toList();
    candidates.sort((a, b) => -a.length.compareTo(b.length));
    return candidates.firstOrNull;
  }

  /// Normalises a folder path to never have a trailing path separator.
  String _normaliseFolderPath(String filePath) =>
      filePath.replaceAll(_trailingSlashPattern, '');
}

/// Client configuration for Dart Inlay Hints.
///
/// Defaults to enabled for all hint types, but the user can override these by
/// enabling all, disabling all, or setting their own individual preferences.
///
/// ```js
/// "dart.inlayHints": true, // Enables all Inlay Hints
///
/// "dart.inlayHints": false, // Disables all Inlay Hints
///
/// "dart.inlayHints": {
///   "parameterNames": { "enabled": "literal" },
///   "parameterTypes": { "enabled": true },
///   "returnTypes": { "enabled": false },
///   "typeArguments": { "enabled": false },
///   "variableTypes": { "enabled": true }
/// }
/// ```
class LspClientInlayHintsConfiguration {
  late InlayHintsParameterNamesMode _parameterNames;
  late bool _parameterTypes;
  late bool _returnTypes;
  late bool _typeArguments;
  late bool _variableTypes;

  LspClientInlayHintsConfiguration(Object? userPreference) {
    var map = userPreference is Map<String, Object?> ? userPreference : null;
    var boolean = userPreference is bool ? userPreference : null;

    _parameterNames = _getParameterNamesMode(
      map,
      boolean ?? true
          ? InlayHintsParameterNamesMode.all
          : InlayHintsParameterNamesMode.none,
    );
    _parameterTypes = _getEnabled(map, 'parameterTypes', boolean ?? true);
    _returnTypes = _getEnabled(map, 'returnTypes', boolean ?? true);
    _typeArguments = _getEnabled(map, 'typeArguments', boolean ?? true);
    _variableTypes = _getEnabled(map, 'variableTypes', boolean ?? true);
  }

  /// Which kind of parameter names to show inlay hints for.
  InlayHintsParameterNamesMode get parameterNamesMode => _parameterNames;

  /// Whether parameter type inlay hints are enabled.
  bool get parameterTypesEnabled => _parameterTypes;

  /// Whether return type inlay hints are enabled.
  bool get returnTypesEnabled => _returnTypes;

  /// Whether type argument inlay hints are enabled.
  bool get typeArgumentsEnabled => _typeArguments;

  /// Whether variable type inlay hints are enabled.
  bool get variableTypesEnabled => _variableTypes;

  bool _getEnabled(Map<String, Object?>? map, String key, bool defaultValue) {
    return switch (map?[key]) {
      bool enabled => enabled,
      {'enabled': bool enabled} => enabled,
      _ => defaultValue,
    };
  }

  /// The mode for inlay hints on parameter names.
  InlayHintsParameterNamesMode _getParameterNamesMode(
    Map<String, Object?>? map,
    InlayHintsParameterNamesMode defaultMode,
  ) {
    return switch (map?['parameterNames']) {
      bool enabled || {'enabled': bool enabled} =>
        enabled
            ? InlayHintsParameterNamesMode.all
            : InlayHintsParameterNamesMode.none,
      String mode || {'enabled': String mode} => switch (mode) {
        'none' => InlayHintsParameterNamesMode.none,
        'literal' => InlayHintsParameterNamesMode.literal,
        'all' => InlayHintsParameterNamesMode.all,
        _ => InlayHintsParameterNamesMode.all,
      },
      _ => defaultMode,
    };
  }
}

/// Wraps the client (editor) configuration to provide stronger typing and
/// handling of default values where a setting has not been supplied.
///
/// Settings in this class are only allowed to be configured at the workspace
/// level (they will be ignored at the resource level).
class LspGlobalClientConfiguration extends LspResourceClientConfiguration {
  late final codeLens = LspClientCodeLensConfiguration(_settings['codeLens']);
  late final inlayHints = LspClientInlayHintsConfiguration(
    _settings['inlayHints'],
  );

  LspGlobalClientConfiguration(Map<String, Object?> settings)
    : super(settings, null);

  List<String> get analysisExcludedFolders {
    // This setting is documented as a string array, but because editors are
    // unlikely to provide validation, support single strings for convenience.
    var value = _settings['analysisExcludedFolders'];
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

  /// A flag for including property access in Inline Values.
  bool get experimentalInlineValuesProperties =>
      _settings['experimentalInlineValuesProperties'] as bool? ?? false;

  /// A flag for enabling interactive refactors flagged as experimental.
  ///
  /// This flag is likely to be used by both analysis server developers (working
  /// on new refactors) and users that want to test/provide feedback for
  /// incomplete refactors.
  bool get experimentalRefactors =>
      _settings['experimentalRefactors'] as bool? ?? false;

  /// Whether or not to include dependencies in `textDocument/workspaceSymbols`.
  ///
  /// If set to `false`, only analyzed files will be searched.
  /// Defaults to `true`.
  bool get includeDependenciesInWorkspaceSymbols =>
      _settings['includeDependenciesInWorkspaceSymbols'] as bool? ?? true;

  /// The users preferred kind of documentation for requests that return many
  /// results and could have large payloads when docs are included.
  ///
  /// If the user has not expressed a preference, defaults to
  /// [DocumentationPreference.full].
  DocumentationPreference get preferredDocumentation {
    var value = _settings['documentation'];
    return switch (value) {
      'none' => DocumentationPreference.none,
      'summary' => DocumentationPreference.summary,
      _ => DocumentationPreference.full,
    };
  }

  /// A preview flag for enabling commit characters for completions.
  ///
  /// This is a temporary setting to allow this feature to be tested without
  /// defaulting to on for everybody.
  bool get previewCommitCharacters =>
      _settings['previewCommitCharacters'] as bool? ?? false;

  // Whether diagnostics should be generated for all `TODO` comments.
  bool get showAllTodos =>
      _settings['showTodos'] is bool && _settings['showTodos'] as bool;

  /// A specific set of `TODO` comments that should generate diagnostics.
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
  /// The maximum number of completions to return for completion requests by
  /// default.
  ///
  /// This has been set fairly high initially to avoid changing behaviour too
  /// much. The Dart-Code extension will override this default with its own
  /// to gather feedback and then this can be adjusted accordingly.
  static const defaultMaxCompletions = 2000;

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

  /// Whether to include Snippets in code completion results.
  bool get enableSnippets {
    // Versions of Dart-Code earlier than v3.36 (1 Mar 2022) send
    // enableServerSnippets=false to opt-out of snippets. Later versions map
    // this version to the documented 'enableSnippets' setting in middleware.
    // Once the number of users on < 3.36 is insignificant, this check can be
    // removed. At 24 Mar 2022, approx 9% of users are on < 3.36.
    if (_settings['enableServerSnippets'] == false /* explicit false */ ) {
      return false;
    }

    return _settings['enableSnippets'] as bool? ??
        _fallback?.enableSnippets ??
        true;
  }

  /// The line length used when formatting documents if not specified in
  /// `analysis_options.yaml`.
  ///
  /// If null, the formatters default will be used.
  int? get lineLength =>
      _settings['lineLength'] as int? ?? _fallback?.lineLength;

  /// Requested maximum number of CompletionItems per completion request.
  ///
  /// If more than this are available, ranked items in the list will be
  /// truncated and `isIncomplete` is set to `true`.
  ///
  /// Unranked items are never truncated so it's still possible that more than
  /// this number of items will be returned.
  int get maxCompletionItems =>
      _settings['maxCompletionItems'] as int? ??
      _fallback?.maxCompletionItems ??
      defaultMaxCompletions;

  /// Whether to rename files when renaming classes inside them where the file
  /// and class name match.
  ///
  /// Values are "always", "prompt", "never". Any other values should be treated
  /// like "never".
  String get renameFilesWithClasses =>
      _settings['renameFilesWithClasses'] as String? ??
      _fallback?.renameFilesWithClasses ??
      'never';

  /// Whether to update imports and other directives when files are renamed.
  ///
  /// This setting works by controlling whether the server registers for
  /// `willRenameFiles` requests from the client. Changing the value after
  /// initialization will register/unregister appropriately.
  bool get updateImportsOnRename =>
      _settings['updateImportsOnRename'] as bool? ??
      _fallback?.updateImportsOnRename ??
      true;
}

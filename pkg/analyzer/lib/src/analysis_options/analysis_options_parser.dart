// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/analysis_options_validator.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

AnalysisOptionsCache _newMergedOptionsYamlCache() {
  return CanonicalizedMap(
    (key) {
      var (:containingUri, :uri) = key;
      if (uri.isScheme('package')) return uri;
      if (uri.isScheme('file') || uri.scheme.isEmpty) {
        if (uri.isAbsolute) return uri;
        if (containingUri != null) {
          return uriCache.resolveRelative(containingUri, uri);
        }
      }
      return uri;
    },
    isValidKey: (key) {
      // We can canonicalize a URI if it is a 'package:' URI (as this is per
      // SourceFactory), or if it is an absolute 'file:' URI, or if it is a
      // relative 'file:' URI and we have a "containing" URI which it is
      // relative to (via `UriCache.resolveRelative`).
      var (:containingUri, :uri) = key;
      if (uri.isScheme('package')) return true;
      if (uri.isScheme('file') || uri.scheme.isEmpty) {
        return uri.isAbsolute || containingUri != null;
      }
      return false;
    },
  );
}

/// The content of an analysis-options file.
final class AnalysisOptionsFileContent {
  /// The file text.
  final String text;

  /// Line information for [text].
  final LineInfo lineInfo;

  /// The parsed, unmerged YAML map from [text].
  ///
  /// This is `null` if [text] cannot be parsed as YAML, or is not a YAML map.
  final YamlMap? yamlMap;

  AnalysisOptionsFileContent({
    required this.text,
    required this.lineInfo,
    required this.yamlMap,
  });
}

/// The result of parsing an analysis options file at a user-visible boundary.
///
/// Analysis options are configuration, so parsing is best-effort: callers get
/// the effective options object along with diagnostics for parts of the file
/// graph that were ignored, malformed, unsupported, or inconsistent.
final class AnalysisOptionsParseResult {
  /// The initial options file passed to [AnalysisOptionsParseSession.parse].
  final File file;

  /// The content read from [file], or `null` if it could not be read.
  final AnalysisOptionsFileContent? content;

  final AnalysisOptionsImpl analysisOptions;
  final List<Diagnostic> diagnostics;

  AnalysisOptionsParseResult({
    required this.file,
    required this.content,
    required this.analysisOptions,
    required this.diagnostics,
  });
}

/// Parses analysis options during one analysis-options parsing task.
///
/// The session owns the separate internal caches needed while parsing still
/// delegates to the legacy validation and provider paths.
final class AnalysisOptionsParseSession {
  final AnalysisOptionsValidationCache _validationCache =
      AnalysisOptionsValidationCache();

  final Map<SourceFactory, AnalysisOptionsCache> _mergedOptionsYamlCaches = {};

  /// Parses [file] and reports diagnostics for the same file graph.
  ///
  /// This is the production boundary for callers that need the effective
  /// [AnalysisOptionsImpl] and the diagnostics produced while interpreting the
  /// same initial options file. The implementation still delegates to the
  /// existing builder and validator; keeping that delegation behind this session
  /// lets callers move to the combined contract before the internal include
  /// walks are collapsed.
  AnalysisOptionsParseResult parse({
    required SourceFactory sourceFactory,
    required Folder contextRoot,
    required File file,
    VersionConstraint? sdkVersionConstraint,
  }) {
    AnalysisOptionsFileContent? content;
    try {
      var text = file.readAsStringSync();
      content = AnalysisOptionsFileContent(
        text: text,
        lineInfo: LineInfo.fromContent(text),
        yamlMap: _parseYamlMap(text, sourceUrl: file.toUri()),
      );
    } catch (_) {}

    var diagnostics = const <Diagnostic>[];
    if (content != null) {
      try {
        // ignore: deprecated_member_use_from_same_package
        diagnostics = AnalysisOptionsValidator(
          sourceFactory: sourceFactory,
          contextRoot: contextRoot,
          sdkVersionConstraint: sdkVersionConstraint,
          validationCache: _validationCache,
        ).validate(file: file, content: content.text);
      } catch (_) {
        // Preserve the provider's best-effort behavior for unreadable initial
        // files while clients migrate to the combined parser API.
      }
    }

    AnalysisOptionsImpl analysisOptions;
    try {
      analysisOptions = AnalysisOptionsProvider(sourceFactory)
          // ignore: deprecated_member_use_from_same_package
          .getAnalysisOptionsFromFile(
            file,
            analysisOptionsCache: _mergedOptionsYamlCacheFor(sourceFactory),
          );
    } catch (_) {
      analysisOptions = AnalysisOptionsImpl(file: file);
    }

    return AnalysisOptionsParseResult(
      file: file,
      content: content,
      analysisOptions: analysisOptions,
      diagnostics: diagnostics,
    );
  }

  AnalysisOptionsCache _mergedOptionsYamlCacheFor(SourceFactory sourceFactory) {
    return _mergedOptionsYamlCaches.putIfAbsent(
      sourceFactory,
      _newMergedOptionsYamlCache,
    );
  }

  YamlMap? _parseYamlMap(String content, {required Uri sourceUrl}) {
    try {
      var node = loadYamlNode(content, sourceUrl: sourceUrl);
      return node.tryCast<YamlMap>();
    } on YamlException {
      return null;
    }
  }
}

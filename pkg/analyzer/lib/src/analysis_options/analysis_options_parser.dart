// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/analysis_options_validator.dart';
import 'package:analyzer/src/analysis_options/analysis_options_yaml.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

_MergedOptionsYamlCache _newMergedOptionsYamlCache() {
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

/// Cache of merged analysis-options YAML maps.
///
/// Entries are keyed by the URI being resolved and, for relative include URIs,
/// the containing URI that makes the include unambiguous.
typedef _MergedOptionsYamlCache = Map<({Uri? containingUri, Uri uri}), YamlMap>;

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
/// delegates to the legacy validation and merged-YAML builder paths.
final class AnalysisOptionsParseSession {
  final AnalysisOptionsValidationCache _validationCache =
      AnalysisOptionsValidationCache();

  final Map<SourceFactory, _MergedOptionsYamlCache> _mergedOptionsYamlCaches =
      {};

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
        // Preserve best-effort behavior while clients migrate to the combined
        // parser API.
      }
    }

    AnalysisOptionsImpl analysisOptions;
    try {
      var mergedOptionsYaml = _MergedOptionsYamlBuilder(
        sourceFactory: sourceFactory,
        pathContext: file.provider.pathContext,
        cache: _mergedOptionsYamlCacheFor(sourceFactory),
      ).getOptionsFromFile(file);
      analysisOptions = AnalysisOptionsImpl.fromYaml(
        optionsMap: mergedOptionsYaml,
        file: file,
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

  _MergedOptionsYamlCache _mergedOptionsYamlCacheFor(
    SourceFactory sourceFactory,
  ) {
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

/// Builds the effective YAML map used to create [AnalysisOptionsImpl].
///
/// This is intentionally private to [AnalysisOptionsParseSession]. It preserves
/// the legacy merge semantics while keeping callers on the combined
/// parse-and-validate API.
final class _MergedOptionsYamlBuilder {
  final SourceFactory sourceFactory;
  final path.Context pathContext;
  final _MergedOptionsYamlCache cache;

  _MergedOptionsYamlBuilder({
    required this.sourceFactory,
    required this.pathContext,
    required this.cache,
  });

  YamlMap getOptionsFromFile(File file) {
    return _getOptionsFromSource(FileSource(file), handled: {});
  }

  YamlMap _getOptionsFromSource(Source source, {required Set<Source> handled}) {
    if (cache[(containingUri: null, uri: source.uri)] case var cached?) {
      return cached;
    }

    YamlMap options;
    try {
      options = parseAnalysisOptionsYaml(
        source.stringContents,
        sourceUrl: source.uri,
      );
    } on Exception {
      // A YAML-parsing exception is reported by the validation path.
      return YamlMap();
    }

    var includeValue = options.valueAt(AnalysisOptionsFileKeys.include);
    var includes = switch (includeValue) {
      YamlScalar(:String value) => [value],
      YamlList() =>
        includeValue.nodes
            .whereType<YamlScalar>()
            .map((e) => e.value)
            .whereType<String>()
            .toList(),
      _ => <String>[],
    };

    var includeOptions = includes.fold(YamlMap(), (currentOptions, uriString) {
      var uri = uriCache.parse(uriString);
      YamlMap includedOptions;
      if (cache[(containingUri: source.uri, uri: uri)] case var cached?) {
        includedOptions = cached;
      } else {
        var includeSource = sourceFactory.resolveUri(source, uriString);
        if (includeSource == null || !handled.add(includeSource)) {
          return currentOptions;
        }

        includedOptions = _getOptionsFromSource(
          includeSource,
          handled: handled,
        );

        includedOptions = _rewriteRelativePaths(
          includedOptions,
          pathContext.dirname(includeSource.fullName),
        );
        cache[(containingUri: source.uri, uri: uri)] = includedOptions;
      }
      return _merge(currentOptions, includedOptions);
    });

    options = _merge(includeOptions, options);
    cache[(containingUri: null, uri: source.uri)] = options;
    return options;
  }

  YamlMap _merge(YamlMap defaults, YamlMap overrides) {
    return Merger().mergeMap(defaults, overrides);
  }

  /// Rewrites relative paths in semantic locations whose meaning depends on the
  /// file where they were declared.
  YamlMap _rewriteRelativePaths(YamlMap options, String directory) {
    var pluginsSection = options.valueAt(AnalysisOptionsFileKeys.plugins);
    if (pluginsSection is! YamlMap) {
      return options;
    }

    var plugins = <String, Object>{};
    pluginsSection.nodes.forEach((key, value) {
      if (key is YamlScalar && value is YamlMap) {
        var pathValue = value.valueAt(AnalysisOptionsFileKeys.path)?.value;
        if (pathValue is String) {
          if (pathContext.isRelative(pathValue)) {
            // The plugin source is later used in a synthetic pub package, so
            // it must no longer depend on the included file's location.
            pathValue = pathContext.join(directory, pathValue);
            pathValue = pathContext.normalize(pathValue);
          }

          plugins[key.value as String] = {
            AnalysisOptionsFileKeys.path: pathValue,
          };
        }
      }
    });
    return _merge(
      options,
      YamlMap.wrap({AnalysisOptionsFileKeys.plugins: plugins}),
    );
  }
}

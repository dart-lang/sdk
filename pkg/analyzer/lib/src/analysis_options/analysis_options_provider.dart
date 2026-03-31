// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// Provide the options found in the analysis options file.
class AnalysisOptionsProvider {
  /// The source factory used to resolve include declarations in analysis
  /// options files.
  final SourceFactory _sourceFactory;

  AnalysisOptionsProvider(this._sourceFactory);

  /// Provides the options found in [file].
  ///
  /// Recursively merges options referenced by any 'include' directives
  /// and removes any 'include' directive from the resulting options map.
  /// Returns an empty options map if the file does not exist or cannot be
  /// parsed.
  ///
  /// The [optionsCache] is used to avoid resolving URIs and reading options
  /// files from disk. A cache should only be passed which is used during an
  /// atomic task (like locating contexts) and which has [YamlMap] contents
  /// derived from this [_sourceFactory].
  YamlMap getOptionsFromFile(File file, {Map<Uri, YamlMap>? optionsCache}) {
    return _getOptionsFromSource(
      FileSource(file),
      file.provider.pathContext,
      handled: {},
      optionsCache: optionsCache ?? {},
    );
  }

  /// Provides the options found in [source].
  ///
  /// Recursively merges options referenced by any `include` directives and
  /// removes any `include` directives from the resulting options map. Returns
  /// an empty options map if the file does not exist or cannot be parsed.
  YamlMap getOptionsFromSource(Source source, path.Context pathContext) {
    return _getOptionsFromSource(
      source,
      pathContext,
      handled: {},
      optionsCache: {},
    );
  }

  /// Provide the options found in [content].
  ///
  /// Any 'include' directives, if present, will be left intact, and the
  /// referenced options will NOT be merged into the result. Returns an empty
  /// options map if the content is not a YAML map, or if a [YamlException] is
  /// thrown.
  YamlMap getOptionsFromString(String content, {Uri? sourceUrl}) {
    try {
      var doc = loadYamlNode(content, sourceUrl: sourceUrl);
      return doc is YamlMap ? doc : YamlMap();
    } on YamlException catch (e) {
      throw OptionsFormatException(e.message, e.span);
    }
  }

  /// Merge the given options contents where the values in [defaults] may be
  /// overridden by [overrides].
  ///
  /// Some notes about merge semantics:
  ///
  ///   * lists are merged (without duplicates).
  ///   * lists of scalar values can be promoted to simple maps when merged with
  ///     maps of strings to booleans (e.g., ['opt1', 'opt2'] becomes
  ///     {'opt1': true, 'opt2': true}.
  ///   * maps are merged recursively.
  ///   * if map values cannot be merged, the overriding value is taken.
  @visibleForTesting
  YamlMap merge(YamlMap defaults, YamlMap overrides) =>
      Merger().mergeMap(defaults, overrides);

  /// Provides the options found in [source].
  ///
  /// Recursively merges options referenced by any `include` directives and
  /// removes any `include` directives from the resulting options map. Returns
  /// an empty options map if the file does not exist or cannot be parsed.
  YamlMap _getOptionsFromSource(
    Source source,
    path.Context pathContext, {
    required Set<Source> handled,
    required Map<Uri, YamlMap> optionsCache,
  }) {
    YamlMap options;
    try {
      options = getOptionsFromString(source.stringContents);
    } on Exception {
      return YamlMap();
    }

    var includeValue = options.valueAt(AnalysisOptionsFile.include);
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
      if (optionsCache[uri] case var cached? when uri.isScheme('package')) {
        includedOptions = cached;
      } else {
        var includeSource = _sourceFactory.resolveUri(source, uriString);
        if (includeSource == null || !handled.add(includeSource)) {
          // Return the existing options, unchanged.
          return currentOptions;
        }
        includedOptions = _getOptionsFromSource(
          includeSource,
          pathContext,
          handled: handled,
          optionsCache: optionsCache,
        );

        includedOptions = _rewriteRelativePaths(
          includedOptions,
          pathContext.dirname(includeSource.fullName),
          pathContext,
        );
        if (uri.isScheme('package')) {
          // Cache options only if the URI to the file is a "package:" URI.
          optionsCache[uri] = includedOptions;
        }
      }
      return merge(currentOptions, includedOptions);
    });
    options = merge(includeOptions, options);
    return options;
  }

  /// Walks [options] with semantic knowledge about where paths may appear in an
  /// analysis options file, rewriting relative paths (relative to [directory])
  /// as absolute paths.
  ///
  /// Namely: paths to plugins which are specified by path.
  // TODO(srawlins): I think 'exclude' paths should be made absolute too; I
  // believe there is an existing bug about 'include'd 'exclude' paths.
  YamlMap _rewriteRelativePaths(
    YamlMap options,
    String directory,
    path.Context pathContext,
  ) {
    var pluginsSection = options.valueAt('plugins');
    if (pluginsSection is! YamlMap) return options;
    var plugins = <String, Object>{};
    pluginsSection.nodes.forEach((key, value) {
      if (key is YamlScalar && value is YamlMap) {
        var pathValue = value.valueAt('path')?.value;
        if (pathValue is String) {
          if (pathContext.isRelative(pathValue)) {
            // We need to store the absolute path, before this value is used in
            // a synthetic pub package.
            pathValue = pathContext.join(directory, pathValue);
            pathValue = pathContext.normalize(pathValue);
          }

          plugins[key.value as String] = {'path': pathValue};
        }
      }
    });
    return merge(options, YamlMap.wrap({'plugins': plugins}));
  }
}

/// Thrown on options format exceptions.
class OptionsFormatException implements Exception {
  final String message;
  final SourceSpan? span;
  OptionsFormatException(this.message, [this.span]);

  @override
  String toString() =>
      'OptionsFormatException: ${message.toString()}, ${span?.toString()}';
}

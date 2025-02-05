// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// Provide the options found in the analysis options file.
class AnalysisOptionsProvider {
  /// The source factory used to resolve include declarations
  /// in analysis options files or `null` if include is not supported.
  final SourceFactory? _sourceFactory;

  AnalysisOptionsProvider([this._sourceFactory]);

  /// Provides the analysis options that apply to [root].
  ///
  /// The analysis options come from either [file_paths.analysisOptionsYaml]
  /// found directly in [root] or one of [root]'s ancestor directories.
  ///
  /// Recursively merges options referenced by any 'include' directives
  /// and removes any 'include' directives from the resulting options map.
  /// Returns an empty options map if the file does not exist or cannot be
  /// parsed.
  YamlMap getOptions(Folder root) {
    File? optionsFile = getOptionsFile(root);
    if (optionsFile == null) {
      return YamlMap();
    }
    return getOptionsFromFile(optionsFile);
  }

  /// Returns the analysis options file from which options should be read, or
  /// `null` if there is no analysis options file for code in the given [root].
  ///
  /// The given [root] directory will be searched first. If no file is found,
  /// then enclosing directories will be searched.
  File? getOptionsFile(Folder root) {
    for (var current in root.withAncestors) {
      var file = current.getChildAssumingFile(file_paths.analysisOptionsYaml);
      if (file.exists) {
        return file;
      }
    }
    return null;
  }

  /// Provides the options found in [file].
  ///
  /// Recursively merges options referenced by any 'include' directives
  /// and removes any 'include' directive from the resulting options map.
  /// Returns an empty options map if the file does not exist or cannot be
  /// parsed.
  YamlMap getOptionsFromFile(File file) {
    return getOptionsFromSource(FileSource(file));
  }

  /// Provides the options found in [source].
  ///
  /// Recursively merges options referenced by any `include` directives and
  /// removes any `include` directives from the resulting options map. Returns
  /// an empty options map if the file does not exist or cannot be parsed.
  YamlMap getOptionsFromSource(Source source) {
    try {
      var options = getOptionsFromString(_readAnalysisOptions(source));
      if (_sourceFactory == null) {
        return options;
      }
      var includeValue = options.valueAt(AnalysisOptionsFile.include);
      if (includeValue case YamlScalar(value: String path)) {
        var includeUri = _sourceFactory.resolveUri(source, path);
        if (includeUri != null) {
          options = merge(getOptionsFromSource(includeUri), options);
        }
      } else if (includeValue is YamlList) {
        var includePaths = includeValue.nodes
            .whereType<YamlScalar>()
            .map((e) => e.value)
            .whereType<String>();
        var includeOptions = includePaths.fold(YamlMap(), (options, path) {
          var includeUri = _sourceFactory.resolveUri(source, path);
          if (includeUri == null) {
            // Return the existing options, unchanged.
            return options;
          }
          return merge(options, getOptionsFromSource(includeUri));
        });
        options = merge(includeOptions, options);
      }
      return options;
    } on OptionsFormatException {
      return YamlMap();
    }
  }

  /// Provide the options found in [content].
  ///
  /// An 'include' directive, if present, will be left as-is, and the referenced
  /// options will NOT be merged into the result. Returns an empty options map
  /// if the content is null, or not a YAML map.
  YamlMap getOptionsFromString(String? content) {
    if (content == null) {
      return YamlMap();
    }
    try {
      var doc = loadYamlNode(content);
      return doc is YamlMap ? doc : YamlMap();
    } on YamlException catch (e) {
      throw OptionsFormatException(e.message, e.span);
    } catch (e) {
      throw OptionsFormatException('Unable to parse YAML document.');
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
  ///
  YamlMap merge(YamlMap defaults, YamlMap overrides) =>
      Merger().mergeMap(defaults, overrides);

  /// Read the contents of [source] as a string.
  /// Returns null if source is null or does not exist.
  String? _readAnalysisOptions(Source source) {
    try {
      return source.contents.data;
    } catch (e) {
      // Source can't be read.
      return null;
    }
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

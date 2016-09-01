// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.source.analysis_options_provider;

import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// Provide the options found in the analysis options file.
class AnalysisOptionsProvider {
  /// Provide the options found in either
  /// [root]/[AnalysisEngine.ANALYSIS_OPTIONS_FILE] or
  /// [root]/[AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE].
  /// Return an empty options map if the file does not exist.
  Map<String, YamlNode> getOptions(Folder root, {bool crawlUp: false}) {
    Resource resource;
    for (Folder folder = root; folder != null; folder = folder.parent) {
      resource = folder.getChild(AnalysisEngine.ANALYSIS_OPTIONS_FILE);
      if (resource.exists) {
        break;
      }
      resource = folder.getChild(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
      if (resource.exists || !crawlUp) {
        break;
      }
    }
    String optionsText = _readAnalysisOptionsFile(resource);
    return getOptionsFromString(optionsText);
  }

  /// Provide the options found in [file].
  /// Return an empty options map if the file does not exist.
  Map<String, YamlNode> getOptionsFromFile(File file) {
    var optionsSource = _readAnalysisOptionsFile(file);
    return getOptionsFromString(optionsSource);
  }

  /// Provide the options found in [optionsSource].
  /// Return an empty options map if the source is null.
  Map<String, YamlNode> getOptionsFromString(String optionsSource) {
    Map<String, YamlNode> options = <String, YamlNode>{};
    if (optionsSource == null) {
      return options;
    }

    YamlNode safelyLoadYamlNode() {
      try {
        return loadYamlNode(optionsSource);
      } on YamlException catch (e) {
        throw new OptionsFormatException(e.message, e.span);
      } catch (e) {
        throw new OptionsFormatException('Unable to parse YAML document.');
      }
    }
    YamlNode doc = safelyLoadYamlNode();

    // Empty options.
    if (doc is YamlScalar && doc.value == null) {
      return options;
    }
    if ((doc != null) && (doc is! YamlMap)) {
      throw new OptionsFormatException(
          'Bad options file format (expected map, got ${doc.runtimeType})',
          doc.span);
    }
    if (doc is YamlMap) {
      doc.nodes.forEach((k, YamlNode v) {
        var key;
        if (k is YamlScalar) {
          key = k.value;
        }
        if (key is! String) {
          throw new OptionsFormatException(
              'Bad options file format (expected String scope key, '
              'got ${k.runtimeType})',
              (k ?? doc).span);
        }
        if (v != null && v is! YamlNode) {
          throw new OptionsFormatException(
              'Bad options file format (expected Node value, '
              'got ${v.runtimeType}: `${v.toString()}`)',
              doc.span);
        }
        options[key] = v;
      });
    }
    return options;
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
  Map<String, YamlNode> merge(
          Map<String, YamlNode> defaults, Map<String, YamlNode> overrides) =>
      new Merger().merge(defaults, overrides) as Map<String, YamlNode>;

  /// Read the contents of [file] as a string.
  /// Returns null if file does not exist.
  String _readAnalysisOptionsFile(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
  }
}

/// Thrown on options format exceptions.
class OptionsFormatException implements Exception {
  final String message;
  final SourceSpan span;
  OptionsFormatException(this.message, [this.span]);

  @override
  String toString() =>
      'OptionsFormatException: ${message?.toString()}, ${span?.toString()}';
}

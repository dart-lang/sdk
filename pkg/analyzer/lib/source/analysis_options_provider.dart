// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source.analysis_options_provider;

import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/// Provide the options found in the `.analysis_options` file.
class AnalysisOptionsProvider {
  /// The name of the analysis options source file.
  static const String ANALYSIS_OPTIONS_NAME = '.analysis_options';

  /// Provide the options found in [root]/[ANALYSIS_OPTIONS_NAME].
  /// Return an empty options map if the file does not exist.
  Map<String, YamlNode> getOptions(Folder root) {
    var optionsSource =
        _readAnalysisOptionsFile(root.getChild(ANALYSIS_OPTIONS_NAME));
    return getOptionsFromString(optionsSource);
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
    var options = <String, YamlNode>{};
    if (optionsSource == null) {
      return options;
    }
    var doc = loadYaml(optionsSource);
    if (doc is! YamlMap) {
      throw new Exception(
          'Bad options file format (expected map, got ${doc.runtimeType})');
    }
    if (doc is YamlMap) {
      doc.forEach((k, v) {
        if (k is! String) {
          throw new Exception(
              'Bad options file format (expected String scope key, '
              'got ${k.runtimeType})');
        }
        options[k] = v;
      });
    }
    return options;
  }

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

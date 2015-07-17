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

  /// Provide the options found in the [ANALYSIS_OPTIONS_NAME] file located in
  /// [folder]. Return an empty options map if the file does not exist.
  Map<String, YamlNode> getOptions(Folder root) {
    var options = <String, YamlNode>{};
    var optionsSource = _readAnalysisOptionsFile(root);
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

  /// Read the contents of [root]/[ANALYSIS_OPTIONS_NAME] as a string.
  /// Returns null if file does not exist.
  String _readAnalysisOptionsFile(Folder root) {
    var file = root.getChild(ANALYSIS_OPTIONS_NAME);
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
  }
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:io';

import 'configuration.dart';

/// The manifest that defines the set of supported test [Configuration]s and
/// how they are run on the bots.
class TestMatrix {
  final List<Configuration> configurations;

  /// Reads a test matrix from the file at [path].
  static TestMatrix fromPath(String path) {
    var json = jsonDecode(new File(path).readAsStringSync());
    return fromJson(json as Map<String, dynamic>);
  }

  static TestMatrix fromJson(Map<String, dynamic> json) {
    var configurationsJson = json["configurations"] as Map<String, dynamic>;

    // Keep track of the configurations and which templates they were expanded
    // from.
    var configurations = <Configuration>[];

    configurationsJson.forEach((template, configurationJson) {
      var options = configurationJson["options"] ?? const <String, dynamic>{};

      for (var configuration in Configuration.expandTemplate(
          template, options as Map<String, dynamic>)) {
        for (var existing in configurations) {
          // Make the names don't collide.
          if (configuration.name == existing.name) {
            throw FormatException(
                'Configuration "${configuration.name}" already exists.');
          }

          // Make sure we don't have two equivalent configurations.
          if (configuration.optionsEqual(existing)) {
            throw FormatException(
                'Configuration "${configuration.name}" is identical to '
                '"${existing.name}".');
          }
        }

        configurations.add(configuration);
      }
    });

    return TestMatrix._(configurations);
  }

  TestMatrix._(this.configurations);
}

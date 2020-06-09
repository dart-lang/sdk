// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:io';

import 'builder.dart';
import 'configuration.dart';

/// The manifest that defines the set of supported test [Configuration]s and
/// how they are run on the [Builders]s.
class TestMatrix {
  final List<Configuration> configurations;
  final List<Builder> builders;
  final List<String> branches;

  /// Reads a test matrix from the file at [path].
  static TestMatrix fromPath(String path) {
    var json = jsonDecode(File(path).readAsStringSync());
    return fromJson(json as Map<String, dynamic>);
  }

  static TestMatrix fromJson(Map<String, dynamic> json) {
    var configurationsJson =
        json["configurations"] as Map<String, dynamic> ?? <String, dynamic>{};

    // Keep track of the configurations and which templates they were expanded
    // from.
    var configurations = <Configuration>[];

    configurationsJson.forEach((template, configurationJson) {
      var options = configurationJson["options"] ?? const <String, dynamic>{};

      for (var configuration in Configuration.expandTemplate(
          template, options as Map<String, dynamic>)) {
        for (var existing in configurations) {
          // Make sure the names don't collide.
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

    var builderConfigurations = <Map>[...?json["builder_configurations"]];
    var builders = parseBuilders(builderConfigurations, configurations);
    var branches = <String>[...?json["branches"]];

    // Check that each configuration is tested on at most one builder.
    var testedOn = <Configuration, Builder>{};
    for (var builder in builders) {
      for (var configuration in builder.testedConfigurations) {
        if (testedOn.containsKey(configuration)) {
          var other = testedOn[configuration];
          throw FormatException('Configuration "${configuration.name}" is '
              'tested on both "${builder.name}" and "${other.name}"');
        } else {
          testedOn[configuration] = builder;
        }
      }
    }

    return TestMatrix._(configurations, builders, branches);
  }

  TestMatrix._(this.configurations, this.builders, this.branches);
}

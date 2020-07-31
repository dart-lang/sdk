// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'configuration.dart';

/// A step that is run on a builder to build and test certain configurations of
/// the Dart SDK.
///
/// Each step on a builder runs a script the with provided arguments. If the
/// script is 'tools/test.py' (which is the default if no script is given in
/// the test matrix), or `testRunner == true`, the step is called a 'test
/// step'. Test steps must include the '--named_configuration' (for short
/// '-n') option to select the named [Configuration] to test.
///
/// Test steps are expected to produce test results that are collected during
/// the run of the builder and checked against the expected results to determine
/// the success or failure of the build.
class Step {
  final String name;
  final String script;
  final List<String> arguments;
  final Map<String, String> environment;
  final String fileSet;
  final int shards;
  final bool isTestRunner;
  final Configuration testedConfiguration;

  Step(this.name, String script, this.arguments, this.environment, this.fileSet,
      this.shards, this.isTestRunner, this.testedConfiguration)
      : script = script ?? testScriptName;

  static const testScriptName = "tools/test.py";

  bool get isTestStep => script == testScriptName || isTestRunner;

  /// Create a [Step] from the 'step template' [map], values for supported
  /// variables [configuration], and the list of supported named configurations.
  static Step parse(Map map, Map<String, String> configuration,
      List<Configuration> configurations) {
    var arguments = (map["arguments"] as List ?? [])
        .map((argument) => _expandVariables(argument as String, configuration))
        .toList();
    var testedConfigurations = <Configuration>[];
    var script = map["script"] as String ?? testScriptName;
    var isTestRunner = map["testRunner"] as bool ?? false;
    if (script == testScriptName || isTestRunner) {
      // TODO(karlklose): replace with argument parser that can handle all
      // arguments to test.py.
      for (var argument in arguments) {
        var names = <String>[];
        if (argument.startsWith("--named_configuration")) {
          names.addAll(argument
              .substring("--named_configuration".length)
              .split(",")
              .map((s) => s.trim()));
        } else if (argument.startsWith("-n")) {
          names.addAll(
              argument.substring("-n".length).split(",").map((s) => s.trim()));
        } else {
          continue;
        }
        for (var name in names) {
          var matchingConfigurations =
              configurations.where((c) => c.name == name);
          if (matchingConfigurations.isEmpty) {
            throw FormatException("Undefined configuration: $name");
          }
          testedConfigurations.add(matchingConfigurations.single);
        }
      }
      if (testedConfigurations.length > 1) {
        throw FormatException("Step tests multiple configurations: $arguments");
      }
    }
    return Step(
        map["name"] as String,
        script,
        arguments,
        <String, String>{...?map["environment"]},
        map["fileset"] as String,
        map["shards"] as int,
        isTestRunner,
        testedConfigurations.isEmpty ? null : testedConfigurations.single);
  }
}

/// A builder runs a list of [Step]s to build and test certain configurations of
/// the Dart SDK.
///
/// Groups of builders are defined in the 'builder_configurations' section of
/// the test matrix.
class Builder {
  final String name;
  final String description;
  final List<Step> steps;
  final System system;
  final Mode mode;
  final Architecture arch;
  final Sanitizer sanitizer;
  final Runtime runtime;
  final Set<Configuration> testedConfigurations;

  Builder(this.name, this.description, this.steps, this.system, this.mode,
      this.arch, this.sanitizer, this.runtime, this.testedConfigurations);

  /// Create a [Builder] from its name, a list of 'step templates', the
  /// supported named configurations and a description.
  ///
  /// The 'step templates' can contain the variables `${system}`, `${mode}`,
  /// `${arch}`, and `${runtime}. The values for these variables are inferred
  /// from the builder's name.
  static Builder parse(String builderName, List<Map> steps,
      List<Configuration> configurations, String description) {
    var builderParts = builderName.split("-");
    var systemName = _findPart(builderParts, System.names);
    var modeName = _findPart(builderParts, Mode.names);
    var archName = _findPart(builderParts, Architecture.names);
    var sanitizerName = _findPart(builderParts, Sanitizer.names);
    var runtimeName = _findPart(builderParts, Runtime.names);
    var parsedSteps = steps
        .map((step) => Step.parse(
            step,
            {
              "system": systemName,
              "mode": modeName,
              "arch": archName,
              "sanitizer": sanitizerName,
              "runtime": runtimeName,
            },
            configurations))
        .toList();
    var testedConfigurations = _getTestedConfigurations(parsedSteps);
    return Builder(
        builderName,
        description,
        parsedSteps,
        _findIfNotNull(System.find, systemName),
        _findIfNotNull(Mode.find, modeName),
        _findIfNotNull(Architecture.find, archName),
        _findIfNotNull(Sanitizer.find, sanitizerName),
        _findIfNotNull(Runtime.find, runtimeName),
        testedConfigurations);
  }
}

/// Tries to replace a variable named [variableName] with [value] and throws
/// and exception if the variable is used but `value == null`.
String _tryReplace(String string, String variableName, String value) {
  var variable = "\${$variableName}";
  if (string.contains(variable)) {
    if (value == null) {
      throw FormatException("Undefined value for '$variableName' in '$string'");
    }
    return string.replaceAll(variable, value);
  } else {
    return string;
  }
}

/// Replace the use of supported variable names with the their value given
/// in [values] and throws an exception if an unsupported variable name is used.
String _expandVariables(String string, Map<String, String> values) {
  for (var variable in ["system", "mode", "arch", "sanitizer", "runtime"]) {
    string = _tryReplace(string, variable, values[variable]);
  }
  return string;
}

Set<Configuration> _getTestedConfigurations(List<Step> steps) {
  return steps
      .where((step) => step.isTestStep)
      .map((step) => step.testedConfiguration)
      .toSet();
}

T _findIfNotNull<T>(T Function(String) find, String name) {
  return name != null ? find(name) : null;
}

String _findPart(List<String> builderParts, List<String> parts) {
  return builderParts.firstWhere((part) => parts.contains(part),
      orElse: () => null);
}

List<Builder> parseBuilders(
    List<Map> builderConfigurations, List<Configuration> configurations) {
  var builders = <Builder>[];
  var names = <String>{};
  for (var builderConfiguration in builderConfigurations) {
    var meta = builderConfiguration["meta"] as Map ?? <String, String>{};
    var builderNames = <String>[...?builderConfiguration["builders"]];
    var steps = <Map>[...?builderConfiguration["steps"]];
    for (var builderName in builderNames) {
      if (!names.add(builderName)) {
        throw FormatException('Duplicate builder name: "$builderName"');
      }
      builders.add(Builder.parse(
          builderName, steps, configurations, meta["description"] as String));
    }
  }
  return builders;
}

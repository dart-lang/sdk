// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns the content for an analysis options file, specified appropriately
/// with the given parameter values.
String analysisOptionsContent({
  List<String> includes = const [],
  List<String> experiments = const [],
  List<String> legacyPlugins = const [],
  bool propagateLinterExceptions = true,
  List<String> rules = const [],
  Map<String, Object?> errors = const {},
  bool strictCasts = false,
  bool strictInference = false,
  bool strictRawTypes = false,
  List<String> unignorableNames = const [],
}) {
  var buffer = StringBuffer();

  if (includes.isNotEmpty) {
    buffer.writeln('include:');
    for (var include in includes) {
      buffer.writeln('  - $include');
    }
  }

  final language = strictCasts || strictInference || strictRawTypes;

  if (language ||
      errors.isNotEmpty ||
      unignorableNames.isNotEmpty ||
      legacyPlugins.isNotEmpty ||
      experiments.isNotEmpty ||
      propagateLinterExceptions) {
    buffer.writeln('analyzer:');
  }
  if (experiments.isNotEmpty) {
    buffer.writeln('  enable-experiment:');
    for (var experiment in experiments) {
      buffer.writeln('    - $experiment');
    }
  }

  if (errors.isNotEmpty) {
    buffer.writeln('  errors:');
    for (var error in errors.entries) {
      buffer.writeln('    ${error.key}: ${error.value}');
    }
  }

  if (language) {
    buffer.writeln('  language:');
    if (strictCasts) {
      buffer.writeln('    strict-casts: $strictCasts');
    }
    if (strictInference) {
      buffer.writeln('    strict-inference: $strictInference');
    }
    if (strictRawTypes) {
      buffer.writeln('    strict-raw-types: $strictRawTypes');
    }
  }

  if (unignorableNames.isNotEmpty) {
    buffer.writeln('  cannot-ignore:');
    for (var name in unignorableNames) {
      buffer.writeln('    - $name');
    }
  }

  if (legacyPlugins.isNotEmpty) {
    buffer.writeln('  plugins:');
    for (var plugin in legacyPlugins) {
      buffer.writeln('    - $plugin');
    }
  }

  if (propagateLinterExceptions) {
    buffer.writeln('  optional-checks:');
    buffer.writeln(
      '    propagate-linter-exceptions: $propagateLinterExceptions',
    );
  }

  if (rules.isNotEmpty) {
    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var rule in rules) {
      buffer.writeln('    - $rule');
    }
  }

  return buffer.toString();
}

/// Returns the content for a pubspec file, specified appropriately
/// with the given parameter values.
String pubspecYamlContent({
  String? name,
  String? sdkVersion,
  List<String> dependencies = const [],
}) {
  var buffer = StringBuffer();

  if (name != null) {
    buffer.writeln('name: $name');
  }

  if (sdkVersion != null) {
    buffer.writeln('environment:');
    buffer.writeln("  sdk: '$sdkVersion'");
  }

  if (dependencies.isNotEmpty) {
    buffer.writeln('dependencies:');
    for (var dependency in dependencies) {
      buffer.writeln('  $dependency: any');
    }
  }

  return buffer.toString();
}

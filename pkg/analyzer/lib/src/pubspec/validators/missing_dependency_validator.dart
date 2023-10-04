// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:yaml/yaml.dart';

class MissingDependencyData {
  final List<String> addDeps;
  final List<String> addDevDeps;
  final List<String> removeDevDeps;

  MissingDependencyData(this.addDeps, this.addDevDeps, this.removeDevDeps);
}

/// A validator that computes missing dependencies and dev_dependencies based on
/// the pubspec file and the list of used dependencies and dev_dependencies
///  provided for validation.
class MissingDependencyValidator {
  /// Yaml document being validated
  final Map<dynamic, YamlNode> contents;

  /// The source representing the file being validated.
  final Source source;

  /// The reporter to which errors should be reported.
  late ErrorReporter reporter;

  /// The resource provider used to access the file system.
  final ResourceProvider provider;

  /// The listener to record the errors.
  final RecordingErrorListener recorder;

  MissingDependencyValidator(this.contents, this.source, this.provider)
      : recorder = RecordingErrorListener() {
    reporter = ErrorReporter(recorder, source, isNonNullableByDefault: false);
  }

  /// Given the set of dependencies and dev dependencies used in the sources,
  /// check to see if they are present in the dependencies and dev_dependencies
  /// section of the pubspec.yaml file.
  /// Returns the list of names of the packages to be added/removed for these
  /// sections.
  List<AnalysisError> validate(Set<String> usedDeps, Set<String> usedDevDeps) {
    /// Return a map whose keys are the names of declared dependencies and whose
    /// values are the specifications of those dependencies. The map is extracted
    /// from the given [contents] using the given [key].
    Map<dynamic, YamlNode> getDeclaredDependencies(String key) {
      var field = contents[key];
      if (field == null || (field is YamlScalar && field.value == null)) {
        return <String, YamlNode>{};
      } else if (field is YamlMap) {
        return field.nodes;
      }
      _reportErrorForNode(
          field, PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP, [key]);
      return <String, YamlNode>{};
    }

    final dependencies =
        getDeclaredDependencies(PubspecField.DEPENDENCIES_FIELD);
    final devDependencies =
        getDeclaredDependencies(PubspecField.DEV_DEPENDENCIES_FIELD);

    var availableDeps = [
      if (dependencies.isNotEmpty)
        for (var dep in dependencies.entries) dep.key.toString()
    ];
    var availableDevDeps = [
      if (devDependencies.isNotEmpty)
        for (var dep in devDependencies.entries) dep.key.toString(),
    ];

    var addDeps = <String>[];
    var addDevDeps = <String>[];
    var removeDevDeps = <String>[];
    for (var name in usedDeps) {
      if (!availableDeps.contains(name)) {
        addDeps.add(name);
        if (availableDevDeps.contains(name)) {
          removeDevDeps.add(name);
        }
      }
    }
    for (var name in usedDevDeps) {
      if (!availableDevDeps.contains(name)) {
        addDevDeps.add(name);
      }
    }
    var message = addDeps.isNotEmpty
        ? "${addDeps.map((s) => "'$s'").join(',')} in 'dependencies'"
        : '';
    if (addDevDeps.isNotEmpty) {
      message = message.isNotEmpty ? '$message,' : message;
      message =
          "$message ${addDevDeps.map((s) => "'$s'").join(',')} in 'dev_dependencies'";
    }
    if (addDeps.isNotEmpty || addDevDeps.isNotEmpty) {
      _reportErrorForNode(
          contents.values.first,
          PubspecWarningCode.MISSING_DEPENDENCY,
          [message],
          [],
          MissingDependencyData(addDeps, addDevDeps, removeDevDeps));
    }
    return recorder.errors;
  }

  /// Report an error for the given node.
  void _reportErrorForNode(
    YamlNode node,
    ErrorCode errorCode, [
    List<Object>? arguments,
    List<DiagnosticMessage>? messages,
    Object? data,
  ]) {
    final span = node.span;
    reporter.reportErrorForOffset(
      errorCode,
      span.start.offset,
      span.length,
      arguments,
      messages,
      data,
    );
  }
}

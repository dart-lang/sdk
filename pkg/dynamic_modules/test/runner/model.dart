// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// Data needed to build and run a single dynamic module test.
class DynamicModuleTest {
  /// Name of the test. Matches the folder containing the test.
  final String name;

  /// Absolute path to the test folder.
  final Uri folder;

  /// Entrypoint of the original application, relative to the test folder.
  /// All shared code
  /// must be reachable from it.
  final String main;

  /// Location of the dynamic_interface.yaml declaration.
  final String interface;

  /// Entrypoint for each dynamic module, keyed by name.
  final Map<String, String> dynamicModules;

  DynamicModuleTest(
    this.name,
    this.folder,
    this.main,
    this.interface,
    this.dynamicModules,
  );
}

/// Result of an individual module test.
class DynamicModuleTestResult {
  final String name;
  final Status status;
  final String details;
  final Duration time;

  DynamicModuleTestResult._(this.name, this.status, this.details, this.time);

  factory DynamicModuleTestResult.pass(DynamicModuleTest test, Duration time) =>
      DynamicModuleTestResult._(test.name, Status.pass, '', time);

  factory DynamicModuleTestResult.compileError(
    DynamicModuleTest test,
    String details,
    Duration time,
  ) => DynamicModuleTestResult._(
    test.name,
    Status.compileTimeError,
    details,
    time,
  );

  factory DynamicModuleTestResult.runtimeError(
    DynamicModuleTest test,
    String details,
    Duration time,
  ) => DynamicModuleTestResult._(test.name, Status.runtimeError, details, time);

  /// Emit the result in the JSON format expected by the test infrastructure.
  String toRecordJson(String configuration) {
    final outcome = switch (status) {
      Status.pass => 'Pass',
      Status.compileTimeError => 'CompileTimeError',
      Status.runtimeError => 'RuntimeError',
    };
    return jsonEncode({
      'name': 'dynamic_modules_suite/$name',
      'configuration': configuration,
      'suite': 'dynamic_modules_suite',
      'test_name': name,
      'time_ms': time.inMilliseconds,
      'expected': 'Pass',
      'result': outcome,
      'matches': status == Status.pass,
    });
  }

  /// Emit the log entry with details of a failure in the JSON format expected
  /// by the test infrastructure.
  String toLogJson(String configuration) {
    final outcome = switch (status) {
      Status.pass => 'Pass',
      Status.compileTimeError => 'CompileTimeError',
      Status.runtimeError => 'RuntimeError',
    };
    return jsonEncode({
      'name': 'dynamic_modules_suite/$name',
      'configuration': configuration,
      'result': outcome,
      'log': details,
    });
  }
}

enum Status { pass, compileTimeError, runtimeError }

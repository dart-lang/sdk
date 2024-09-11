// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
      this.name, this.folder, this.main, this.interface, this.dynamicModules);
}

/// Result of an individual module test.
class DynamicModuleTestResult {
  final String name;
  final Status status;
  final String details;

  DynamicModuleTestResult._(this.name, this.status, this.details);

  factory DynamicModuleTestResult.pass(DynamicModuleTest test) =>
      DynamicModuleTestResult._(test.name, Status.pass, '');

  factory DynamicModuleTestResult.compileError(
          DynamicModuleTest test, String details) =>
      DynamicModuleTestResult._(test.name, Status.compileTimeError, details);

  factory DynamicModuleTestResult.runtimeError(
          DynamicModuleTest test, String details) =>
      DynamicModuleTestResult._(test.name, Status.runtimeError, details);
}

enum Status { pass, compileTimeError, runtimeError }

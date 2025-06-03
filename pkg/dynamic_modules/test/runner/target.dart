// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines how dynamic modules get compiled and executed on each target
/// platform.
library;

import 'model.dart';

/// Possible backends where the tests can be executed.
enum Target { aot, jit, dart2wasm, ddc }

/// Defines how to build and run a test in a specific target.
///
/// The test framework will use a single executor for all tests in a suite. This
/// can be leveraged to keep compilers warm and cache results if that is
/// helpful.
abstract class TargetExecutor {
  /// Takes the steps necessary to build the initial version of the app.
  Future compileApplication(DynamicModuleTest test);

  /// Takes the steps necessary to build a single dynamic module.
  Future compileDynamicModule(DynamicModuleTest test, String name);

  /// Takes the steps necessary to execute the test.
  ///
  /// This step will only be called after both the app and modules have been
  /// generated.
  Future executeApplication(DynamicModuleTest test);

  /// Notification that all tests have been executed and that this executor is
  /// no longer going to be used anymore.
  Future suiteComplete();
}

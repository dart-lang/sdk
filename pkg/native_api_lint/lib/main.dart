// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entry point for the `native_api_lint` analyzer plugin.
///
/// This file is the plugin's declared entry point (see `pubspec.yaml`).
/// The analysis server loads it and calls [plugin].register() to register
/// all lint rules.
///
/// To enable this plugin in a Flutter project, add to `analysis_options.yaml`:
/// ```yaml
/// analyzer:
///   plugins:
///     - native_api_lint
///
/// # Optional: override the auto-detected deployment targets.
/// native_api_lint:
///   ios_min: '14.0'
///   macos_min: '11.0'
/// ```
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/api_deprecated_on_target.dart';
import 'src/rules/api_not_available_on_min_target.dart';

/// The singleton plugin instance discovered by the analysis server.
final Plugin plugin = NativeApiLintPlugin();

/// Plugin that provides OS-level API compatibility linting for FFIgen-generated
/// native interop bindings.
///
/// Registered rules:
/// - [ApiNotAvailableOnMinTargetRule] — warns when a native API requires a
///   newer OS version than the project's minimum deployment target.
/// - [ApiDeprecatedOnTargetRule] — informs when a native API is deprecated
///   on the project's minimum deployment target.
class NativeApiLintPlugin extends Plugin {
  @override
  String get name => 'native_api_lint';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(ApiNotAvailableOnMinTargetRule());
    registry.registerLintRule(ApiDeprecatedOnTargetRule());
  }
}

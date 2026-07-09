// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_util.dart';

/// Get the file system location for storing global data on the users' system.
///
/// The directory follows OS defaults and is not backed up or synchronized
/// across devices by the OS.
///
/// The [packageName] must be a valid Dart package name. Prefer using the name
/// of the package calling this function to avoid name clashes.
///
/// If provided, [environment] is used for environment variables. Otherwise,
/// [Platform.environment] is used.
///
/// The directory location depends on the current [Platform.operatingSystem]:
/// - on **Windows**:
///   - `%LOCALAPPDATA%\Dart\<packageName>`
/// - on **Mac OS**:
///   - `$HOME/Library/Application Support/Dart/<packageName>`
/// - on **Linux**:
///   - `$XDG_STATE_HOME/Dart/<packageName>` if `$XDG_STATE_HOME` is defined,
///     and
///   - `$HOME/.local/state/Dart/<packageName>` otherwise.
///
/// The Dart data home can be overridden with the `DART_DATA_HOME` environment
/// variable.
///
/// The directory won't be created, this method merely returns the recommended
/// location.
String getDartDataHome(String packageName, {Map<String, String>? environment}) {
  environment ??= Platform.environment;
  final overridden = environment['DART_DATA_HOME'];
  final Directory dartDataHome;
  if (overridden != null) {
    dartDataHome = Directory(overridden);
  } else {
    final dartBaseDirectories = BaseDirectories(
      'Dart',
      environment: environment,
    );
    // Use 'state', not 'data': Don't synchronize across devices.
    dartDataHome = Directory(dartBaseDirectories.stateHome);
  }
  return dartDataHome.uri.resolve('$packageName/').toFilePath();
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// A class to represent a SDK configuration file.
///
/// This file may or may not be present in a Dart SDK. If it exists, the values
/// in it can be used to configure the SDK for specific environments, like
/// google3. This file generally lives in `<dart-sdk>/config/settings.json`.
class SdkConfiguration {
  final Map<String, dynamic> _values = {};

  SdkConfiguration.readFromFile(File file) {
    if (!file.existsSync()) {
      throw '$file not found';
    }

    _readFromFile(file);
  }

  /// Create an SDK configuration based on any SDK configuration file at
  /// <dart-sdk>/config/settings.json.
  ///
  /// This constructor will still create an object even if a configuration file
  /// is not found.
  SdkConfiguration.readFromSdk() {
    // <dart-sdk>/config/settings.json:
    final sdkDir =
        Directory(path.dirname(path.dirname(Platform.resolvedExecutable)));
    final configFile = File(path.join(sdkDir.path, 'config', 'settings.json'));

    if (configFile.existsSync()) {
      _readFromFile(configFile);
    }
  }

  /// Whether analytics is forced on.
  bool get analyticsForceEnabled => _values['server.analytics.forceEnabled'];

  /// Return a override value for the analysis server's google analytics ID.
  String get analyticsId => _values['server.analytics.id'];

  /// Whether crash reporting is forced on.
  bool get crashReportingForceEnabled =>
      _values['server.crash.reporting.forceEnabled'];

  /// Return a override value for the analysis server's crash reporting product
  /// ID.
  String get crashReportingId => _values['server.crash.reporting.id'];

  /// Return a string describing the contents of this SDK configuration.
  String get displayString {
    return _values.keys.map((key) => '$key: ${_values[key]}').join(('\n'));
  }

  /// Returns whether this SDK configuration has any configured values.
  bool get hasAnyOverrides => _values.isNotEmpty;

  @override
  String toString() => displayString;

  void _readFromFile(File file) {
    try {
      Map m = jsonDecode(file.readAsStringSync());
      for (var key in m.keys) {
        _values[key] = m[key];
      }
    } catch (_) {
      // ignore issues reading the file
    }
  }
}

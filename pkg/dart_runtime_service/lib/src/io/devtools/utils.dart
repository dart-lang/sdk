// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Utility methods used by DevTools and DTD integrations.
abstract final class DevToolsUtils {
  DevToolsUtils._();

  static const _kVersionFile = 'version.json';
  static const _kVersionKey = 'version';
  static const _kUnknownVersion = 'unknown';

  /// Reads the version string from `version.json` in [devToolsDir].
  static Future<String> getVersion(String devToolsDir) async {
    try {
      final versionFile = File(path.join(devToolsDir, _kVersionFile));
      final decoded = jsonDecode(await versionFile.readAsString());
      if (decoded case {_kVersionKey: final String version}) {
        return version;
      }
      return _kUnknownVersion;
    } on FileSystemException {
      return _kUnknownVersion;
    } on FormatException {
      return _kUnknownVersion;
    }
  }

  /// Prints output either as a structured JSON string when [machineMode] is
  /// true, or as a human-readable plain text [message] otherwise.
  ///
  /// [message] provides the formatted string to output when running in standard
  /// CLI mode (e.g. "Serving the Dart Tooling Daemon at http://...").
  /// [json] provides the structured event/data payload serialized when running in
  /// machine mode (`--machine`).
  static void printOutput(
    String? message,
    Object json, {
    required bool machineMode,
  }) {
    final output = machineMode ? jsonEncode(json) : message;
    if (output != null) {
      print(output);
    }
  }
}

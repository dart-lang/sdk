// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';

abstract class DevToolsUtils {
  static Future<VmService?> connectToVmService(Uri theUri) async {
    // Fix up the various acceptable URI formats into a WebSocket URI to connect.
    final uri = convertToWebSocketUrl(serviceProtocolUrl: theUri);

    try {
      final WebSocket ws = await WebSocket.connect(uri.toString());

      final VmService service = VmService(
        ws.asBroadcastStream(),
        (String message) => ws.add(message),
      );

      return service;
    } catch (_) {
      print('ERROR: Unable to connect to VMService $theUri');
      return null;
    }
  }

  static Future<String> getVersion(String devToolsDir) async {
    try {
      final versionFile = File(path.join(devToolsDir, 'version.json'));
      final decoded = jsonDecode(await versionFile.readAsString());
      return decoded['version'] ?? 'unknown';
    } on FileSystemException {
      return 'unknown';
    }
  }

  /// Provides an instance of [Analytics] with the Dart SDK version and Flutter
  /// version and channel if running the dart executable shipped with Flutter.
  static Analytics initializeAnalytics() {
    // Use helper method from package:unified_analytics to return
    // a cleaned dart sdk verison
    final dartVersion = parseDartSDKVersion(Platform.version);

    // The location for the dart executable in the following path
    //  /path/to/dart-sdk/bin/dart
    final dartExecutableFile = File(Platform.resolvedExecutable);

    // The flutter version file can also be found if we are running the
    // dart sdk that is shipped with flutter in the following path
    //  /path/to/flutter/bin/cache/dart-sdk/bin/dart
    final flutterVersionFile = File(path.join(
        dartExecutableFile.parent.path, '..', '..', 'flutter.version.json'));

    // These fields are defined as nullable incase the dart sdk being run
    // is not the sdk shipped with flutter
    String? flutterChannel;
    String? flutterVersion;

    // If the dart sdk being used is vendored with the flutter sdk, we can
    // expect this file to exist
    if (flutterVersionFile.existsSync()) {
      try {
        final flutterObj = jsonDecode(flutterVersionFile.readAsStringSync())
            as Map<String, Object?>;
        flutterChannel = flutterObj['channel'] as String?;
        flutterVersion = flutterObj['frameworkVersion'] as String?;
      } catch (_) {
        // Leave the flutter channel and version info null
      }
    }

    return Analytics(
      tool: DashTool.devtools,
      dartVersion: dartVersion,
      // TODO(eliasyishak): pass this information (https://github.com/flutter/devtools/issues/7230)
      // clientIde: 'TBD',
      flutterChannel: flutterChannel,
      flutterVersion: flutterVersion,
    );
  }

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

extension SafeAccessList<T> on List<T> {
  T? safeGet(int index) => index < 0 || index >= length ? null : this[index];
}

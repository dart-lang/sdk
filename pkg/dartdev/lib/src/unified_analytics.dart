// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:telemetry/telemetry.dart' as telemetry show isRunningOnBot;
import 'package:unified_analytics/unified_analytics.dart';

import 'sdk.dart';

const String _dartDirectoryName = '.dart';

const String analyticsDisabledNoticeMessage =
    'Analytics reporting disabled. In order to enable it, run: dart --enable-analytics';

/// Create the `Analytics` instance to be used to report analytics.
Analytics createUnifiedAnalytics({bool disableAnalytics = false}) {
  if (disableAnalytics) {
    return NoOpAnalytics();
  }
  return Analytics(
    tool: DashTool.dartTool,
    dartVersion: Runtime.runtime.version,
  );
}

String userHomeDir() {
  var envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  var value = Platform.environment[envKey];
  return value ?? '.';
}

/// Return the user's home directory for the current platform.
Directory? get homeDir {
  var dir = Directory(userHomeDir());
  return dir.existsSync() ? dir : null;
}

/// The directory used to store the analytics settings file.
///
/// Typically, the directory is `~/.dart/` (and the settings file is
/// `dartdev.json`).
///
/// This can return null under some conditions, including when the user's home
/// directory does not exist.
Directory? getDartStorageDirectory() {
  var dir = homeDir;
  if (dir == null) {
    return null;
  } else {
    return Directory(path.join(dir.path, _dartDirectoryName));
  }
}

/// The method used by dartdev to determine if this machine is a bot such as a
/// CI machine.
bool isBot() => telemetry.isRunningOnBot();

// Matches file:/, non-ws, /, non-ws, .dart
final RegExp _pathRegex = RegExp(r'file:/\S+/(\S+\.dart)');

// Match multiple tabs or spaces.
final RegExp _tabOrSpaceRegex = RegExp(r'[\t ]+');

/// Sanitize a stacktrace. This will shorten file paths in order to remove any
/// PII that may be contained in the full file path. For example, this will
/// shorten `file:///Users/foobar/tmp/error.dart` to `error.dart`.
///
/// If [shorten] is `true`, this method will also attempt to compress the text
/// of the stacktrace. GA has a 100 char limit on the text that can be sent for
/// an exception. This will try and make those first 100 chars contain
/// information useful to debugging the issue.
String sanitizeStacktrace(dynamic st, {bool shorten = true}) {
  var str = '$st';

  Iterable<Match> iter = _pathRegex.allMatches(str);
  iter = iter.toList().reversed;

  for (var match in iter) {
    var replacement = match.group(1)!;
    str =
        str.substring(0, match.start) + replacement + str.substring(match.end);
  }

  if (shorten) {
    // Shorten the stacktrace up a bit.
    str = str.replaceAll(_tabOrSpaceRegex, ' ');
  }

  return str;
}

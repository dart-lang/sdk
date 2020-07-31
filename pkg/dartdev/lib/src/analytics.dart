// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:telemetry/telemetry.dart' as telemetry show isRunningOnBot;
import 'package:usage/src/usage_impl.dart';
import 'package:usage/src/usage_impl_io.dart';
import 'package:usage/usage_io.dart';

const String analyticsNoticeOnFirstRunMessage = '''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ The Dart tool uses Google Analytics to anonymously report feature usage    ║
  ║ statistics, and crash reporting to send basic crash reports. This data is  ║
  ║ used to help improve the Dart platform and tools over time.                ║
  ║                                                                            ║
  ║ To disable reporting of anonymous tool usage statistics in general, run    ║
  ║ the command: `dart --disable-analytics`.                                   ║
  ╚════════════════════════════════════════════════════════════════════════════╝
''';
const String analyticsDisabledNoticeMessage = '''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ Anonymous analytics disabled. To enable again, run the command:            ║
  ║ `dart --enable-analytics`                                                  ║
  ╚════════════════════════════════════════════════════════════════════════════╝
''';
const String _unknownCommand = '<unknown>';
const String _appName = 'dartdev';
const String _dartDirectoryName = '.dart';
const String _settingsFileName = 'dartdev.json';
const String _trackingId = 'UA-26406144-37';

const String eventCategory = 'dartdev';
const String exitCodeParam = 'exitCode';
const String flagsParam = 'flags';

Analytics instance;

/// Create and return an [Analytics] instance, this value is cached and returned
/// on subsequent calls.
Analytics createAnalyticsInstance(bool disableAnalytics) {
  if (instance != null) {
    return instance;
  }

  // Dartdev tests pass a hidden 'disable-dartdev-analytics' flag which is
  // handled here
  if (disableAnalytics) {
    instance = DisabledAnalytics(_trackingId, _appName);
    return instance;
  }

  var settingsDir = getDartStorageDirectory();
  if (settingsDir == null) {
    // Some systems don't support user home directories; for those, fail
    // gracefully by returning a disabled analytics object.
    instance = DisabledAnalytics(_trackingId, _appName);
    return instance;
  }

  if (!settingsDir.existsSync()) {
    try {
      settingsDir.createSync();
    } catch (e) {
      // If we can't create the directory for the analytics settings, fail
      // gracefully by returning a disabled analytics object.
      instance = DisabledAnalytics(_trackingId, _appName);
      return instance;
    }
  }

  var settingsFile = File(path.join(settingsDir.path, _settingsFileName));
  instance = DartdevAnalytics(_trackingId, settingsFile, _appName);
  return instance;
}

/// Return the first member from [args] that occurs in [allCommands], otherwise
/// '<unknown>' is returned.
///
/// 'help' is special cased to have 'dart analyze help', 'dart help analyze',
/// and 'dart analyze --help' all be recorded as a call to 'help' instead of
/// 'help' and 'analyze'.
String getCommandStr(List<String> args, List<String> allCommands) {
  if (args.contains('help') || args.contains('-h') || args.contains('--help')) {
    return 'help';
  }
  return args.firstWhere((arg) => allCommands.contains(arg),
      orElse: () => _unknownCommand);
}

/// Given some set of arguments and parameters, this returns a proper subset
/// of the arguments that start with '-', joined by a space character.
String getFlags(List<String> args) {
  if (args == null || args.isEmpty) {
    return '';
  }
  var argSubset = <String>[];
  for (var arg in args) {
    if (arg.startsWith('-')) {
      if (arg.contains('=')) {
        argSubset.add(arg.substring(0, arg.indexOf('=') + 1));
      } else {
        argSubset.add(arg);
      }
    }
  }
  return argSubset.join(' ');
}

/// The directory used to store the analytics settings file.
///
/// Typically, the directory is `~/.dart/` (and the settings file is
/// `dartdev.json`).
///
/// This can return null under some conditions, including when the user's home
/// directory does not exist.
Directory getDartStorageDirectory() {
  var homeDir = Directory(userHomeDir());
  if (!homeDir.existsSync()) {
    return null;
  }
  return Directory(path.join(homeDir.path, _dartDirectoryName));
}

class DartdevAnalytics extends AnalyticsImpl {
  DartdevAnalytics(String trackingId, File settingsFile, String appName)
      : super(
          trackingId,
          IOPersistentProperties.fromFile(settingsFile),
          IOPostHandler(),
          applicationName: appName,
          applicationVersion: getDartVersion(),
        );

  @override
  bool get enabled {
    if (telemetry.isRunningOnBot()) {
      return false;
    }

    // If there's no explicit setting (enabled or disabled) then we don't send.
    return (properties['enabled'] as bool) ?? false;
  }
}

class DisabledAnalytics extends AnalyticsMock {
  @override
  final String trackingId;
  @override
  final String applicationName;

  DisabledAnalytics(this.trackingId, this.applicationName);

  @override
  bool get enabled => false;

  @override
  bool get firstRun => false;
}

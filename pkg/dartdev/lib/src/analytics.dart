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
const String _appName = 'dartdev';
const String _dartDirectoryName = '.dart';
const String _settingsFileName = 'dartdev.json';
const String _trackingId = 'UA-26406144-37';
const String _readmeFileName = 'README.txt';
const String _readmeFileContents = '''
The present directory contains user-level settings for the
Dart programming language (https://dart.dev).
''';

const String eventCategory = 'dartdev';
const String exitCodeParam = 'exitCode';

Analytics _instance;

Analytics get analyticsInstance => _instance;

/// Create and return an [Analytics] instance, this value is cached and returned
/// on subsequent calls.
Analytics createAnalyticsInstance(bool disableAnalytics) {
  if (_instance != null) {
    return _instance;
  }

  // Dartdev tests pass a hidden 'disable-dartdev-analytics' flag which is
  // handled here.
  // Also, stdout.hasTerminal is checked, if there is no terminal we infer that
  // a machine is running dartdev so we return analytics shouldn't be set.
  if (disableAnalytics) {
    _instance = DisabledAnalytics(_trackingId, _appName);
    return _instance;
  }

  var settingsDir = getDartStorageDirectory();
  if (settingsDir == null) {
    // Some systems don't support user home directories; for those, fail
    // gracefully by returning a disabled analytics object.
    _instance = DisabledAnalytics(_trackingId, _appName);
    return _instance;
  }

  if (!settingsDir.existsSync()) {
    try {
      settingsDir.createSync();
    } catch (e) {
      // If we can't create the directory for the analytics settings, fail
      // gracefully by returning a disabled analytics object.
      _instance = DisabledAnalytics(_trackingId, _appName);
      return _instance;
    }
  }

  var readmeFile =
      File('${settingsDir.absolute.path}${path.separator}$_readmeFileName');
  if (!readmeFile.existsSync()) {
    readmeFile.createSync();
    readmeFile.writeAsStringSync(_readmeFileContents);
  }

  var settingsFile = File(path.join(settingsDir.path, _settingsFileName));
  _instance = DartdevAnalytics(_trackingId, settingsFile, _appName);
  return _instance;
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

/// The method used by dartdev to determine if this machine is a bot such as a
/// CI machine.
bool isBot() => telemetry.isRunningOnBot();

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
    // Don't enable if the user hasn't been shown the disclosure or if this
    // machine is bot.
    if (!disclosureShownOnTerminal || isBot()) {
      return false;
    }

    // If there's no explicit setting (enabled or disabled) then we don't send.
    return (properties['enabled'] as bool) ?? false;
  }

  bool get disclosureShownOnTerminal =>
      (properties['disclosureShown'] as bool) ?? false;

  set disclosureShownOnTerminal(bool value) {
    properties['disclosureShown'] = value;
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

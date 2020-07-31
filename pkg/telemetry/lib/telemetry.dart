// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:usage/src/usage_impl.dart';
import 'package:usage/src/usage_impl_io.dart';
import 'package:usage/src/usage_impl_io.dart' as usage_io show getDartVersion;
import 'package:usage/usage.dart';
import 'package:usage/usage_io.dart';

export 'package:usage/usage.dart' show Analytics;

// TODO(devoncarew): Don't show the UI until we're ready to ship.
final bool SHOW_ANALYTICS_UI = false;

final String _dartDirectoryName = '.dart';
final String _settingsFileName = 'analytics.json';

/// Dart SDK tools with analytics should display this notice.
///
/// In addition, they should support displaying the analytics' status, and have
/// a flag to toggle analytics. This may look something like:
///
/// `Analytics are currently enabled (and can be disabled with --no-analytics).`
final String analyticsNotice =
    "Dart SDK tools anonymously report feature usage statistics and basic crash\n"
    "reports to help improve Dart tools over time. See Google's privacy policy:\n"
    "https://www.google.com/intl/en/policies/privacy/.";

/// Return a customized message for command-line tools to display about the
/// state of analytics, and how users can enabled or disable analytics.
///
/// An example return value might be `'Analytics are currently enabled (and can
/// be disabled with --no-analytics).'`
String createAnalyticsStatusMessage(
  bool enabled, {
  String command: 'analytics',
}) {
  String currentState = enabled ? 'enabled' : 'disabled';
  String toggleState = enabled ? 'disabled' : 'enabled';
  String commandToggle = enabled ? 'no-$command' : command;

  return 'Analytics are currently $currentState '
      '(and can be $toggleState with --$commandToggle).';
}

/// Create an [Analytics] instance with the given trackingID and
/// applicationName.
///
/// This analytics instance will share a common enablement state with the rest
/// of the Dart SDK tools.
Analytics createAnalyticsInstance(
  String trackingId,
  String applicationName, {
  bool disableForSession = false,
  bool forceEnabled = false,
}) {
  Directory dir = getDartStorageDirectory();
  if (dir == null) {
    // Some systems don't support user home directories; for those, fail
    // gracefully by returning a disabled analytics object.
    return new _DisabledAnalytics(trackingId, applicationName);
  }

  if (!dir.existsSync()) {
    try {
      dir.createSync();
    } catch (e) {
      // If we can't create the directory for the analytics settings, fail
      // gracefully by returning a disabled analytics object.
      return new _DisabledAnalytics(trackingId, applicationName);
    }
  }

  File settingsFile = new File(path.join(dir.path, _settingsFileName));
  return new _TelemetryAnalytics(
    trackingId,
    applicationName,
    getDartVersion(),
    settingsFile,
    disableForSession: disableForSession,
    forceEnabled: forceEnabled,
  );
}

/// The directory used to store the analytics settings file.
///
/// Typically, the directory is `~/.dart/` (and the settings file is
/// `analytics.json`).
///
/// This can return null under some conditions, including when the user's home
/// directory does not exist.
@visibleForTesting
Directory getDartStorageDirectory() {
  Directory homeDirectory = new Directory(userHomeDir());
  if (!homeDirectory.existsSync()) return null;

  return new Directory(path.join(homeDirectory.path, _dartDirectoryName));
}

/// Return the version of the Dart SDK.
String getDartVersion() => usage_io.getDartVersion();

class _TelemetryAnalytics extends AnalyticsImpl {
  final bool disableForSession;
  final bool forceEnabled;

  _TelemetryAnalytics(
    String trackingId,
    String applicationName,
    String applicationVersion,
    File settingsFile, {
    @required this.disableForSession,
    @required this.forceEnabled,
  }) : super(
          trackingId,
          new IOPersistentProperties.fromFile(settingsFile),
          new IOPostHandler(),
          applicationName: applicationName,
          applicationVersion: applicationVersion,
        ) {
    final String locale = getPlatformLocale();
    if (locale != null) {
      setSessionValue('ul', locale);
    }
  }

  @override
  bool get enabled {
    if (disableForSession || isRunningOnBot()) {
      return false;
    }

    // This is only used in special cases.
    if (forceEnabled) {
      return true;
    }

    // If there's no explicit setting (enabled or disabled) then we don't send.
    return (properties['enabled'] as bool) ?? false;
  }
}

class _DisabledAnalytics extends AnalyticsMock {
  @override
  final String trackingId;
  @override
  final String applicationName;

  _DisabledAnalytics(this.trackingId, this.applicationName);

  @override
  bool get enabled => false;
}

/// Detect whether we're running on a bot or in a continuous testing
/// environment.
///
/// We should periodically keep this code up to date with:
/// https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/base/bot_detector.dart#L30
/// and
/// https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/reporting/usage.dart#L200.
bool isRunningOnBot() {
  final Map<String, String> env = Platform.environment;

  if (
      // Explicitly stated to not be a bot.
      env['BOT'] == 'false'
          // Set by the IDEs to the IDE name, so a strong signal that this is not a bot.
          ||
          env.containsKey('FLUTTER_HOST')
          // When set, GA logs to a local file (normally for tests) so we don't need to filter.
          ||
          env.containsKey('FLUTTER_ANALYTICS_LOG_FILE')) {
    return false;
  }

  return env.containsKey('BOT')
      // https://docs.travis-ci.com/user/environment-variables/
      // Example .travis.yml file: https://github.com/flutter/devtools/blob/master/.travis.yml
      ||
      env['TRAVIS'] == 'true' ||
      env['CONTINUOUS_INTEGRATION'] == 'true' ||
      env.containsKey('CI') // Travis and AppVeyor

      // https://www.appveyor.com/docs/environment-variables/
      ||
      env.containsKey('APPVEYOR')

      // https://cirrus-ci.org/guide/writing-tasks/#environment-variables
      ||
      env.containsKey('CIRRUS_CI')

      // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
      ||
      (env.containsKey('AWS_REGION') && env.containsKey('CODEBUILD_INITIATOR'))

      // https://wiki.jenkins.io/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-belowJenkinsSetEnvironmentVariables
      ||
      env.containsKey('JENKINS_URL')

      // https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables
      ||
      env.containsKey('GITHUB_ACTIONS')

      // Properties on Flutter's Chrome Infra bots.
      ||
      env['CHROME_HEADLESS'] == '1' ||
      env.containsKey('BUILDBOT_BUILDERNAME') ||
      env.containsKey('SWARMING_TASK_ID')

      // Property when running on borg.
      ||
      env.containsKey('BORG_ALLOC_DIR');

  // TODO(jwren): Azure detection -- each call for this detection requires an
  //  http connection, the flutter cli tool captures the result on the first
  //  run, we should consider the same caching here.
}

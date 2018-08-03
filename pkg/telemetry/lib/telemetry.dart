// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

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
_TelemetryAnalytics createAnalyticsInstance(
  String trackingId,
  String applicationName, {
  bool disableForSession: false,
}) {
  Directory dir = getDartStorageDirectory();
  if (!dir.existsSync()) {
    dir.createSync();
  }

  File file = new File(path.join(dir.path, _settingsFileName));
  return new _TelemetryAnalytics(
      trackingId, applicationName, getDartVersion(), file, disableForSession);
}

/// The directory used to store the analytics settings file.
///
/// Typically, the directory is `~/.dart/` (and the settings file is
/// `analytics.json`).
Directory getDartStorageDirectory() {
  return new Directory(path.join(userHomeDir(), _dartDirectoryName));
}

/// Return the version of the Dart SDK.
String getDartVersion() => usage_io.getDartVersion();

class _TelemetryAnalytics extends AnalyticsImpl {
  final bool disableForSession;

  _TelemetryAnalytics(
    String trackingId,
    String applicationName,
    String applicationVersion,
    File file,
    this.disableForSession,
  ) : super(
          trackingId,
          new IOPersistentProperties.fromFile(file),
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

    // If there's no explicit setting (enabled or disabled) then we don't send.
    return (properties['enabled'] as bool) ?? false;
  }
}

bool isRunningOnBot() {
  final Map<String, String> env = Platform.environment;

  return env['BOT'] != 'false' &&
      (env['BOT'] == 'true'
          // https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
          ||
          env['TRAVIS'] == 'true' ||
          env['CONTINUOUS_INTEGRATION'] == 'true' ||
          env.containsKey('CI') // Travis and AppVeyor

          // https://www.appveyor.com/docs/environment-variables/
          ||
          env.containsKey('APPVEYOR')

          // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
          ||
          (env.containsKey('AWS_REGION') &&
              env.containsKey('CODEBUILD_INITIATOR'))

          // https://wiki.jenkins.io/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-belowJenkinsSetEnvironmentVariables
          ||
          env.containsKey('JENKINS_URL')

          // Properties on Flutter's Chrome Infra bots.
          ||
          env['CHROME_HEADLESS'] == '1' ||
          env.containsKey('BUILDBOT_BUILDERNAME'));
}

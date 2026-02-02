// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unified_analytics/unified_analytics.dart';

import 'sdk.dart';

const String _dartDirectoryName = '.dart';

const String analyticsDisabledNoticeMessage =
    'Analytics reporting disabled. '
    'In order to enable it, run: dart --enable-analytics';

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
bool isBot() => _isRunningOnBot();

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

/// Detect whether we're running on a bot / a continuous testing environment.
///
/// We should periodically keep this code up to date with:
/// https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/base/bot_detector.dart#L30
/// and
/// https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/reporting/usage.dart#L200.
bool _isRunningOnBot() {
  final Map<String, String> env = Platform.environment;

  if (
  // Explicitly stated to not be a bot.
  env['BOT'] == 'false'
      // Set by the IDEs to the IDE name, so a strong signal that this is
      // not a bot.
      ||
      env.containsKey('FLUTTER_HOST')
      // When set, GA logs to a local file (normally for tests) so we don't
      // need to filter.
      ||
      env.containsKey('FLUTTER_ANALYTICS_LOG_FILE')) {
    return false;
  }

  // TODO(jwren): Azure detection -- each call for this detection requires an
  // http connection, the flutter cli tool captures the result on the first run,
  // we should consider the same caching here.

  return env.containsKey('BOT')
      // https://docs.travis-ci.com/user/environment-variables/
      // Example .travis.yml file:
      // https://github.com/flutter/devtools/blob/master/.travis.yml
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
}

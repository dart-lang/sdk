// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

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

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'util.dart';

/// The [Uri] of a build step stdio log split into its subparts.
class BuildUri {
  final String scheme;
  final String host;
  final String prefix;
  final String botName;
  final int buildNumber;
  final String stepName;
  final String suffix;

  factory BuildUri(Uri uri) {
    List<String> parts =
        split(uri.path, ['/builders/', '/builds/', '/steps/', '/logs/']);
    String botName = parts[1];
    int buildNumber = int.parse(parts[2]);
    String stepName = parts[3];
    return new BuildUri.fromData(botName, buildNumber, stepName);
  }

  factory BuildUri.fromData(String botName, int buildNumber, String stepName) {
    return new BuildUri.internal('https', 'build.chromium.org',
        '/p/client.dart', botName, buildNumber, stepName, 'stdio/text');
  }

  BuildUri.internal(this.scheme, this.host, this.prefix, this.botName,
      this.buildNumber, this.stepName, this.suffix);

  String get shortBuildName => '$botName/$stepName';

  String get buildName =>
      '/builders/$botName/builds/$buildNumber/steps/$stepName';

  String get path => '$prefix$buildName/logs/$suffix';

  /// Creates the [Uri] for this build step stdio log.
  Uri toUri() {
    return new Uri(scheme: scheme, host: host, path: path);
  }

  /// Returns the [BuildUri] the previous build of this build step.
  BuildUri prev() {
    return new BuildUri.internal(
        scheme, host, prefix, botName, buildNumber - 1, stepName, suffix);
  }

  String toString() {
    return buildName;
  }
}

/// Id for a test on a specific configuration, for instance
/// `dart2js-chrome release_x64 co19/Language/Metadata/before_function_t07`.
class TestConfiguration {
  final String configName;
  final String archName;
  final String testName;

  TestConfiguration(this.configName, this.archName, this.testName);

  String toString() {
    return '$configName $archName $testName';
  }

  int get hashCode =>
      configName.hashCode * 13 +
      archName.hashCode * 17 +
      testName.hashCode * 19;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TestConfiguration) return false;
    return configName == other.configName &&
        archName == other.archName &&
        testName == other.testName;
  }
}

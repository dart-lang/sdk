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

  BuildUri withBuildNumber(int buildNumber) {
    return new BuildUri.fromData(botName, buildNumber, stepName);
  }

  String get shortBuildName => '$botName/$stepName';

  String get buildName =>
      '/builders/$botName/builds/$buildNumber/steps/$stepName';

  String get path => '$prefix$buildName/logs/$suffix';

  /// Returns the path used in logdog for this build uri.
  ///
  /// Since logdog only supports absolute build numbers, [buildNumber] must be
  /// non-negative. A [StateError] is thrown, otherwise.
  String get logdogPath {
    if (buildNumber < 0)
      throw new StateError('BuildUri $buildName must have a non-negative build '
          'number to a valid logdog path.');
    return 'chromium/bb/client.dart/$botName/$buildNumber/+/recipes/steps/'
        '${stepName.replaceAll(' ', '_')}/0/stdout';
  }

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

/// The results of a build step.
class BuildResult {
  final BuildUri _buildUri;

  /// The absolute build number, if found.
  ///
  /// The [buildUri] can be created with a relative build number, such as `-2`
  /// which means the second-to-last build. The absolute build number, a
  /// positive number, is read from the build results.
  final int buildNumber;

  final List<TestStatus> _results;
  final List<TestFailure> _failures;
  final List<Timing> _timings;

  BuildResult(this._buildUri, this.buildNumber, this._results, this._failures,
      this._timings);

  BuildUri get buildUri =>
      buildNumber != null ? _buildUri.withBuildNumber(buildNumber) : _buildUri;

  /// `true` of the build result has test failures.
  bool get hasFailures => _failures.isNotEmpty;

  /// Returns the top-20 timings found in the build log.
  Iterable<Timing> get timings => _timings;

  /// Returns the [TestStatus] for all tests.
  Iterable<TestStatus> get results => _results;

  /// Returns the [TestFailure]s for tests that timed out.
  Iterable<TestFailure> get timeouts {
    return _failures
        .where((TestFailure failure) => failure.actual == 'Timeout');
  }

  /// Returns the [TestFailure]s for failing tests that did not time out.
  Iterable<TestFailure> get errors {
    return _failures
        .where((TestFailure failure) => failure.actual != 'Timeout');
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('$buildUri\n');
    sb.write('Failures:\n${_failures.join('\n-----\n')}\n');
    sb.write('\nTimings:\n${_timings.join('\n')}');
    return sb.toString();
  }
}

/// Test failure data derived from the test failure summary in the build step
/// stdio log.
class TestFailure {
  final BuildUri uri;
  final TestConfiguration id;
  final String expected;
  final String actual;
  final String text;

  factory TestFailure(BuildUri uri, List<String> lines) {
    List<String> parts = split(lines.first, ['FAILED: ', ' ', ' ']);
    String configName = parts[1];
    String archName = parts[2];
    String testName = parts[3];
    TestConfiguration id =
        new TestConfiguration(configName, archName, testName);
    String expected = split(lines[1], ['Expected: '])[1];
    String actual = split(lines[2], ['Actual: '])[1];
    return new TestFailure.internal(
        uri, id, expected, actual, lines.skip(3).join('\n'));
  }

  TestFailure.internal(
      this.uri, this.id, this.expected, this.actual, this.text);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('FAILED: $id\n');
    sb.write('Expected: $expected\n');
    sb.write('Actual: $actual\n');
    sb.write(text);
    return sb.toString();
  }
}

/// Id for a single test step, for instance the compilation and run steps of
/// a test.
class TestStep {
  final String stepName;
  final TestConfiguration id;

  TestStep(this.stepName, this.id);

  String toString() {
    return '$stepName - $id';
  }

  int get hashCode => stepName.hashCode * 13 + id.hashCode * 17;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TestStep) return false;
    return stepName == other.stepName && id == other.id;
  }
}

/// The timing result for a single test step.
class Timing {
  final BuildUri uri;
  final String time;
  final TestStep step;

  Timing(this.uri, this.time, this.step);

  String toString() {
    return '$time - $step';
  }
}

/// The result of a single test for a single test step.
class TestStatus {
  final TestConfiguration config;
  final String status;

  TestStatus(this.config, this.status);

  String toString() => '$config: $status';
}

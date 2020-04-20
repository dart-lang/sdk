// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide HttpException;

import 'buildbot_data.dart';
import 'buildbot_loading.dart';
import 'buildbot_structures.dart';
import 'util.dart';

/// Interface for pulling build bot results.
abstract class BuildbotClient {
  /// Reads the [BuildResult] for the [buildUri].
  Future<BuildResult> readResult(BuildUri buildUri);

  int get mostRecentBuildNumber;

  /// Closes the client and cleans up its state.
  void close();
}

/// Buildbot client that pulls build bot results through http.
class HttpBuildbotClient implements BuildbotClient {
  final HttpClient _client = new HttpClient();

  static const int maxSkips = 3;

  @override
  Future<BuildResult> readResult(BuildUri buildUri) async {
    int skips = 0;
    Duration timeout;
    timeout = new Duration(seconds: 1);

    void skipToPreviousBuildNumber() {
      BuildUri prevBuildUri = buildUri.prev();
      String message =
          'Skip build number on ${buildUri} -> ${prevBuildUri.buildNumber}';
      // Skipping is more serious with an absolute than a relative build.
      if (buildUri.buildNumber < 0) {
        log(message);
      } else {
        print(message);
      }
      buildUri = buildUri.prev();
    }

    while (true) {
      try {
        return await readBuildResultFromHttp(_client, buildUri, timeout);
      } on TimeoutException {
        if (timeout != null && skips < maxSkips) {
          skips++;
          skipToPreviousBuildNumber();
          continue;
        }
        return null;
      } on HttpException {
        if (timeout != null && skips < maxSkips) {
          skips++;
          skipToPreviousBuildNumber();
          continue;
        }
        return null;
      } on SocketException {
        return null;
      }
    }
  }

  int get mostRecentBuildNumber => -1;

  @override
  void close() {
    _client.close();
  }
}

/// Buildbot client that pulls build bot results through logdog.
class LogdogBuildbotClient implements BuildbotClient {
  Map<String, List<int>> _botBuildNumberCache = <String, List<int>>{};

  int get mostRecentBuildNumber => -1;

  Future<List<int>> _getAbsoluteBuildNumbers(BuildUri buildUri) async {
    List<int> absoluteBuildNumbers = _botBuildNumberCache[buildUri.botName];
    if (absoluteBuildNumbers == null) {
      absoluteBuildNumbers = await lookupBotBuildNumbers(buildUri.botName);
      _botBuildNumberCache[buildUri.botName] = absoluteBuildNumbers;
    }
    return absoluteBuildNumbers;
  }

  @override
  Future<BuildResult> readResult(BuildUri buildUri) async {
    List<int> absoluteBuildNumbers;
    int buildNumberIndex;
    if (buildUri.buildNumber < 0) {
      absoluteBuildNumbers = await _getAbsoluteBuildNumbers(buildUri);
      int buildNumberIndex =
          getBuildNumberIndex(absoluteBuildNumbers, buildUri.buildNumber);
      if (buildNumberIndex == null) return null;
      buildUri =
          buildUri.withBuildNumber(absoluteBuildNumbers[buildNumberIndex]);
    }
    while (true) {
      try {
        return await readBuildResultFromLogDog(buildUri);
      } catch (e) {
        absoluteBuildNumbers ??= await _getAbsoluteBuildNumbers(buildUri);
        buildNumberIndex =
            getBuildNumberIndex(absoluteBuildNumbers, buildUri.buildNumber);
        if (buildNumberIndex == null) return null;
        buildNumberIndex++;
        if (buildNumberIndex >= absoluteBuildNumbers.length) return null;
        int buildNumber = absoluteBuildNumbers[buildNumberIndex];
        log('Skip build number ${buildUri.buildNumber} -> ${buildNumber}');
        buildUri = buildUri.withBuildNumber(buildNumber);
      }
    }
  }

  @override
  void close() {
    // Nothing to do.
  }
}

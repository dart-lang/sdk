// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares the test log of a build step with previous builds.
///
/// Use this to detect flakiness of failures, especially timeouts.

import 'dart:async';
import 'dart:io';

import 'package:gardening/src/buildbot_loading.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/cache.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/util.dart';

class TestClient implements BuildbotClient {
  BuildbotClient _client;

  /// Creates a mock client using logs stored in the `data` folder. If [force]
  /// is `true`, missing logs are pulling from http and stored in the `data`
  /// folder.
  TestClient({bool force: false})
      : _client = force ? new HttpBuildbotClient() : null;

  String computePath(BuildUri buildUri) {
    return 'data/${buildUri.botName}/${buildUri.buildNumber}'
        '/${buildUri.stepName.replaceAll(' ', '_')}.log';
  }

  Future<String> readData(BuildUri buildUri) async {
    String path = computePath(buildUri);
    File file = new File.fromUri(Platform.script.resolve(path));
    if (!file.existsSync() && _client != null) {
      await file.parent.create();
      log('Pulling $buildUri from http');
      BuildResult result = await _client.readResult(buildUri);
      if (result.buildNumber != null) {
        print('Writing test data to $file');
        String text = await cache.read(
            result.buildUri.logdogPath,
            () => throw new ArgumentError(
                'Cache missing for ${result.buildUri.logdogPath}.'));
        await file.writeAsString(text);
      }
    }
    assert(file.existsSync(), "File $file not found.");
    log('Reading test data from $file');
    return file.readAsString();
  }

  @override
  Future<BuildResult> readResult(BuildUri buildUri) async {
    String text = await readData(buildUri);
    return parseTestStepResult(buildUri, text);
  }

  @override
  void close() {
    _client?.close();
  }

  @override
  int get mostRecentBuildNumber => -1;
}

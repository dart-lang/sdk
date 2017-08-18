// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'buildbot_data.dart';
import 'buildbot_structures.dart';
import 'client.dart';
import 'util.dart';

class Bot {
  final BuildbotClient _client;

  /// Instantiates a Bot.
  ///
  /// Bots must be [close]d when they aren't needed anymore.
  Bot({bool logdog = false})
      : this.internal(
            logdog ? new LogdogBuildbotClient() : new HttpBuildbotClient());

  Bot.internal(this._client);

  int get mostRecentBuildNumber => _client.mostRecentBuildNumber;

  /// Reads the build result of [buildUri] and the [previousCount] earlier
  /// builds.
  Future<List<BuildResult>> readHistoricResults(BuildUri buildUri,
      {int previousCount = 0}) {
    log("Fetching $buildUri and $previousCount previous builds in parallel");
    var uris = [buildUri];
    for (int i = 0; i < previousCount; i++) {
      buildUri = buildUri.prev();
      uris.add(buildUri);
    }
    return readResults(uris);
  }

  Future<BuildResult> readResult(BuildUri buildUri) {
    return _client.readResult(buildUri);
  }

  /// Maximum number of [BuildResult]s read concurrently by [readResults].
  static const maxParallel = 20;

  /// Reads the build results of all given uris.
  ///
  /// Returns a list of the results. If a uri couldn't be read, then the entry
  /// in the list is `null`.
  Future<List<BuildResult>> readResults(List<BuildUri> buildUris) async {
    var result = <BuildResult>[];
    int i = 0;
    while (i < buildUris.length) {
      var end = i + maxParallel;
      if (end > buildUris.length) end = buildUris.length;
      var parallelChunk = buildUris.sublist(i, end);
      log("Fetching ${end - i} uris in parallel");
      result.addAll(await Future.wait(parallelChunk.map((uri) {
        var result = _client.readResult(uri);
        if (result == null) {
          log("Error while reading $uri");
        }
        return result;
      })));
      i = end;
    }
    return result;
  }

  /// Returns uris for the most recent build of all build groups.
  List<BuildUri> get mostRecentUris {
    List<BuildUri> result = [];
    for (BuildGroup group in buildGroups) {
      result.addAll(group.createUris(mostRecentBuildNumber));
    }
    return result;
  }

  /// Closes the bot.
  void close() => _client.close();
}

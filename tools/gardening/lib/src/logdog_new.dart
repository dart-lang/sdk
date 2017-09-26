// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'logdog_rpc.dart';
import 'cache_new.dart';
import 'try.dart';

/// Gets latest build numbers of completed runs from the last completed runs.
/// This works if one assumes that the bots we are interested in also completes
/// runs regularly.
Future<Try<Map<String, int>>> getLatestBuilderNumbers(
    WithCacheFunction withCache) async {
  var logdog = new LogdogRpc();
  // This queries logdog for all logs that wrote recipe_result, which is the
  // last step of any recipe. The ** searches the last incoming commits that
  // fits the scheme.
  // TODO(mkroghj): Give project as an option to allow for FYI.
  var tryStreams = await logdog.query(
      "chromium",
      "bb/client.dart/**/+/recipes/steps/recipe_result/0/logs/result/0",
      withCache);
  // All logs have the build-number in their path, so we just get it out.
  var regExp = new RegExp(r"^.*\/.*\/(.*)\/(\d*)\/\+");
  return tryStreams.bind((streams) {
    var map = <String, int>{};
    streams.forEach((stream) {
      var match = regExp.firstMatch(stream.path);
      map[match.group(1)] ??= int.parse(match.group(2));
    });
    return map;
  });
}

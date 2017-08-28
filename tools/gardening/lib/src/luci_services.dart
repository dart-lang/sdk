// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'try.dart';
import 'logger.dart';
import 'cache_new.dart';
import 'luci_api.dart';

/// Fetches all builds for a given [commit]-hash, by searching the latest
/// [amount] builds.
Future<Try<List<BuildDetail>>> fetchBuildsForCommmit(LuciApi api, Logger logger,
    String client, String commit, CreateCacheFunction createCache,
    [int amount = 1]) async {
  logger.debug("Finding primary bots for client $client");
  var buildBots = await api.getPrimaryBuilders(
      client, createCache(duration: new Duration(minutes: 30)));

  var cache = createCache(duration: new Duration(minutes: 30));
  return (await buildBots.bindAsync((List<LuciBuildBot> buildBots) async {
    var buildBotBuilds = new List<List<BuildDetail>>();
    for (var buildBot in buildBots) {
      (await api.getBuildBotDetails(client, buildBot.name, cache, amount)).fold(
          (ex, st) {
        logger.error("Problem getting results", ex, st);
      }, buildBotBuilds.add);
    }
    logger.debug("All latest $amount builds found for client $client. "
        "Processing results...");
    return buildBotBuilds.expand((id) => id).toList();
  })).bind((List<BuildDetail> buildDetails) {
    return buildDetails.where((BuildDetail buildDetail) {
      return buildDetail.allChanges.any((change) => change.revision == commit);
    });
  });
}

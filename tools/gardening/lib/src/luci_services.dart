// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'try.dart';
import 'logger.dart';
import 'cache_new.dart';
import 'luci.dart';
import 'util.dart';

const UNINTERESTING_BUILDER_SUFFIXES = const [
  "-dev",
  "-stable",
  "-integration"
];

/// Fetches all builds for a given [commit]-hash, by searching the latest
/// [amount] builds.
Future<Try<List<BuildDetail>>> fetchBuildsForCommmit(Luci luci, Logger logger,
    String client, String commit, CreateCacheFunction createCache,
    [int amount = 1]) async {
  logger.debug("Finding primary bots for client $client");
  var buildBots = await getPrimaryBuilders(
      luci, client, createCache(duration: new Duration(minutes: 30)));

  var cache = createCache(duration: new Duration(minutes: 30));

  return (await buildBots.bindAsync((List<String> buildBots) async {
    var buildBotBuilds = new List<List<BuildDetail>>();
    for (var buildBot in buildBots) {
      (await luci.getBuildBotDetails(client, buildBot, cache, amount)).fold(
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

/// [getBuilderGroups] fetches all builder groups not in -dev, -stable and
/// -integration from CBE.
Future<Try<List<String>>> getBuilderGroups(
    Luci luci, String client, WithCacheFunction withCache) async {
  var result = await luci.getJsonFromChromeBuildExtract(client, withCache);
  return result.bind((json) {
    var builders = json["builders"];
    return builders.keys.fold<Map<String, Object>>({},
        (Map<String, Object> map, builderKey) {
      if (UNINTERESTING_BUILDER_SUFFIXES.any((x) => builderKey.contains(x))) {
        return map;
      }
      map[sanitizeCategory(builders[builderKey]["category"])] = true;
      return map;
    }).keys;
  });
}

/// [getAllBuilders] fetches all builders from CBE.
Future<Try<List<String>>> getAllBuilders(
    Luci luci, String client, WithCacheFunction withCache) async {
  var result = await luci.getJsonFromChromeBuildExtract(client, withCache);
  return result.bind((json) {
    return json["builders"].keys;
  });
}

/// [getPrimaryBuilders] fetches all primary builders from CBE.
Future<Try<List<String>>> getPrimaryBuilders(
    Luci luci, String client, WithCacheFunction withCache) async {
  var result = await getAllBuilders(luci, client, withCache);
  return result.bind((builders) {
    return builders
        .where((builderKey) =>
            !UNINTERESTING_BUILDER_SUFFIXES.any((x) => builderKey.contains(x)))
        .toList();
  });
}

/// [getPrimaryBuilders] gets all builders in builder group [builderGroup].
Future<Try<List<String>>> getBuildersInBuilderGroup(Luci luci, String client,
    WithCacheFunction withCache, String builderGroup) async {
  var result = await luci.getJsonFromChromeBuildExtract(client, withCache);
  return result.bind((json) {
    var builders = json["builders"];
    return builders.keys.where((builder) {
      return sanitizeCategory(builders[builder]["category"]) == builderGroup;
    });
  });
}

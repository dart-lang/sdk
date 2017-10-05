// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'logger.dart';
import 'cache_new.dart';
import 'luci_api.dart';
import 'util.dart';

const UNINTERESTING_BUILDER_SUFFIXES = const [
  "-dev",
  "-stable",
  "-integration"
];

const String DART_CLIENT = 'client.dart';

/// Fetches all builds for a given [commit]-hash, by searching the latest
/// [amount] builds.
Future<List<BuildDetail>> fetchBuildsForCommmit(LuciApi luciApi, Logger logger,
    String client, String commit, CreateCacheFunction createCache,
    [int amount = 1]) {
  logger.info(
      "Sorry - this is going to take some time, since we have to look into all "
      "$amount latest builds for all bots for client ${client}.\n"
      "Subsequent queries run faster if caching is not turned off...");

  logger.debug("Finding primary bots for client $client");
  var futureBuildBots = getPrimaryBuilders(
      luciApi, client, createCache(duration: new Duration(minutes: 30)));

  var cache = createCache(duration: new Duration(minutes: 30));

  return futureBuildBots.then((buildBots) {
    var buildBotBuilds = new List<List<BuildDetail>>();
    var futureDetails = buildBots.map((buildBot) {
      return luciApi
          .getBuildBotDetails(client, buildBot, cache, amount)
          .then(buildBotBuilds.add)
          .catchError(
              errorLogger(logger, "Could not get details for $buildBot", []));
    });
    return Future.wait(futureDetails).then((details) {
      return buildBotBuilds.expand((id) => id);
    }).then((details) {
      return details.where((buildDetail) {
        return buildDetail.allChanges
            .any((change) => change.revision.startsWith(commit));
      }).toList();
    });
  });
}

/// [getBuilderGroups] fetches all builder groups not in -dev, -stable and
/// -integration from CBE.
Future<List<String>> getBuilderGroups(
    LuciApi luciApi, String client, WithCacheFunction withCache) {
  var result = luciApi.getJsonFromChromeBuildExtract(client, withCache);
  return result.then((json) {
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
Future<List<String>> getAllBuilders(
    LuciApi luciApi, String client, WithCacheFunction withCache) {
  var result = luciApi.getJsonFromChromeBuildExtract(client, withCache);
  return result.then((json) {
    return json["builders"].keys;
  });
}

/// [getPrimaryBuilders] fetches all primary builders from CBE.
Future<List<String>> getPrimaryBuilders(
    LuciApi luciApi, String client, WithCacheFunction withCache) {
  var result = getAllBuilders(luciApi, client, withCache);
  return result.then((builders) {
    return builders
        .where((builderKey) =>
            !UNINTERESTING_BUILDER_SUFFIXES.any((x) => builderKey.contains(x)))
        .toList();
  });
}

/// [getPrimaryBuilders] gets all builders in builder group [builderGroup].
Future<List<String>> getBuildersInBuilderGroup(LuciApi luciApi, String client,
    WithCacheFunction withCache, String builderGroup) {
  var result = luciApi.getJsonFromChromeBuildExtract(client, withCache);
  return result.then((json) {
    var builders = json["builders"];
    return builders.keys.where((builder) {
      return sanitizeCategory(builders[builder]["category"]) == builderGroup;
    }).toList();
  });
}

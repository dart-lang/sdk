// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:gardening/src/luci.dart';
import 'package:gardening/src/luci_services.dart';
import 'package:gardening/src/logger.dart';
import 'package:gardening/src/cache_new.dart';
import 'package:gardening/src/util.dart';
import 'package:args/args.dart';

ArgParser setupArgs() {
  return new ArgParser()
    ..addOption("client",
        abbr: "c", defaultsTo: DART_CLIENT, help: "Set which client to use.")
    ..addFlag(Flags.verbose,
        abbr: "v", negatable: false, help: "Print debugging information.")
    ..addFlag(Flags.noCache,
        negatable: false,
        defaultsTo: false,
        help: "Use this flag to bypass caching. This may be slower.")
    ..addFlag(Flags.help,
        negatable: false,
        help: "Shows information on how to use the luci tool.")
    ..addFlag("build-bots",
        negatable: false,
        help: "Use this flag to see the primary build bots for --client.")
    ..addFlag("build-bots-all",
        negatable: false,
        help: "Use this flag to see all build bots for --client.")
    ..addFlag("master",
        negatable: false,
        help: "Use this flag to see information about master for --client.")
    ..addFlag("build-groups",
        negatable: false,
        help: "Use this flag to see all builder-groups not -dev, -stable "
            "or -integration for --client.")
    ..addFlag("builders-in-group",
        negatable: false,
        help: "Use this flag as `--build-bot-details <group>` to see all "
            "builders (incl. shards) for a build group <group>.")
    ..addFlag("build-bot-details",
        negatable: false,
        help: "Use this flag as `--build-bot-details <name>` where "
            "<name> is the name of the build bot, to see details of "
            "a specific build bot.")
    ..addFlag("build-details",
        negatable: false,
        help: "Use this option as `--build-details <name> <buildNo>` where "
            "<name> is the name of the bot and "
            "<buildNo> is the number of the build.")
    ..addFlag("builds-with-commit",
        negatable: false,
        help: "Fetches all builds with a specific commit. Use this flag as "
            "`--builds-with-commit <commit-hash>` where the <commit-hash> is "
            "the hash of the commit");
}

void printHelp(ArgParser parser) {
  print("This tool calls different pages on Luci and aggregate the information "
      "found. Below is stated information about flags and options:");
  print("");
  print(parser.usage);
}

main(List<String> args) async {
  var parser = setupArgs();
  var results = parser.parse(args);

  if (results["help"]) {
    printHelp(parser);
    return;
  }

  var luci = new Luci();
  Logger logger = createLogger(verbose: results[Flags.verbose]);
  CreateCacheFunction createCache =
      createCacheFunction(logger, disableCache: results[Flags.noCache]);

  if (results["build-bots"]) {
    await performBuildBotsPrimary(luci, createCache, results);
  } else if (results["build-bots-all"]) {
    await performBuildBotsAll(luci, createCache, results);
  } else if (results["master"]) {
    await performMaster(luci, createCache, results);
  } else if (results["build-groups"]) {
    await performBuilderGroups(luci, createCache, results);
  } else if (results["builders-in-group"]) {
    await performBuildersInGroup(luci, createCache, results);
  } else if (results["build-bot-details"]) {
    await performBuildBotDetails(luci, createCache, results);
  } else if (results["build-details"]) {
    await performBuildDetails(luci, createCache, results);
  } else if (results["builds-with-commit"]) {
    await performFindBuildsForCommit(luci, createCache, logger, results);
  } else {
    printHelp(parser);
  }

  luci.close();
}

Future performBuildBotsPrimary(
    Luci luci, CreateCacheFunction createCache, ArgResults results) async {
  var res = await getPrimaryBuilders(
      luci, results['client'], createCache(duration: new Duration(hours: 1)));
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (bots) => bots.forEach(print));
}

Future performBuildBotsAll(
    Luci luci, CreateCacheFunction cache, ArgResults results) async {
  var res = await getAllBuilders(
      luci, results['client'], cache(duration: new Duration(hours: 1)));
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (bots) => bots.forEach(print));
}

Future performMaster(
    Luci luci, CreateCacheFunction cache, ArgResults results) async {
  var res = await luci.getMaster(
      results['client'], cache(duration: new Duration(minutes: 15)));
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (res) => print(res));
}

Future performBuilderGroups(
    Luci luci, CreateCacheFunction cache, ArgResults results) async {
  var res = await getBuilderGroups(
      luci, results['client'], cache(duration: new Duration(minutes: 15)));
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (res) => res.forEach(print));
}

Future performBuildersInGroup(
    Luci luci, CreateCacheFunction cache, ArgResults results) async {
  if (results.rest.length == 0) {
    print("No argument given for <group>. To see help, use --help");
    return;
  }

  var res = await getBuildersInBuilderGroup(luci, results['client'],
      cache(duration: new Duration(minutes: 15)), results.rest[0]);
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (res) => res.forEach(print));
}

Future performBuildBotDetails(
    Luci luci, CreateCacheFunction cache, ArgResults results) async {
  if (results.rest.length == 0) {
    print("No argument given for <name>. To see help, use --help");
    return;
  }
  var result = await luci.getBuildBotDetails(results['client'], results.rest[0],
      cache(duration: new Duration(minutes: 15)));
  result.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (detail) => print(detail));
}

Future performBuildDetails(
    Luci luci, CreateCacheFunction createCache, ArgResults results) async {
  if (results.rest.length < 2) {
    print("Missing argument for <name> or <buildNo>. To see help, use --help");
    return;
  }
  int buildNumber = int.parse(results.rest[1], onError: (source) => 0);
  if (buildNumber <= 0) {
    print("The buildnumber ${results['build-details']} must be a integer "
        "greater than zero");
    return;
  }

  var result = await luci.getBuildBotBuildDetails(
      results['client'],
      results.rest[0],
      buildNumber,
      createCache(duration: new Duration(minutes: 15)));
  result.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (detail) => print(detail));
}

Future performFindBuildsForCommit(Luci luci, CreateCacheFunction createCache,
    Logger logger, ArgResults results) async {
  if (results.rest.length == 0) {
    print("Missing argument for <commit>. To see help, use --help");
    return;
  }

  int amount = 25;

  var result = await fetchBuildsForCommmit(
      luci, logger, results['client'], results.rest[0], createCache, amount);
  result.fold((ex, st) {
    print(ex);
    print(st);
  }, (List<BuildDetail> details) {
    print("The commit '${results.rest[0]} is used in the following builds:");
    details.forEach((detail) {
      String url = "https://luci-milo.appspot.com/buildbot/"
          "${detail.client}/${detail.botName}/${detail.buildNumber}";
      print("${detail.botName}: #${detail.buildNumber}\t$url");
    });
  });
}

// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:gardening/src/luci_api.dart';
import 'package:gardening/src/luci_services.dart';
import 'package:gardening/src/logger.dart';
import 'package:gardening/src/cache_new.dart';
import 'package:args/args.dart';

ArgParser setupArgs() {
  return new ArgParser()
    ..addOption("client",
        abbr: "c", defaultsTo: 'client.dart', help: "Set which client to use.")
    ..addFlag("verbose",
        abbr: "v", negatable: false, help: "Print debugging information.")
    ..addFlag("no-cache",
        negatable: false,
        defaultsTo: false,
        help: "Use this flag to bypass caching. This may be slower.")
    ..addFlag("help",
        negatable: false,
        help: "Shows information on how to use the luci_api tool.")
    ..addFlag("build-bots",
        negatable: false,
        help: "Use this flag to see the primary build bots for --client.")
    ..addFlag("build-bots-all",
        negatable: false,
        help: "Use this flag to see all build bots for --client.")
    ..addFlag("build-bot-details",
        negatable: false,
        help: "Use this flag as `--build-bot-details <name>` where "
            "<name> is the name of the build bot, to see details of "
            "a specific build bot.")
    ..addFlag("build-details",
        negatable: false,
        help: "use this option as `--build-details <name> <buildNo>` where "
            "<name> is the name of the bot and "
            "<buildNo> is the number of the build.")
    ..addFlag("commit-builds",
        negatable: false,
        help: "Fetches all builds for a specific commit. Use this flag as "
            "`--commit-builds <commit-hash>` where the <commit-hash> is the "
            "hash of the commit");
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

  var luciApi = new LuciApi();
  Logger logger =
      new StdOutLogger(results['verbose'] ? Level.debug : Level.info);
  CreateCacheFunction createCache = results['no-cache']
      ? noCache()
      : initCache(Uri.base.resolve('temp/gardening-cache/'), logger);

  if (results["build-bots"]) {
    await performBuildBotsPrimary(luciApi, createCache, results);
  } else if (results["build-bots-all"]) {
    await performBuildBotsAll(luciApi, createCache, results);
  } else if (results["build-bot-details"]) {
    await performBuildBotDetails(luciApi, createCache, results);
  } else if (results["build-details"]) {
    await performBuildDetails(luciApi, createCache, results);
  } else if (results["commit-builds"]) {
    await performFindBuildsForCommit(luciApi, createCache, logger, results);
  } else {
    printHelp(parser);
  }

  luciApi.close();
}

Future performBuildBotsPrimary(
    LuciApi api, CreateCacheFunction createCache, ArgResults results) async {
  var res = await api.getPrimaryBuilders(
      results['client'], createCache(duration: new Duration(hours: 1)));
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (bots) => bots.forEach(print));
}

Future performBuildBotsAll(
    LuciApi api, CreateCacheFunction cache, ArgResults results) async {
  var res = await api.getAllBuildBots(
      results['client'], cache(duration: new Duration(hours: 1)));
  res.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (bots) => bots.forEach(print));
}

Future performBuildBotDetails(
    LuciApi api, CreateCacheFunction cache, ArgResults results) async {
  if (results.rest.length == 0) {
    print("No argument given for <name>. To see help, use --help");
    return;
  }
  var result = await api.getBuildBotDetails(results['client'], results.rest[0],
      cache(duration: new Duration(minutes: 15)));
  result.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (detail) => print(detail));
}

Future performBuildDetails(
    LuciApi api, CreateCacheFunction createCache, ArgResults results) async {
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

  var result = await api.getBuildBotBuildDetails(
      results['client'],
      results.rest[0],
      buildNumber,
      createCache(duration: new Duration(minutes: 15)));
  result.fold((ex, stackTrace) {
    print(ex);
    print(stackTrace);
  }, (detail) => print(detail));
}

Future performFindBuildsForCommit(LuciApi api, CreateCacheFunction createCache,
    Logger logger, ArgResults results) async {
  if (results.rest.length == 0) {
    print("Missing argument for <commit>. To see help, use --help");
    return;
  }

  int amount = 25;
  logger.info(
      "Sorry - this is going to take some time, since we have to look into all "
      "$amount latest builds for all bots for client ${results['client']}.\n"
      "Subsequent queries run faster if caching is not turned off...");

  var result = await fetchBuildsForCommmit(
      api, logger, results['client'], results.rest[0], createCache, amount);
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

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:args/args.dart';
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/util.dart';

void help(ArgParser argParser) {
  print('Summarizes the current status of the build bot.');
  print('Usage: summary [options] (<group> ...)');
  print("  where <group> is (part of) a build bot group, like 'vm-kernel', ");
  print("  and options are:");
  print(argParser.usage);
}

Future main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  if (argResults['help']) {
    help(argParser);
    return;
  }

  Bot bot = new Bot(logdog: argResults['logdog']);
  List<BuildResult> buildResultsWithoutFailures = <BuildResult>[];
  List<BuildResult> buildResultsWithFailures = <BuildResult>[];
  for (BuildGroup group in buildGroups) {
    if (argResults.rest.isNotEmpty) {
      if (!argResults.rest
          .any((arg) => containsIgnoreCase(group.groupName, arg))) {
        log('Skipping group $group');
        continue;
      }
    }
    // TODO(johnniwinther): Support reading a partially completed shard from
    // http, i.e. always use build number `-1`.
    List<BuildUri> uriList = group.createUris(bot.mostRecentBuildNumber);
    if (uriList.isEmpty) continue;
    print('Fetching "${uriList.first}" + ${uriList.length - 1} more ...');
    List<BuildResult> results = await bot.readResults(uriList);
    results.forEach((result) {
      if (result != null) {
        if (result.hasFailures) {
          buildResultsWithFailures.add(result);
        } else {
          buildResultsWithoutFailures.add(result);
        }
      }
    });
  }
  print('');
  if (buildResultsWithFailures.isEmpty && buildResultsWithoutFailures.isEmpty) {
    if (argResults.rest.isEmpty) {
      print('No test steps found.');
    } else {
      print("No test steps found for '${argResults.rest.join("', '")}'.");
    }
  } else {
    int totalCount =
        buildResultsWithFailures.length + buildResultsWithoutFailures.length;
    if (argResults.rest.isEmpty) {
      print('${totalCount} test steps analyzed.');
    } else {
      print("${totalCount} test steps analyzed for build bot groups matching "
          "'${argResults.rest.join("', '")}'.");
    }
    if (LOG) {
      print(' Found ${buildResultsWithoutFailures.length} '
          'test steps without failures:');
      for (BuildResult result in buildResultsWithoutFailures) {
        print('  ${result.buildUri.toUri()}');
      }
    } else {
      print(' Found ${buildResultsWithoutFailures.length} '
          'test steps without failures.');
    }
    if (buildResultsWithFailures.isNotEmpty) {
      print(' Found ${buildResultsWithFailures.length} '
          'test steps with failures:');
      for (BuildResult result in buildResultsWithFailures) {
        print('  ${result.buildUri.toUri()}');
      }
    }
  }

  bot.close();
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Scans past dart2js-windows test steps for timeouts and reports the
/// frequency of each test that has timed out.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_loading.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/logdog.dart';
import 'package:gardening/src/util.dart';

// TODO(johnniwinther): Adjustments needed: this script may run with
// no output for a long time. Hence not yet run by bot.dart.
main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addOption('start',
      defaultsTo: '-2',
      help: "Start pulling from the specified <build-number>.\n"
          "Use negative numbers for the most recent builds;\n"
          "for instance -2 for the second-to-last build.'");
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  BuildbotClient client = argResults['logdog']
      ? new LogdogBuildbotClient()
      : new HttpBuildbotClient();

  List<String> arguments = argResults.rest;
  if (arguments.length > 1) {
    print('Usage: find_timeouts.dart [options] [<count>]');
    print('Where <count> is the number of old builds that are scanned');
    print('and options are:');
    print(argParser.usage);
    exit(1);
  }
  int buildNumberCount = 10;
  if (arguments.length > 0) {
    buildNumberCount = int.parse(arguments[0]);
  }
  int buildNumberOffset;
  if (argResults.wasParsed('start')) {
    buildNumberOffset = int.parse(argResults['start']);
  } else {
    buildNumberOffset = client.mostRecentBuildNumber;
  }

  BuildGroup group =
      buildGroups.firstWhere((g) => g.groupName == 'dart2js-windows');
  Map<String, List<Timeout>> timeouts = <String, List<Timeout>>{};
  for (BuildSubgroup subgroup in group.subgroups) {
    await readBuildBotResults(client, subgroup, timeouts,
        buildNumberOffset: buildNumberOffset,
        buildNumberCount: buildNumberCount);
  }

  List<String> sorted = timeouts.keys.toList()
    ..sort((a, b) {
      return -timeouts[a].length.compareTo(timeouts[b].length);
    });

  sorted.forEach((String testName) {
    List<Timeout> list = timeouts[testName];
    print('${padLeft('${list.length}', 4)} $testName');
    for (Timeout timeout in list) {
      print('     - ${timeout.buildUri.botName}/${timeout.buildUri.stepName} '
          '${timeout.timeout.id} (${timeout.buildNumber})');
    }
  });

  client.close();
}

Future readLogDogResults(
    BuildSubgroup subgroup, Map<String, List<Timeout>> timeouts,
    {int buildNumberOffset, int buildNumberCount}) async {
  Map<String, String> subgroupPaths = subgroup.logDogPaths;
  for (String shardName in subgroupPaths.keys) {
    List<int> buildNumbers =
        await latestBuildNumbersForBuilder(shardName, buildNumberCount);
    int buildNumberIndex;
    if (buildNumberOffset < 0) {
      buildNumberIndex = -buildNumberOffset - 1;
    } else {
      buildNumberIndex = buildNumbers.firstWhere((n) => n <= buildNumberOffset,
          orElse: () => buildNumbers.length);
    }
    for (int i = 0; i < buildNumberCount; i++) {
      if (buildNumberIndex + i < buildNumbers.length) {
        int buildNumber = buildNumbers[buildNumberIndex + i];
        for (BuildUri buildUri
            in subgroup.createShardUris(shardName, buildNumber)) {
          BuildResult result = await readBuildResultFromLogDog(buildUri);
          for (TestFailure timeout in result.timeouts) {
            timeouts.putIfAbsent(timeout.id.testName, () => <Timeout>[]).add(
                new Timeout(subgroup, result.buildNumber, buildUri, timeout));
          }
          buildUri = buildUri.prev();
        }
      }
    }
  }
}

Future readBuildBotResults(BuildbotClient client, BuildSubgroup subgroup,
    Map<String, List<Timeout>> timeouts,
    {int buildNumberOffset, int buildNumberCount}) async {
  List<BuildUri> buildUris = subgroup.createUris(buildNumberOffset);
  for (BuildUri buildUri in buildUris) {
    for (int i = 0; i < buildNumberCount; i++) {
      BuildResult result = await client.readResult(buildUri);
      for (TestFailure timeout in result.timeouts) {
        timeouts
            .putIfAbsent(timeout.id.testName, () => <Timeout>[])
            .add(new Timeout(subgroup, result.buildNumber, buildUri, timeout));
      }
      buildUri = result.buildUri.prev();
    }
  }
}

class Timeout {
  final BuildSubgroup subgroup;
  final int buildNumber;
  final BuildUri buildUri;
  final TestFailure timeout;

  Timeout(this.subgroup, this.buildNumber, this.buildUri, this.timeout);
}

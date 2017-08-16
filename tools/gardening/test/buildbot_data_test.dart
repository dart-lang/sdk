// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks that all active test steps in [buildGroups] can be read from http.

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/util.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  bool useLogdog = argResults['logdog'];

  Bot bot = new Bot(logdog: useLogdog);

  List<String> failingUris = <String>[];
  List<BuildUri> buildUris = <BuildUri>[];
  for (BuildGroup buildGroup in buildGroups) {
    for (BuildSubgroup buildSubgroup in buildGroup.subgroups) {
      if (!useLogdog && !buildSubgroup.isActive) continue;
      buildUris.addAll(buildSubgroup.createUris(bot.mostRecentBuildNumber));
    }
  }
  List<BuildResult> buildResults = await bot.readResults(buildUris);
  for (int index = 0; index < buildResults.length; index++) {
    BuildUri buildUri = buildUris[index];
    BuildResult result = buildResults[index];
    if (result == null) {
      failingUris.add('$buildUri');
    }
  }
  // TODO(johnniwinther): Find out why these steps cannot be read.
  Expect.setEquals([
    '/builders/pkg-mac10.11-release-be/builds/-1/'
        'steps/third_party/pkg_tested unit tests',
    '/builders/pkg-linux-release-be/builds/-1/steps/'
        'third_party/pkg_tested unit tests',
    '/builders/pkg-win7-release-be/builds/-1/steps/'
        'third_party/pkg_tested unit tests',
  ], failingUris,
      "Unexpected failing buildbot uris:\n ${failingUris.join('\n ')}");

  bot.close();
}

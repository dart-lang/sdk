// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks that all active test steps in [buildGroups] can be read from http.

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'package:gardening/src/client.dart';
import 'package:gardening/src/util.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  bool useLogdog = argResults['logdog'];

  BuildbotClient client =
      useLogdog ? new LogdogBuildbotClient() : new HttpBuildbotClient();

  List<String> failingUris = <String>[];
  for (BuildGroup buildGroup in buildGroups) {
    for (BuildSubgroup buildSubgroup in buildGroup.subgroups) {
      if (!useLogdog && !buildSubgroup.isActive) continue;
      List<BuildUri> buildUris =
          buildSubgroup.createUris(client.mostRecentBuildNumber);
      for (BuildUri buildUri in buildUris) {
        BuildResult result = await client.readResult(buildUri);
        if (result == null) {
          failingUris.add('$buildUri');
        }
      }
    }
  }
  // TODO(johnniwinther): Find out why these steps cannot be read.
  Expect.setEquals([
    '/builders/pkg-mac10.11-release-be/builds/-2/'
        'steps/third_party/pkg_tested unit tests',
    '/builders/pkg-linux-release-be/builds/-2/steps/'
        'third_party/pkg_tested unit tests',
    '/builders/pkg-win7-release-be/builds/-2/steps/'
        'third_party/pkg_tested unit tests',
  ], failingUris, "Unexpected failing buildbot uris: $failingUris");

  client.close();
}

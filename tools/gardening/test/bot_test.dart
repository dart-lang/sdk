// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/buildbot_data.dart';
import 'package:gardening/src/buildbot_structures.dart';
import 'test_client.dart';

main() async {
  Bot bot = new Bot.internal(new DummyClient());
  List<BuildUri> buildUriList = buildGroups
      .firstWhere((g) => g.groupName == 'dart2js-linux')
      .createUris(bot.mostRecentBuildNumber);
  Expect.isTrue(buildUriList.length > Bot.maxParallel);
  List<BuildResult> buildResults = await bot.readResults(buildUriList);
  Expect.equals(buildUriList.length, buildResults.length);
  bot.close();
}

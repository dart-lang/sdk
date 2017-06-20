// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/util.dart';

void help(ArgParser argParser) {
  print('Summarizes the current status of the build bot.');
  print('Usage: summary [options]');
  print('  where options are:');
  print(argParser.usage);
}

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  var bot = new Bot(logdog: argResults['logdog']);
  var recentUris = bot.mostRecentUris;
  var results = await bot.readResults(recentUris);
  results.forEach((result) {
    if (result.hasFailures) {
      print("${result.buildUri} has failures.");
    }
  });
  bot.close();
}

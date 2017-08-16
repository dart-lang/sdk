// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares the test log of a build step with previous builds.
///
/// Use this to detect flakiness of failures, especially timeouts.

import 'dart:io';

import 'package:args/args.dart';
import 'package:gardening/src/bot.dart';
import 'package:gardening/src/compare_failures_impl.dart';
import 'package:gardening/src/util.dart';

void help(ArgParser argParser) {
  print('Given a <log-uri> finds all failing tests in that stdout. Then ');
  print('fetches earlier runs of the same bot and compares the results.');
  print('This tool is particularly useful to detect flakes and their ');
  print('frequency.');
  print('Usage: compare_failures [options] ');
  print('  (<log-uri> [<log-uri> ...] | <build-group> [<build-group> ...])');
  print('where <log-uri> is the uri the stdio output of a failing test step ');
  print('and <build-group> is the name of a buildbot group, for instance ');
  print('`vm-kernel`, and options are:');
  print(argParser.usage);
}

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addOption("run-count",
      defaultsTo: "10", help: "How many previous runs should be fetched");
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  var runCount = int.parse(argResults['run-count'], onError: (_) => null);

  if (argResults.rest.length < 1 || argResults['help'] || runCount == null) {
    help(argParser);
    if (argResults['help']) return;
    exit(1);
  }

  Bot bot = new Bot(logdog: argResults['logdog']);
  await mainInternal(bot, argResults.rest, runCount: runCount);
  bot.close();
}

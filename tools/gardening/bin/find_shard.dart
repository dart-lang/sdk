#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Translates a buildbot shard name to the corresponding column group name
// on the buildbot site, such that it's easier to find the right column.
//
// Example: `bin/find_shard.dart precomp-linux-debug-x64-be`
// prints `vm-precomp(5): precomp-linux-debug-x64-be`.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:gardening/src/shard_data.dart';

ArgParser createArgParser() {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('help', help: "Help");
  return argParser;
}

bool INCLUDE_DEV =
    const bool.fromEnvironment('INCLUDE_DEV', defaultValue: false);
bool INCLUDE_STABLE =
    const bool.fromEnvironment('INCLUDE_STABLE', defaultValue: false);
bool INCLUDE_INTEGRATION =
    const bool.fromEnvironment('INCLUDE_INTEGRATION', defaultValue: false);

void processArgResults(ArgResults argResults) {
  if (argResults['include-all']) {
    INCLUDE_DEV = INCLUDE_STABLE = INCLUDE_INTEGRATION = true;
  } else {
    if (argResults['include-dev']) INCLUDE_DEV = true;
    if (argResults['include-stable']) INCLUDE_STABLE = true;
    if (argResults['include-integration']) INCLUDE_INTEGRATION = true;
  }
}

void help(ArgParser argParser) {
  print('Given a shard name or a substring thereof, search all buildbot');
  print('shard names and print matching ones, along with their group.');
  print('E.g., searching "drt" will show that there are several matching');
  print('shards, all in the group "chrome", which may be helpful when');
  print('navigating the buildbot web page based on blame email etc.\n');
  print('Usage: find_shard [options] <shard>');
  print('where options are:');
  print(argParser.usage);
}

bool shard_enabled(String shard) {
  if (shard.endsWith('-dev')) return INCLUDE_DEV;
  if (shard.endsWith('-stable')) return INCLUDE_STABLE;
  if (shard.endsWith('-integration')) return INCLUDE_INTEGRATION;
  return true;
}

Future main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag("include-dev",
      abbr: "d",
      defaultsTo: false,
      negatable: false,
      help: "Include shards named *-dev");
  argParser.addFlag("include-stable",
      abbr: "s",
      defaultsTo: false,
      negatable: false,
      help: "Include shards named *-stable");
  argParser.addFlag("include-integration",
      abbr: "i",
      defaultsTo: false,
      negatable: false,
      help: "Include shards named *-integration");
  argParser.addFlag("include-all",
      abbr: "a",
      defaultsTo: false,
      negatable: false,
      help: "Include all shards");
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);

  if (argResults.rest.length != 1 || argResults['help']) {
    help(argParser);
    if (argResults['help']) return;
    exit(1);
  }

  String arg = argResults.rest.first;
  for (String group in shardGroups.keys) {
    List<String> shardGroup = shardGroups[group];
    for (int i = 0; i < shardGroup.length; i++) {
      String shard = shardGroup[i];
      if (shard_enabled(shard) && shard.contains(arg)) {
        print("$group(${i+1}): $shard");
      }
    }
  }
}

#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Find the newest commit that has a full set of results on the bots.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:glob/glob.dart';

void main(List<String> args) async {
  final parser = new ArgParser();
  parser.addMultiOption("bot",
      abbr: "b",
      help: "Select the bots matching the glob pattern [option is repeatable]",
      splitCommas: false);
  parser.addOption("branch",
      abbr: "B",
      help: "Select the bots building this branch",
      defaultsTo: "master");
  parser.addOption("count",
      abbr: "c", help: "List this many commits", defaultsTo: "1");
  parser.addFlag("help", help: "Show the program usage.", negatable: false);

  final options = parser.parse(args);
  if (options["help"]) {
    print("""
Usage: find_base_commit.dart [OPTION]...
Find the newest commit that has a full set of results on the bots.

The options are as follows:

${parser.usage}""");
    return;
  }

  int count = int.parse(options["count"]);
  final globs = new List<Glob>.from(
      options["bot"].map((String pattern) => new Glob(pattern)));

  // Download the most recent builds from buildbucket.
  int maxBuilds = 1000;
  final url = Uri.parse(
      "https://cr-buildbucket.appspot.com/_ah/api/buildbucket/v1/search"
      "?bucket=luci.dart.ci.sandbox"
      "&max_builds=$maxBuilds"
      "&status=COMPLETED"
      "&fields=builds(url%2Cparameters_json)");
  const maxRetries = 3;
  const timeout = const Duration(seconds: 30);
  Map<String, dynamic> object;
  for (int i = 1; i <= maxRetries; i++) {
    try {
      final client = new HttpClient();
      final request = await client.getUrl(url).timeout(timeout);
      final response = await request.close().timeout(timeout);
      object = await response
          .cast<List<int>>()
          .transform(new Utf8Decoder())
          .transform(new JsonDecoder())
          .first
          .timeout(timeout);
      client.close();
      break;
    } on TimeoutException catch (e) {
      final inSeconds = e.duration.inSeconds;
      stderr.writeln(
          "Attempt $i of $maxRetries timed out after $inSeconds seconds");
      if (i == maxRetries) {
        stderr.writeln("error: Failed to download $url");
        exit(1);
      }
    }
  }

  // Locate the builds we're interested in and map them to each commit. The
  // builds returned by the API are sorted with the newest first. Since bots
  // don't build back in time and always build the latest commit whenever they
  // can, the first time we see a commit, we know it's newer than all commits
  // we haven't seen yet. The insertion order into the botsForCommits map will
  // then sorted with the newest commit first.
  final builds = object["builds"];
  final botsForCommits = <String, Set<String>>{};
  for (final build in builds) {
    final parameters = jsonDecode(build["parameters_json"]);
    final bot = parameters["builder_name"];
    if (bot.endsWith("-beta") ||
        bot.endsWith("-dev") ||
        bot.endsWith("-stable")) {
      // Ignore the release builders. The -try builders aren't in the
      // bucket we're reading.
      continue;
    }
    if (globs.isNotEmpty && !globs.any((glob) => glob.matches(bot))) {
      // Filter way bots we're not interested in.
      continue;
    }
    final properties = parameters["properties"];
    final branch = properties["branch"];
    if (branch != null && branch != "refs/heads/${options['branch']}") {
      // Ignore bots that are building the wrong branch.
      continue;
    }
    final commit = properties["revision"];
    if (commit == null) {
      // Ignore bots that aren't commit based, e.g. fuzz-linux.
      continue;
    }
    final botsForCommit =
        botsForCommits.putIfAbsent(commit, () => new Set<String>());
    botsForCommit.add(bot);
  }

  if (botsForCommits.isEmpty) {
    print("Failed to locate any commits having run on the bots");
    exitCode = 1;
    return;
  }

  int maxBots = 0;
  for (final commit in botsForCommits.keys) {
    maxBots = max(maxBots, botsForCommits[commit].length);
  }

  // List commits run on the most bots.
  for (final commit in botsForCommits.keys
      .where((commit) => botsForCommits[commit].length == maxBots)
      .take(count)) {
    print(commit);
  }
}

#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Find the newest commit that has a full set of results on the builders.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:glob/glob.dart';

void main(List<String> args) async {
  final parser = new ArgParser();
  parser.addMultiOption("builder",
      abbr: "b",
      help: "Select the builders matching the glob [option is repeatable]",
      splitCommas: false);
  parser.addOption("branch",
      abbr: "B",
      help: "Select the builders building this branch",
      defaultsTo: "master");
  parser.addOption("count",
      abbr: "c", help: "List this many commits", defaultsTo: "1");
  parser.addFlag("help", help: "Show the program usage.", negatable: false);

  final options = parser.parse(args);
  if (options["help"]) {
    print("""
Usage: find_base_commit.dart [OPTION]...
Find the newest commit that has a full set of results on the builders.

The options are as follows:

${parser.usage}""");
    return;
  }

  int count = int.parse(options["count"]);
  final globs = new List<Glob>.from(
      options["builder"].map((String pattern) => new Glob(pattern)));

  // Download the most recent builds from buildbucket.
  const maxBuilds = 1000;
  final url = Uri.parse("https://cr-buildbucket.appspot.com"
      "/prpc/buildbucket.v2.Builds/SearchBuilds");
  const maxRetries = 3;
  const timeout = const Duration(seconds: 30);
  final query = jsonEncode({
    "predicate": {
      "builder": {"project": "dart", "bucket": "ci.sandbox"},
      "status": "ENDED_MASK"
    },
    "pageSize": maxBuilds,
    "fields": "builds.*.builder.builder,builds.*.input"
  });
  late Map<String, dynamic> searchResult;
  for (int i = 1; i <= maxRetries; i++) {
    try {
      final client = new HttpClient();
      final request = await client.postUrl(url).timeout(timeout)
        ..headers.contentType = ContentType.json
        ..headers.add(HttpHeaders.acceptHeader, ContentType.json)
        ..write(query);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        print("Failed to search for builds: "
            "${response.statusCode}:${response.reasonPhrase}");
        exit(1);
      }
      const prefix = ")]}'";
      searchResult = await (response
          .cast<List<int>>()
          .transform(new Utf8Decoder())
          .map((event) =>
              event.startsWith(prefix) ? event.substring(prefix.length) : event)
          .transform(new JsonDecoder())
          .cast<Map<String, dynamic>>()
          .first
          .timeout(timeout));
      client.close();
      break;
    } on TimeoutException catch (e) {
      final inSeconds = e.duration?.inSeconds;
      stderr.writeln(
          "Attempt $i of $maxRetries timed out after $inSeconds seconds");
      if (i == maxRetries) {
        stderr.writeln("error: Failed to download $url");
        exit(1);
      }
    }
  }

  // Locate the builds we're interested in and map them to each commit. The
  // builds returned by the API are sorted with the newest first. Since builders
  // don't build back in time and always build the latest commit whenever they
  // can, the first time we see a commit, we know it's newer than all commits
  // we haven't seen yet. The insertion order into the buildersForCommits map
  // will then sorted with the newest commit first.
  final builds = searchResult["builds"];
  if (builds == null) {
    print("No builds found");
    exit(1);
  }
  final buildersForCommits = <String, Set<String>>{};
  for (final build in builds) {
    final builder = build["builder"]?["builder"];
    if (builder is! String ||
        builder.endsWith("-beta") ||
        builder.endsWith("-dev") ||
        builder.endsWith("-stable")) {
      // Ignore the release builders. The -try builders aren't in the
      // bucket we're reading.
      continue;
    }
    if (globs.isNotEmpty && !globs.any((glob) => glob.matches(builder))) {
      // Filter way builders we're not interested in.
      continue;
    }
    final input = build["input"]?["gitilesCommit"];
    if (input == null) {
      // Ignore builds not triggered by a commit, e.g. fuzz-linux.
      continue;
    }
    final ref = input["ref"];
    if (ref != "refs/heads/${options['branch']}") {
      // Ignore builds on the wrong branch.
      continue;
    }
    final commit = input["id"] as String;
    final buildersForCommit =
        buildersForCommits.putIfAbsent(commit, () => new Set<String>());
    buildersForCommit.add(builder);
  }

  if (buildersForCommits.isEmpty) {
    print("Failed to locate any commits having run on the builders");
    exitCode = 1;
    return;
  }

  int maxBots = 0;
  for (final builders in buildersForCommits.values) {
    maxBots = max(maxBots, builders.length);
  }

  // List commits run on the most builders.
  for (final commit in buildersForCommits.keys
      .where((commit) => buildersForCommits[commit]!.length == maxBots)
      .take(count)) {
    print(commit);
  }
}

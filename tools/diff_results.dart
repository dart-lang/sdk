#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:glob/glob.dart';

final parser = ArgParser()
  ..addMultiOption('bot',
      abbr: 'b',
      help: 'Select the bots matching the glob pattern [option is repeatable]',
      splitCommas: false)
  ..addFlag('verbose', abbr: 'v', help: 'Verbose output.', negatable: false)
  ..addFlag('help', help: 'Show the program usage.', negatable: false);

void printUsage() {
  print("""
Usage: ${Platform.executable} ${Platform.script} [OLDER_COMMIT] [NEWER_COMMIT]

The options are as follows:

${parser.usage}""");
}

bool verbose;

main(List<String> args) async {
  final options = parser.parse(args);
  if (options["help"]) {
    printUsage();
    return;
  }

  final commits = options.rest;
  if (commits.length < 2) {
    print('Need to supply at least two commits.');
    printUsage();
    exitCode = 1;
    return;
  }
  verbose = options['verbose'] ?? false;

  final globs = List<Glob>.from(options["bot"].map((pattern) => Glob(pattern)));
  final vmBuilders = loadVmBuildersFromTestMatrix(globs);

  final futures = <Future<List<Result>>>[];
  for (final commit in commits) {
    final DateTime date = await getDateOfCommit(commit);
    futures.add(getResults(commit, date, vmBuilders));
  }

  final results = await Future.wait(futures);
  for (int i = 0; i < results.length - 1; i++) {
    final commitB = commits[i];
    final commitA = commits[i + 1];

    print('\nResult changes between $commitB -> $commitA:');
    final commonGroups =
        buildCommonGroups(commitA, commitB, results[i], results[i + 1]);
    for (final commonGroup in commonGroups) {
      final builders = commonGroup.builders;

      print('');
      for (final group in commonGroup.groups) {
        final diff = group.diffs.first;
        print('${group.test} ${diff.before} -> ${diff.after}');
      }
      for (final b in extractBuilderPattern(builders)) {
        print('   on $b');
      }
    }
  }
}

Future<DateTime> getDateOfCommit(String commit) async {
  final result = await Process.run(
      'git', ['show', '-s', '--format=%cd', '--date=iso-strict', commit]);
  if (result.exitCode != 0) {
    print('Could not determine date of commit $commit. Git reported:\n');
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }
  return DateTime.parse(result.stdout.trim());
}

Future<List<Result>> getResults(
    String commit, DateTime dateC, Set<String> builders) async {
  final DateTime date0 = dateC.add(const Duration(hours: 24));
  final DateTime date2 = dateC.subtract(const Duration(hours: 24));
  final query = '''
      SELECT commit_time, builder_name, build_number, name, result, expected FROM `dart-ci.results.results`
      WHERE commit_hash="$commit"
        AND matches=false
        AND (_PARTITIONDATE = "${formatDate(date0)}" OR
             _PARTITIONDATE = "${formatDate(dateC)}" OR
             _PARTITIONDATE = "${formatDate(date2)}" )
        AND (STARTS_WITH(builder_name, "vm-") OR
             STARTS_WITH(builder_name, "app-") OR
             STARTS_WITH(builder_name, "cross-"))
        AND ((flaky is NULL) OR flaky=false)
        ORDER BY name''';

  final arguments = <String>[
    'query',
    '--format=prettyjson',
    '--project_id=dart-ci',
    '--nouse_legacy_sql',
    '-n',
    '1000000',
    query,
  ];
  if (verbose) {
    print('Executing query:\n    bq ${arguments.join(' ')}');
  }

  final result = await Process.run('bq', arguments);
  if (result.exitCode == 0) {
    File('$commit.json').writeAsStringSync(result.stdout);
    final resultsForCommit = json.decode(result.stdout);

    final results = <Result>[];
    for (final Map<String, dynamic> result in resultsForCommit) {
      final builderName = result['builder_name'];
      if (!builders.contains(builderName)) {
        continue;
      }

      final failure = Result(commit, builderName, result['build_number'],
          result['name'], result['expected'], result['result']);
      results.add(failure);
    }

    results.sort((Result a, Result b) {
      final c = a.name.compareTo(b.name);
      if (c != 0) return c;
      return a.builderName.compareTo(b.builderName);
    });

    return results;
  } else {
    print('Running the following query failed:\nbq ${arguments.join(' ')}');
    print('Exit code: ${result.exitCode}');
    final stdout = result.stdout.trim();
    if (stdout.length > 0) {
      print('Stdout:\n$stdout');
    }
    final stderr = result.stderr.trim();
    if (stderr.length > 0) {
      print('Stderr:\n$stderr');
    }
    return <Result>[];
  }
}

List<CommonGroup> buildCommonGroups(String commitA, String commitB,
    List<Result> commitResults, List<Result> commitResultsBefore) {
  // If a test has same outcome across many vm builders
  final diffs = <Diff>[];
  int i = 0;
  int j = 0;
  while (i < commitResultsBefore.length && j < commitResults.length) {
    final a = commitResultsBefore[i];
    final b = commitResults[j];

    // Is a smaller than b, then we had a failure before and no longer one.
    if (a.name.compareTo(b.name) < 0 ||
        (a.name.compareTo(b.name) == 0 &&
            a.builderName.compareTo(b.builderName) < 0)) {
      diffs.add(Diff(a, null));
      i++;
      continue;
    }

    // Is b smaller than a, then we had no failure before but have one now.
    if (b.name.compareTo(a.name) < 0 ||
        (b.name.compareTo(a.name) == 0 &&
            b.builderName.compareTo(a.builderName) < 0)) {
      diffs.add(Diff(null, b));
      j++;
      continue;
    }

    // Else we must have the same name and builder.
    if (a.name != b.name || a.builderName != b.builderName) throw 'BUG';

    if (a.expected != b.expected || a.result != b.result) {
      diffs.add(Diff(a, b));
    }
    i++;
    j++;
  }

  while (i < commitResultsBefore.length) {
    final a = commitResultsBefore[i++];
    diffs.add(Diff(a, null));
  }

  while (j < commitResults.length) {
    final b = commitResults[j++];
    diffs.add(Diff(null, b));
  }

  // If a test has same outcome across many vm builders
  final groups = <GroupedDiff>[];
  int h = 0;
  while (h < diffs.length) {
    final d = diffs[h++];
    final builders = Set<String>()..add(d.builder);
    final gropupDiffs = <Diff>[d];

    while (h < diffs.length) {
      final nd = diffs[h];
      if (d.test == nd.test) {
        if (d.sameExpectationDifferenceAs(nd)) {
          builders.add(nd.builder);
          gropupDiffs.add(nd);
          h++;
          continue;
        }
      }
      break;
    }

    groups.add(GroupedDiff(d.test, builders.toList()..sort(), gropupDiffs));
  }

  final commonGroups = <String, List<GroupedDiff>>{};
  for (final group in groups) {
    final key = group.builders.join(' ');
    commonGroups.putIfAbsent(key, () => <GroupedDiff>[]).add(group);
  }

  final commonGroupList = commonGroups.values
      .map((list) => CommonGroup(list.first.builders, list))
      .toList();
  commonGroupList
      .sort((a, b) => a.builders.length.compareTo(b.builders.length));
  return commonGroupList;
}

class CommonGroup {
  final List<String> builders;
  final List<GroupedDiff> groups;
  CommonGroup(this.builders, this.groups);
}

class GroupedDiff {
  final String test;
  final List<String> builders;
  final List<Diff> diffs;

  GroupedDiff(this.test, this.builders, this.diffs);
}

class Diff {
  final Result before;
  final Result after;

  Diff(this.before, this.after);

  String get test => before?.name ?? after?.name;
  String get builder => before?.builderName ?? after?.builderName;

  bool sameExpectationDifferenceAs(Diff other) {
    if ((before == null) != (other.before == null)) return false;
    if ((after == null) != (other.after == null)) return false;

    if (before != null) {
      if (!before.sameResult(other.before)) return false;
    }
    if (after != null) {
      if (!after.sameResult(other.after)) return false;
    }
    return true;
  }
}

class Result {
  final String commit;
  final String builderName;
  final String buildNumber;
  final String name;
  final String expected;
  final String result;

  Result(this.commit, this.builderName, this.buildNumber, this.name,
      this.expected, this.result);

  String toString() => '(expected: $expected, actual: $result)';

  bool sameResult(Result other) {
    return name == other.name &&
        expected == other.expected &&
        result == other.result;
  }

  bool equals(other) {
    if (other is Result) {
      if (name != other.name) return false;
      if (builderName != other.builderName) return false;
    }
    return false;
  }

  int get hashCode => name.hashCode ^ builderName.hashCode;
}

String currentDate() {
  final timestamp = DateTime.now().toUtc().toIso8601String();
  return timestamp.substring(0, timestamp.indexOf('T'));
}

Set<String> loadVmBuildersFromTestMatrix(List<Glob> globs) {
  final contents = File('tools/bots/test_matrix.json').readAsStringSync();
  final testMatrix = json.decode(contents);

  final vmBuilders = Set<String>();
  for (final config in testMatrix['builder_configurations']) {
    for (final builder in config['builders']) {
      if (builder.startsWith('vm-') || builder.startsWith('app-')) {
        vmBuilders.add(builder);
      }
    }
  }

  // This one is in the test_matrix.json but we don't run it on CI.
  vmBuilders.remove('vm-kernel-asan-linux-release-ia32');

  if (!globs.isEmpty) {
    vmBuilders.removeWhere((String builder) {
      return !globs.any((Glob glob) => glob.matches(builder));
    });
  }

  return vmBuilders;
}

List<String> extractBuilderPattern(List<String> builders) {
  final all = Set<String>.from(builders);

  String reduce(String builder, List<String> posibilities) {
    for (final pos in posibilities) {
      if (builder.contains(pos)) {
        final existing = <String>[];
        final available = <String>[];
        for (final pos2 in posibilities) {
          final builder2 = builder.replaceFirst(pos, pos2);
          if (all.contains(builder2)) {
            existing.add(builder2);
            available.add(pos2);
          }
        }
        if (existing.length > 1) {
          all.removeAll(existing);
          final replacement =
              builder.replaceFirst(pos, '{${available.join(',')}}');
          all.add(replacement);
          return replacement;
        }
      }
    }
    return builder;
  }

  for (String builder in builders) {
    if (all.contains(builder)) {
      builder = reduce(builder, const ['debug', 'release', 'product']);
    }
  }
  for (String builder in all.toList()) {
    if (all.contains(builder)) {
      builder = reduce(builder, const ['mac', 'linux', 'win']);
    }
  }

  for (String builder in all.toList()) {
    if (all.contains(builder)) {
      builder = reduce(builder, const [
        'ia32',
        'x64',
        'simarm',
        'simarm64',
        'arm',
        'arm64',
      ]);
    }
  }
  return all.toList()..sort();
}

String formatDate(DateTime date) {
  final s = date.toIso8601String();
  return s.substring(0, s.indexOf('T'));
}

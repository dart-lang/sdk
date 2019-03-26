#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Applies pending pre-approvals for any changelists that have landed according
// to the git history of HEAD.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'results.dart';

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag("dry",
      abbr: "n",
      help: "Don't write out the updated approvals.",
      negatable: false);
  parser.addMultiOption("apply-changelist",
      abbr: "A",
      help: "Apply this changelist even if it hasn't landed",
      splitCommas: false);
  parser.addFlag("help", help: "Show the program usage.", negatable: false);
  parser.addOption("upload",
      abbr: "u",
      help: "Upload the updated results to this cloud storage location");

  final options = parser.parse(args);
  if (options["help"]) {
    print("""
Usage: apply_preapprovals.dart [OPTION]... APPROVALS
Applies pending pre-approvals for any changelists that have landed according to
the git history of HEAD.

The options are as follows:

${parser.usage}""");
    return;
  }

  final parameters = options.rest;
  if (parameters.length != 1) {
    print("error: Expected one parameter");
    exitCode = 2;
    return;
  }

  // Locate gsutil.py.
  gsutilPy = Platform.script
      .resolve("../../third_party/gsutil/gsutil.py")
      .toFilePath();

  final approvalsPath = parameters[0];
  final approvals = await loadResultsMap(approvalsPath);

  // Find the changelists with pre-approvals.
  final allChangelists = <String>{};
  for (final key in approvals.keys) {
    final record = approvals[key];
    final preapprovals =
        record.putIfAbsent("preapprovals", () => <String, dynamic>{});
    allChangelists.addAll(preapprovals.keys);
  }
  if (allChangelists.isEmpty) {
    print("No pre-approvals are pending");
  }

  // Find the order the pre-approved changelists landed in.
  final joinedChangelistsPattern = allChangelists.join("\\|");
  final pattern = "^Change-Id: \\($joinedChangelistsPattern\\)\$";
  final arguments = [
    "rev-list",
    "--pretty=medium",
    "--grep=$pattern",
    "--reverse",
    "HEAD"
  ];
  final processOutput = await Process.run("git", arguments, runInShell: true);
  if (processOutput.exitCode != 0) {
    throw new Exception("Failed to run git $arguments\n"
        "exitCode: ${processOutput.exitCode}\n"
        "stdout: ${processOutput.stdout}\n"
        "stderr: ${processOutput.stderr}");
  }
  final landedChangelists = <String>[];
  final commitOfChangelist = <String, String>{};
  String currentCommit;
  for (final line in LineSplitter.split(processOutput.stdout)) {
    if (line.startsWith("commit ")) {
      currentCommit = line.substring("commit ".length);
    } else if (line.startsWith("    Change-Id: ")) {
      final changeId = line.substring("    Change-Id: ".length);
      if (allChangelists.contains(changeId)) {
        landedChangelists.add(changeId);
        commitOfChangelist[changeId] = currentCommit;
      }
    }
  }
  if (processOutput.stdout != "") {
    print(processOutput.stdout);
  }

  // Report the status of each of the pre-approved changelists.
  final unlandedChangelists =
      allChangelists.difference(landedChangelists.toSet());
  for (final changelist in unlandedChangelists) {
    final changelistUrl = "https://dart-review.googlesource.com/q/$changelist";
    print("Pending: Changelist $changelistUrl hasn't landed yet");
  }
  if (allChangelists.isNotEmpty && landedChangelists.isEmpty) {
    print("No pre-approved changelists have landed.");
  }
  for (final changelist in landedChangelists) {
    final changelistUrl = "https://dart-review.googlesource.com/q/$changelist";
    final commit = commitOfChangelist[changelist];
    print("Landed: Changelist $changelistUrl landed in commit $commit");
  }
  for (final changelist in options["apply-changelist"]) {
    final changelistUrl = "https://dart-review.googlesource.com/q/$changelist";
    print("Force applying: Pretending $changelistUrl has landed");
    landedChangelists.add(changelist);
  }

  // Apply the pre-approvals for landed changes.
  bool updated = false;
  final conflictsForKey = <String, List<String>>{};
  final changelistsWithMergeConflicts = <String>{};
  int totalNumberOfPreapprovals = 0;
  int totalNumberOfMergeConflicts = 0;
  for (final changelist in landedChangelists) {
    final changelistUrl = "https://dart-review.googlesource.com/q/$changelist";
    final commit = commitOfChangelist[changelist];
    print("\nApplying pre-approvals for changelist "
        "$changelistUrl landed in commit $commit");
    int numberOfPreapprovals = 0;
    int numberOfMergeConflicts = 0;
    for (final key in approvals.keys) {
      final record = approvals[key];
      final preapprovals = record["preapprovals"];
      final preapproval = preapprovals.remove(changelist);
      if (preapproval == null) continue;
      updated = true;
      final conflicts = conflictsForKey.putIfAbsent(key, () => <String>[]);
      if (record["result"] == preapproval["from"]) {
        print("$changelist: $key: "
            "${record["result"]} -> ${preapproval["result"]}");
        conflicts.add("$changelist/$commit had changed approval from "
            "${record["result"]} to ${preapproval["result"]}");
        record["result"] = preapproval["result"];
        record["matches"] = preapproval["matches"];
        record["expected"] = preapproval["expected"];
        record["approver"] = preapproval["preapprover"];
        record["approved_at"] = preapproval["preapproved_at"];
        numberOfPreapprovals++;
        totalNumberOfPreapprovals++;
      } else {
        print("$changelist: $key: MERGE CONFLICT:");
        for (final conflict in conflicts) {
          print(" * $conflict");
        }
        print(" * MERGE CONFLICT: Cannot change approval from "
            "${preapproval["from"]} to ${preapproval["result"]} "
            "because it's currently ${record["result"]}");
        changelistsWithMergeConflicts.add(changelist);
        numberOfMergeConflicts++;
        totalNumberOfMergeConflicts++;
      }
    }
    if (0 < numberOfPreapprovals) {
      print("$numberOfPreapprovals "
          "pre-approvals applied from $changelistUrl commit $commit");
    }
    if (0 < numberOfMergeConflicts) {
      print("Warning: $numberOfMergeConflicts "
          "merge conflicts in pre-approvals for $changelistUrl commit $commit");
    }
  }

  // Expire old pre-approvals.
  final now = new DateTime.now().toUtc();
  final expiredChangelists = <String>{};
  for (final record in approvals.values) {
    final preapprovals = record["preapprovals"];
    final changelists = preapprovals.keys.toList();
    for (final changelist in changelists) {
      final preapproval = preapprovals[changelist];
      final expires = DateTime.parse(preapproval["expires"]);
      if (expires.isBefore(now)) {
        updated = true;
        preapprovals.remove(changelist);
        expiredChangelists.add(changelist);
      }
    }
  }
  if (expiredChangelists.isNotEmpty) {
    print("");
  }
  for (final changelist in expiredChangelists) {
    final changelistUrl = "https://dart-review.googlesource.com/q/$changelist";
    print("Expired: Pre-approvals for changelist $changelistUrl have expired");
  }

  // Format a final report.
  print("");
  final landedChangelistsCount = landedChangelists.length;
  if (0 < landedChangelistsCount) {
    print("$landedChangelistsCount changelists have landed");
  }
  final expiredChangelistsCount = expiredChangelists.length;
  if (0 < expiredChangelistsCount) {
    print("$expiredChangelistsCount changelists have expired");
  }
  final unlandedChangelistsCount =
      unlandedChangelists.length - expiredChangelistsCount;
  if (0 < unlandedChangelistsCount) {
    print("$unlandedChangelistsCount changelists are pending");
  }
  if (0 < totalNumberOfPreapprovals) {
    print("$totalNumberOfPreapprovals pre-approvals applied");
  }
  if (0 < totalNumberOfPreapprovals) {
    print("Warning: $totalNumberOfMergeConflicts "
        "pre-approvals had merge conflicts");
  }

  // Save the updated approvals and upload them to cloud storage.
  print("");
  if (!updated) {
    print("Approvals are unchanged");
    return;
  }
  if (options["dry"]) {
    print("Dry run, not saving the updated approvals");
    return;
  }
  await new File(approvalsPath).writeAsString(
      approvals.values.map((data) => jsonEncode(data) + "\n").join(""));
  print("Wrote updated approvals to $approvalsPath");
  if (options["upload"] != null) {
    print("Uploading updated approvals to ${options["upload"]}...");
    await cpGsutil(approvalsPath, options["upload"]);
    print("Uploaded updated approvals to ${options["upload"]}");
  }
}

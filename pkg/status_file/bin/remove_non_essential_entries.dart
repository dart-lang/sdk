// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Removes all status file expectations that are not relevant in the
// new workflow, but preserves entries with comments.
//
// For example, using the script on this status file
//   a: Crash
//   b: RuntimeError
//   c: RuntimeError # Comment
//   d: Pass, RuntimeError
//   e: Pass, Slow, RuntimeError
//   f: Pass, Slow, RuntimeError # Another comment
// will produce the output
//   c: RuntimeError # Comment
//   e: Slow
//   f: Pass, Slow, RuntimeError # Another comment
//
// When using the option to keep crashes, there will be an additional line
//   a: Crash
//
// The option -r can be used to also process expectations in lines with
// comments. In this mode, deleted comments are collected and either printed
// out or written to a separate file (with -w).
//
// The option -i (with -r) tries to resolve the status of issues mentioned in
// comments and adds it to the collected comments. This requires an issue.log
// file as described in [parseIssueFile].

import 'dart:io';

import 'package:args/args.dart';
import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/expectation.dart';

StatusEntry filterExpectations(
    StatusEntry entry, List<Expectation> expectationsToKeep) {
  List<Expectation> remaining = entry.expectations
      .where(
          (Expectation expectation) => expectationsToKeep.contains(expectation))
      .toList();
  return remaining.isEmpty
      ? null
      : StatusEntry(entry.path, entry.lineNumber, remaining, entry.comment);
}

Map<String, Map<int, String>> issues;

String getIssueState(String project, int issue) {
  Map projectIssues = issues[project];
  if (projectIssues == null) {
    throw "Cannot find project $project, not one of {${issues.keys.join(",")}}";
  }
  String state = projectIssues[issue] ?? "";
  return "\t$state";
}

// This method assumes the following data format:
//  <project>, <state>, <issue number>, <update timestamp>
// sorted by issue number then timestamp ascending.
//
// The first line is expected to contain the field names and is skipped.
void parseIssueFile() async {
  issues = {};
  String issuesLog = await File("issues.log").readAsString();
  List<String> lines = issuesLog.split("\n");
  for (String line in lines.skip(1).where((line) => line.isNotEmpty)) {
    List<String> fields = line.split(",");
    if (fields.length != 4) {
      throw "invalid issue state line $line";
    }
    String project = fields[0];
    String state = fields[1];
    int issueNumber = int.parse(fields[2]);
    issues.putIfAbsent(project, () => {})[issueNumber] = state;
  }
}

List<RegExp> co19IssuePatterns = [
  RegExp(r"https://github.com/dart-lang/co19/issues/(\d+)"),
  RegExp(r"co19 issue (\d+)"),
];

List<RegExp> sdkIssuePatterns = [
  RegExp(r"[Ii]ssue (\d+)"),
  RegExp(r"#(\d+)"),
  RegExp(r"^(\d+)$"),
  RegExp(r"http://dartbug.com/(\d+)"),
  RegExp(r"https://github.com/dart-lang/sdk/issues/(\d+)"),
];

String getIssueText(String comment, bool resolveState) {
  int issue;
  String prefix;
  String project;
  for (RegExp pattern in co19IssuePatterns) {
    Match match = pattern.firstMatch(comment);
    if (match != null) {
      issue = int.tryParse(match[1]);
      if (issue != null) {
        prefix = "https://github.com/dart-lang/co19/issues/";
        project = "dart-lang/co19";
        break;
      }
    }
  }
  if (issue == null) {
    for (RegExp pattern in sdkIssuePatterns) {
      Match match = pattern.firstMatch(comment);
      if (match != null) {
        issue = int.tryParse(match[1]);
        if (issue != null) {
          prefix = "https://dartbug.com/";
          project = "dart-lang/sdk";
          break;
        }
      }
    }
  }
  if (issue != null) {
    String state = resolveState ? getIssueState(project, issue) : "";
    return "$prefix$issue$state";
  } else {
    return "";
  }
}

Future<StatusFile> removeNonEssentialEntries(
    StatusFile statusFile,
    List<Expectation> expectationsToKeep,
    bool removeComments,
    List<String> comments,
    bool resolveIssueState) async {
  List<StatusSection> sections = <StatusSection>[];
  for (StatusSection section in statusFile.sections) {
    bool hasStatusEntries = false;
    List<Entry> entries = <Entry>[];
    for (Entry entry in section.entries) {
      if (entry is EmptyEntry) {
        entries.add(entry);
      } else if (entry is CommentEntry) {
        entries.add(entry);
        hasStatusEntries = true;
      } else if (entry is StatusEntry) {
        StatusEntry newEntry = entry;
        if (entry.comment == null) {
          newEntry = filterExpectations(entry, expectationsToKeep);
        } else if (removeComments) {
          newEntry = filterExpectations(entry, expectationsToKeep);
          // Store comment if entry will be removed.
          if (newEntry == null) {
            String comment = entry.comment.toString().substring(1).trim();
            String testName = entry.path;
            String expectations = entry.expectations.toString();
            // Remove '[' and ']'.
            expectations = expectations.substring(1, expectations.length - 1);
            String conditionPrefix =
                section.condition != null ? "${section.condition}" : "";
            String issueText = await getIssueText(comment, resolveIssueState);
            String statusLine = "$conditionPrefix\t$testName\t$expectations"
                "\t$comment\t$issueText";
            comments.add(statusLine);
          }
        }
        if (newEntry != null) {
          entries.add(newEntry);
          hasStatusEntries = true;
        }
      } else {
        throw "Unknown entry type ${entry.runtimeType}";
      }
    }
    bool isDefaultSection = section.condition == null;
    if (hasStatusEntries ||
        (isDefaultSection && section.sectionHeaderComments.isNotEmpty)) {
      StatusSection newSection =
          StatusSection(section.condition, -1, section.sectionHeaderComments);
      newSection.entries.addAll(entries);
      sections.add(newSection);
    }
  }
  StatusFile newStatusFile = StatusFile(statusFile.path);
  newStatusFile.sections.addAll(sections);
  return newStatusFile;
}

ArgParser buildParser() {
  var parser = ArgParser();
  parser.addFlag("overwrite",
      abbr: 'w',
      negatable: false,
      defaultsTo: false,
      help: "Overwrite input file with output.");
  parser.addFlag("keep-crashes",
      abbr: 'c', negatable: false, defaultsTo: false);
  parser.addFlag("remove-comments",
      abbr: 'r', negatable: false, defaultsTo: false);
  parser.addFlag("resolve-issue-states",
      abbr: 'i', negatable: false, defaultsTo: false);
  parser.addFlag("help",
      abbr: "h",
      negatable: false,
      defaultsTo: false,
      help: "Show help and commands for this tool.");
  return parser;
}

void printHelp(ArgParser parser) {
  print("Usage: dart pkg/status_file/bin/remove_non_essential_entries.dart"
      " <path>");
  print(parser.usage);
}

String formatComments(List<String> comments) {
  StringBuffer sb = new StringBuffer();
  for (String statusLine in comments) {
    sb.writeln(statusLine);
  }
  return sb.toString();
}

main(List<String> arguments) async {
  var parser = buildParser();
  var results = parser.parse(arguments);
  if (results["help"] || results.rest.isEmpty) {
    printHelp(parser);
    return;
  }

  final List<Expectation> expectationsToKeep = <Expectation>[
    Expectation.skip,
    Expectation.skipByDesign,
    Expectation.skipSlow,
    Expectation.slow,
    Expectation.extraSlow
  ];

  if (results["keep-crashes"]) {
    expectationsToKeep.add(Expectation.crash);
  }

  bool removeComments = results["remove-comments"];

  for (String path in results.rest) {
    List<String> comments = [];

    bool writeFile = results["overwrite"];
    bool resolveGithubIssueState = results["resolve-issue-states"];
    var statusFile = StatusFile.read(path);
    if (resolveGithubIssueState) {
      await parseIssueFile();
    }
    statusFile = await removeNonEssentialEntries(statusFile, expectationsToKeep,
        removeComments, comments, resolveGithubIssueState);
    if (writeFile) {
      await File(path).writeAsString(statusFile.toString());
      print("Wrote $path.");
      if (removeComments) {
        await File("$path.csv").writeAsString(formatComments(comments));
        print("Wrote $path.csv.");
      }
    } else {
      print(statusFile);
      if (removeComments) {
        print("");
        print(formatComments(comments));
      }
    }
  }
}

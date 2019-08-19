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

StatusFile removeNonEssentialEntries(
    StatusFile statusFile, List<Expectation> expectationsToKeep) {
  List<StatusSection> sections = <StatusSection>[];
  for (StatusSection section in statusFile.sections) {
    bool hasStatusEntries = false;
    List<Entry> entries = <Entry>[];
    for (Entry entry in section.entries) {
      if (entry is EmptyEntry) {
        entries.add(entry);
      } else if (entry is StatusEntry && entry.comment != null ||
          entry is CommentEntry) {
        entries.add(entry);
        hasStatusEntries = true;
      } else if (entry is StatusEntry) {
        StatusEntry newEntry = filterExpectations(entry, expectationsToKeep);
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

main(List<String> arguments) {
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

  for (String path in results.rest) {
    bool writeFile = results["overwrite"];
    var statusFile = StatusFile.read(path);
    statusFile = removeNonEssentialEntries(statusFile, expectationsToKeep);
    if (writeFile) {
      File(path).writeAsStringSync(statusFile.toString());
      print("Modified $path.");
    } else {
      print(statusFile);
    }
  }
}

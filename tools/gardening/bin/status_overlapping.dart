// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:status_file/src/expression.dart';
import 'package:status_file/src/disjunctive.dart';

import 'package:gardening/src/extended_printer.dart';
import 'package:gardening/src/results/status_files.dart';
import 'package:gardening/src/results/testpy_wrapper.dart';
import 'package:gardening/src/util.dart';

ArgParser buildParser() {
  var argParser = new ArgParser();
  argParser.addFlag("print-test",
      negatable: false, help: "Print entries in status files for each test");
  argParser.addFlag("help",
      negatable: false, help: "Show information about the use of the tool.");
  return argParser;
}

void printHelp(ArgParser argParser) {
  print("Checks a suite of status files for duplicate "
      "entries. Usage: status.dart <suite> or status.dart <suite> <test>");
  print(argParser.usage);
}

Future main(List<String> args) async {
  var argParser = buildParser();
  var argResults = argParser.parse(args);
  if (argResults['help']) {
    printHelp(argParser);
    return;
  }
  if (argResults.rest.length == 0 || argResults.rest.length > 2) {
    print("Incorrect number of arguments.\n");
    printHelp(argParser);
    return;
  }
  var suite = argResults.rest.first;
  bool hasSpecificTest = argResults.rest.length == 2;
  String testArg = hasSpecificTest ? "$suite/${argResults.rest.last}" : suite;

  Map<String, Iterable<String>> statusFilesMap =
      await statusFileListerMapFromArgs([testArg]);
  var statusFilePaths = statusFilesMap[suite].map((file) {
    return "${PathHelper.sdkRepositoryRoot()}/$file";
  }).where((sf) {
    return new File(sf).existsSync();
  }).toList();

  StatusFiles statusFilesWrapper = StatusFiles.read(statusFilePaths);

  Map<String, List<StatusSectionEntry>> testsWithOverlappingSections = {};
  if (!hasSpecificTest) {
    // Get all tests from test.py and check every one.
    var suiteTests = await testsForSuite(suite);
    testsWithOverlappingSections = getTestsThatOverlap(
        suiteTests.map((test) => getQualifiedNameForTest(test)).toList(),
        statusFilesWrapper);
  } else {
    testsWithOverlappingSections =
        getTestsThatOverlap([argResults.rest.last], statusFilesWrapper);
  }

  if (testsWithOverlappingSections.isNotEmpty) {
    ExtendedPrinter printer = new ExtendedPrinter();
    if (argResults["print-test"]) {
      printOverlappingSectionsForTest(printer, testsWithOverlappingSections);
    } else {
      printOverlappingSectionsForTestsGrouped(
          printer, testsWithOverlappingSections);
    }
  } else {
    print("No overlapping sections.");
    print("");
  }
}

/// Checks if [source] is a subset of [target], which is the same as checking
/// [target] implies [source]. An expression can be either [VariableExpression],
/// [ComparisonExpression], [NegationExpression] or [LogicExpression].
///
/// The only non-unary is [LogicExpression].
///
/// We assume [source] and [target] are on disjunctive normal form.
///
/// If source is null or have no operands, it is trivially a subset since
/// everything implies [source].
/// If target is null (and source is not null) then [source] can never be a
/// subset.
///
/// In all other cases, we check if source or target is LogicExpression and is
/// joined by or and split these up into smaller tests.
bool isSubset(Expression source, Expression target) {
  if (source == null || target == null) {
    // This happens for the default region, which is always true.
    return true;
  }
  if (source is LogicExpression && source.operands.isEmpty) {
    return true;
  }
  if (target is LogicExpression && target.operands.isEmpty) {
    return false;
  }
  if (source is LogicExpression && source.isOr) {
    return source.operands.any((exp) => isSubset(exp, target));
  }
  if (target is LogicExpression && target.isOr) {
    return target.operands.any((exp) => isSubsetNoDisjuncts(source, exp));
  }
  return isSubsetNoDisjuncts(source, target);
}

/// Should only be called if [source] and [target] is on disjunctive normal
/// form and if the [LogicExpression] is not joined by or's.
///
/// It is easy to check if subset, by just casing.
bool isSubsetNoDisjuncts(Expression source, Expression target) {
  if (source is! LogicExpression && target is! LogicExpression) {
    return source.compareTo(target) == 0;
  }
  if (source is! LogicExpression) {
    return (target as LogicExpression)
        .operands
        .any((exp) => source.compareTo(exp) == 0);
  }
  if (source is LogicExpression &&
      source.operands.length > 1 &&
      target is! LogicExpression) {
    return false;
  }
  if (source is LogicExpression &&
      target is LogicExpression &&
      source.operands.length > target.operands.length) {
    return false;
  }
  var sourceLogic = source as LogicExpression;
  var targetLogic = target as LogicExpression;
  return sourceLogic.operands.every(
      (exp1) => targetLogic.operands.any((exp2) => exp1.compareTo(exp2) == 0));
}

Map<String, List<StatusSectionEntry>> getTestsThatOverlap(
    List<String> tests, StatusFiles statusFiles) {
  var dnfExpressionsCache = <StatusSectionEntry, Expression>{};
  Map<String, List<StatusSectionEntry>> results = {};
  for (var test in tests) {
    var sectionEntries = statusFiles.sectionsWithTest(test);
    if (sectionEntries.length > 1) {
      // Find out if two sections overlap
      var overlapping = <StatusSectionEntry>[];
      for (var i = 0; i < sectionEntries.length; i++) {
        for (var j = i + 1; j < sectionEntries.length; j++) {
          var dnfFirst = dnfExpressionsCache.putIfAbsent(
              sectionEntries[i],
              () =>
                  toDisjunctiveNormalForm(sectionEntries[i].section.condition));
          var dnfOther = dnfExpressionsCache.putIfAbsent(
              sectionEntries[j],
              () =>
                  toDisjunctiveNormalForm(sectionEntries[j].section.condition));
          if (isSubset(dnfFirst, dnfOther) || isSubset(dnfOther, dnfFirst)) {
            overlapping.add(sectionEntries[i]);
            overlapping.add(sectionEntries[j]);
          }
        }
        if (overlapping.isNotEmpty) {
          results[test] = overlapping;
        }
      }
    }
  }
  return results;
}

void printOverlappingSectionsForTest(ExtendedPrinter printer,
    Map<String, List<StatusSectionEntry>> testSectionEntries) {
  for (var test in testSectionEntries.keys) {
    printer.println(test);
    printer.printLinePattern("*");
    printer.printIterable(testSectionEntries[test], (StatusSectionEntry entry) {
      return "${entry.section.lineNumber}: [ ${entry.section.condition} ]\n"
          "\t${entry.entry.lineNumber}: ${entry.entry.path}: "
          "${entry.entry.expectations}";
    }, header: (StatusSectionEntry entry) {
      return entry.statusFile.path;
    }, itemPreceding: "\t");
  }
}

void printOverlappingSectionsForTestsGrouped(ExtendedPrinter printer,
    Map<String, List<StatusSectionEntry>> testSectionEntries) {
  Iterable<StatusSectionEntry> expandedResult =
      testSectionEntries.values.expand((id) => id);
  var allFiles = expandedResult.map((result) => result.statusFile).toSet();
  for (var file in allFiles) {
    printer.preceding = "";
    printer.println(file.path);
    var all = expandedResult.where((x) => x.statusFile == file).toList();
    all.sort((a, b) => a.entry.lineNumber.compareTo(b.entry.lineNumber));
    var sections = all.map((entry) => entry.section).toSet();
    for (var section in sections) {
      printer.preceding = "\t";
      printer.println("${section.lineNumber}: [ ${section.condition} ]");
      var entries = all
          .where((entry) => entry.section == section)
          .map((entry) => entry.entry)
          .toSet();
      printer.preceding = "\t\t";
      for (var entry in entries) {
        printer.println("${entry.lineNumber}: "
            "${entry.path}: "
            "${entry.expectations}");
      }
      printer.println("");
    }
  }
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/diff.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

/// A command that computes the diff between two info files.
class DiffCommand extends Command<void> with PrintUsageException {
  final String name = "diff";
  final String description =
      "See code size differences between two dump-info files.";

  DiffCommand() {
    argParser.addFlag('summary-only',
        defaultsTo: false,
        help: "Show only a summary and hide details of each library");
  }

  void run() async {
    var args = argResults.rest;
    if (args.length < 2) {
      usageException(
          'Missing arguments, expected two dump-info files to compare');
      return;
    }

    var oldInfo = await infoFromFile(args[0]);
    var newInfo = await infoFromFile(args[1]);
    var summaryOnly = argResults['summary-only'];

    var diffs = diff(oldInfo, newInfo);

    // Categorize the diffs
    var adds = <AddDiff>[];
    var removals = <RemoveDiff>[];
    var sizeChanges = <SizeDiff>[];
    var becameDeferred = <DeferredStatusDiff>[];
    var becameUndeferred = <DeferredStatusDiff>[];

    for (var diff in diffs) {
      switch (diff.kind) {
        case DiffKind.add:
          adds.add(diff as AddDiff);
          break;
        case DiffKind.remove:
          removals.add(diff as RemoveDiff);
          break;
        case DiffKind.size:
          sizeChanges.add(diff as SizeDiff);
          break;
        case DiffKind.deferred:
          var deferredDiff = diff as DeferredStatusDiff;
          if (deferredDiff.wasDeferredBefore) {
            becameUndeferred.add(deferredDiff);
          } else {
            becameDeferred.add(deferredDiff);
          }
          break;
      }
    }

    // Sort the changes by the size of the element that changed.
    for (var diffs in [adds, removals, becameDeferred, becameUndeferred]) {
      diffs.sort((a, b) => b.info.size - a.info.size);
    }

    // Sort changes in size by size difference.
    sizeChanges.sort((a, b) => b.sizeDifference - a.sizeDifference);

    var totalSizes = <List<Diff>, int>{};
    for (var diffs in [adds, removals, becameDeferred, becameUndeferred]) {
      var totalSize = 0;
      for (var diff in diffs) {
        // Only count diffs from leaf elements so we don't double count
        // them when we account for class size diff or library size diff.
        if (diff.info.kind == InfoKind.field ||
            diff.info.kind == InfoKind.function ||
            diff.info.kind == InfoKind.closure ||
            diff.info.kind == InfoKind.typedef) {
          totalSize += diff.info.size;
        }
      }
      totalSizes[diffs] = totalSize;
    }
    var totalSizeChange = 0;
    for (var sizeChange in sizeChanges) {
      // Only count diffs from leaf elements so we don't double count
      // them when we account for class size diff or library size diff.
      if (sizeChange.info.kind == InfoKind.field ||
          sizeChange.info.kind == InfoKind.function ||
          sizeChange.info.kind == InfoKind.closure ||
          sizeChange.info.kind == InfoKind.typedef) {
        totalSizeChange += sizeChange.sizeDifference;
      }
    }
    totalSizes[sizeChanges] = totalSizeChange;

    reportSummary(oldInfo, newInfo, adds, removals, sizeChanges, becameDeferred,
        becameUndeferred, totalSizes);
    if (!summaryOnly) {
      print('');
      reportFull(oldInfo, newInfo, adds, removals, sizeChanges, becameDeferred,
          becameUndeferred, totalSizes);
    }
  }
}

void reportSummary(
    AllInfo oldInfo,
    AllInfo newInfo,
    List<AddDiff> adds,
    List<RemoveDiff> removals,
    List<SizeDiff> sizeChanges,
    List<DeferredStatusDiff> becameDeferred,
    List<DeferredStatusDiff> becameUndeferred,
    Map<List<Diff>, int> totalSizes) {
  var overallSizeDiff = newInfo.program.size - oldInfo.program.size;
  print('total_size_difference $overallSizeDiff');

  print('total_added ${totalSizes[adds]}');
  print('total_removed ${totalSizes[removals]}');
  print('total_size_changed ${totalSizes[sizeChanges]}');
  print('total_became_deferred ${totalSizes[becameDeferred]}');
  print('total_no_longer_deferred ${totalSizes[becameUndeferred]}');
}

void reportFull(
    AllInfo oldInfo,
    AllInfo newInfo,
    List<AddDiff> adds,
    List<RemoveDiff> removals,
    List<SizeDiff> sizeChanges,
    List<DeferredStatusDiff> becameDeferred,
    List<DeferredStatusDiff> becameUndeferred,
    Map<List<Diff>, int> totalSizes) {
  // TODO(het): Improve this output. Siggi has good suggestions in
  // https://github.com/dart-lang/dart2js_info/pull/19

  _section('ADDED', size: totalSizes[adds]);
  for (var add in adds) {
    print('${longName(add.info, useLibraryUri: true)}: ${add.info.size} bytes');
  }
  print('');

  _section('REMOVED', size: totalSizes[removals]);
  for (var removal in removals) {
    print('${longName(removal.info, useLibraryUri: true)}: '
        '${removal.info.size} bytes');
  }
  print('');

  _section('CHANGED SIZE', size: totalSizes[sizeChanges]);
  for (var sizeChange in sizeChanges) {
    print('${longName(sizeChange.info, useLibraryUri: true)}: '
        '${sizeChange.sizeDifference} bytes');
  }
  print('');

  _section('BECAME DEFERRED', size: totalSizes[becameDeferred]);
  for (var diff in becameDeferred) {
    print('${longName(diff.info, useLibraryUri: true)}: '
        '${diff.info.size} bytes');
  }
  print('');

  _section('NO LONGER DEFERRED', size: totalSizes[becameUndeferred]);
  for (var diff in becameUndeferred) {
    print('${longName(diff.info, useLibraryUri: true)}: '
        '${diff.info.size} bytes');
  }
}

void _section(String title, {int size}) {
  print('$title ($size bytes)');
  print('=' * 72);
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2js_info/src/diff.dart';
import 'package:dart2js_info/src/util.dart';

/// A command-line tool that computes the diff between two info files.
main(List<String> args) async {
  if (args.length != 2) {
    print('usage: dart2js_info_diff old.info.json new.info.json');
    return;
  }
  var oldInfo = await infoFromFile(args[0]);
  var newInfo = await infoFromFile(args[1]);

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

  // TODO(het): Improve this output. Siggi has good suggestions in
  // https://github.com/dart-lang/dart2js_info/pull/19
  var overallSizeDiff = newInfo.program.size - oldInfo.program.size;
  _section('OVERALL SIZE DIFFERENCE');
  print('$overallSizeDiff bytes');
  print('');

  _section('ADDED');
  for (var add in adds) {
    print('${longName(add.info, useLibraryUri: true)}: ${add.info.size} bytes');
  }
  print('');

  _section('REMOVED');
  for (var removal in removals) {
    print('${longName(removal.info, useLibraryUri: true)}: '
        '${removal.info.size} bytes');
  }
  print('');

  _section('CHANGED SIZE');
  for (var sizeChange in sizeChanges) {
    print('${longName(sizeChange.info, useLibraryUri: true)}: '
        '${sizeChange.sizeDifference} bytes');
  }
  print('');

  _section('BECAME DEFERRED');
  for (var diff in becameDeferred) {
    print('${longName(diff.info, useLibraryUri: true)}: '
        '${diff.info.size} bytes');
  }
  print('');

  _section('NO LONGER DEFERRED');
  for (var diff in becameUndeferred) {
    print('${longName(diff.info, useLibraryUri: true)}: '
        '${diff.info.size} bytes');
  }
}

void _section(String title) {
  print(title);
  print('=' * 72);
}

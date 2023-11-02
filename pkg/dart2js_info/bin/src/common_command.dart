// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/common_element.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

/// A command that computes the commonalities between two info files.
class CommonCommand extends Command<void> with PrintUsageException {
  @override
  final String name = "common";
  @override
  final String description =
      "See code element commonalities between two dump-info files.";

  CommonCommand() {
    argParser.addFlag('packages-only',
        defaultsTo: false,
        help: "Show only packages in common. "
            "Cannot be used with `main-only`.");
    argParser.addFlag('order-by-size',
        defaultsTo: false,
        help: "Show output ordered by size in bytes (decreasing). "
            "If there are size discrepancies, orders by the first "
            "dump-info file's reported size.");
    argParser.addFlag('main-only',
        defaultsTo: false,
        help: "Only shows output comparison for main output unit. Provides "
            "results by class and member rather than by library. "
            "Cannot be used with `packages-only`.");
  }

  @override
  void run() async {
    final argRes = argResults!;
    final args = argRes.rest;
    if (args.length < 2) {
      usageException(
          'Missing arguments, expected two dump-info files to compare');
    }

    var oldInfo = await infoFromFile(args[0]);
    var newInfo = await infoFromFile(args[1]);
    bool packagesOnly = argRes['packages-only'];
    bool orderBySize = argRes['order-by-size'];
    bool mainOnly = argRes['main-only'];
    if (packagesOnly && mainOnly) {
      throw ArgumentError(
          'Only one of `main-only` and `packages-only` can be provided.');
    }

    var commonElements =
        findCommonalities(oldInfo, newInfo, mainOnly: mainOnly);

    if (packagesOnly) {
      reportPackages(commonElements, orderBySize: orderBySize);
    } else {
      report(commonElements, orderBySize: orderBySize);
    }
  }
}

void report(List<CommonElement> commonElements, {orderBySize = false}) {
  var oldSizeTotal = 0, newSizeTotal = 0;
  for (var element in commonElements) {
    // Only sum sizes from leaf elements so we don't double count.
    if (element.oldInfo.kind == InfoKind.field ||
        element.oldInfo.kind == InfoKind.function ||
        element.oldInfo.kind == InfoKind.closure ||
        element.oldInfo.kind == InfoKind.typedef) {
      oldSizeTotal += element.oldInfo.size;
      newSizeTotal += element.newInfo.size;
    }
  }

  _section('COMMON ELEMENTS',
      elementCount: commonElements.length,
      oldSizeTotal: oldSizeTotal,
      newSizeTotal: newSizeTotal);

  if (orderBySize) {
    commonElements.sort((a, b) => b.oldInfo.size.compareTo(a.oldInfo.size));
  } else {
    commonElements.sort((a, b) => a.name.compareTo(b.name));
  }

  for (var element in commonElements) {
    var oldSize = element.oldInfo.size;
    var newSize = element.newInfo.size;
    if (oldSize == newSize) {
      print('${element.name}: ${element.oldInfo.size} bytes');
    } else {
      print('${element.name}: ${element.oldInfo.size} -> '
          '${element.newInfo.size} bytes');
    }
  }
}

void reportPackages(List<CommonElement> commonElements, {orderBySize = false}) {
  // Maps package names to their cumulative size.
  var oldPackageInfo = <String, int>{};
  var newPackageInfo = <String, int>{};

  for (int i = 0; i < commonElements.length; i++) {
    var element = commonElements[i];
    // Skip non-libraries to avoid double counting elements when accumulating
    // package-level information.
    if (element.oldInfo.kind != InfoKind.library) continue;

    var package = packageName(element.oldInfo);
    if (package == null) continue;

    var oldSize = element.oldInfo.size;
    var newSize = element.newInfo.size;
    oldPackageInfo[package] = (oldPackageInfo[package] ?? 0) + oldSize;
    newPackageInfo[package] = (newPackageInfo[package] ?? 0) + newSize;
  }

  var oldSizeTotal = 0, newSizeTotal = 0;
  oldPackageInfo.forEach((oldPackageName, oldPackageSize) {
    var newPackageSize = newPackageInfo[oldPackageName]!;
    oldSizeTotal += oldPackageSize;
    newSizeTotal += newPackageSize;
  });

  _section('COMMON ELEMENTS (PACKAGES)',
      elementCount: oldPackageInfo.keys.length,
      oldSizeTotal: oldSizeTotal,
      newSizeTotal: newSizeTotal);

  var packageInfoEntries = oldPackageInfo.entries.toList();

  if (orderBySize) {
    packageInfoEntries.sort((a, b) => b.value.compareTo(a.value));
  } else {
    packageInfoEntries.sort((a, b) => a.key.compareTo(b.key));
  }

  for (var entry in packageInfoEntries) {
    var oldSize = entry.value;
    var newSize = newPackageInfo[entry.key];
    if (oldSize == newSize) {
      print('${entry.key}: $oldSize bytes');
    } else {
      print('${entry.key}: $oldSize bytes -> $newSize bytes');
    }
  }
}

void _section(String title,
    {required int elementCount,
    required int oldSizeTotal,
    required int newSizeTotal}) {
  if (oldSizeTotal == newSizeTotal) {
    print('$title ($elementCount common elements, $oldSizeTotal bytes)');
  } else {
    print('$title ($elementCount common elements, '
        '$oldSizeTotal bytes -> $newSizeTotal bytes)');
  }
  print('=' * 72);
}

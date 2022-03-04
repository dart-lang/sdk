// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool presenting combined information from dump-info and
/// runtime coverage data.
///
/// This tool requires two input files an `.info.data` and a
/// `.coverage.json` file. To produce these files you need to follow these
/// steps:
///
///   * Compile an app with dart2js using --dump-info and save the .info.data
///     file:
///
///      dart2js --dump-info main.dart
///
///   * Build the same app with dart2js using --experimental-track-allocations:
///
///      dart2js --experimental-track-allocations main.dart
///
///     This can be combined with the --dump-info step above.
///
///   * Load your app, exercise your code, then extract the runtime code
///     coverage JSON blob by querying
///     `$__dart_deferred_initializers__.allocations` in the page.
///
///   * Finally, run this tool.
library compiler.tool.runtime_coverage_analysis;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

class RuntimeCoverageAnalysisCommand extends Command<void>
    with PrintUsageException {
  @override
  final String name = "runtime_coverage";
  @override
  final String description = "Analyze runtime coverage data";

  RuntimeCoverageAnalysisCommand() {
    argParser.addFlag('show-packages',
        defaultsTo: false, help: "Show coverage details at the package level.");
  }

  @override
  void run() async {
    var args = argResults.rest;
    if (args.length < 2) {
      usageException('Missing arguments, expected: info.data coverage.json');
    }
    var showPackages = argResults['show-packages'];
    if (showPackages) {
      await _reportWithPackages(args[0], args[1]);
    } else {
      await _report(args[0], args[1]);
    }
  }
}

Future<void> _report(
  String infoFile,
  String coverageFile,
) async {
  var info = await infoFromFile(infoFile);
  var coverageRaw = jsonDecode(File(coverageFile).readAsStringSync());
  // The value associated with each coverage item isn't used for now.
  var coverage = coverageRaw.keys.toSet();

  int totalProgramSize = info.program.size;
  int totalLibSize = info.libraries.fold(0, (n, lib) => n + lib.size);

  int totalCode = 0;
  int usedCode = 0;
  var unused = PriorityQueue<Info>((a, b) => b.size.compareTo(a.size));

  void tallyCode(Info i) {
    totalCode += i.size;
    var name = qualifiedName(i);
    var used = coverage.contains(name);
    if (used) {
      usedCode += i.size;
    } else {
      unused.add(i);
    }
  }

  info.classes.forEach(tallyCode);
  info.closures.forEach(tallyCode);

  _section('Runtime Coverage Summary');
  _showHeader('', 'bytes', '%');
  _show('Program size', totalProgramSize, totalProgramSize);
  _show('Libraries (excluding statics)', totalLibSize, totalProgramSize);
  _show('Code (classes + closures)', totalCode, totalProgramSize);
  _show('Used', usedCode, totalProgramSize);

  print('');
  _showHeader('', 'count', '%');
  var total = info.classes.length + info.closures.length;
  _show('Classes + closures', total, total);
  _show('Used', total - unused.length, total);

  print('');
  var unusedTotal = totalCode - usedCode;
  _section('Runtime Coverage Breakdown', size: unusedTotal);
  for (int i = 0; i < unused.length; i++) {
    var item = unused.removeFirst();
    var percent = (item.size * 100 / unusedTotal).toStringAsFixed(2);
    print('${qualifiedName(item)}: ${item.size} bytes, $percent%');
  }
}

Future<void> _reportWithPackages(
  String infoFile,
  String coverageFile,
) async {
  var info = await infoFromFile(infoFile);
  var coverageRaw = jsonDecode(File(coverageFile).readAsStringSync());
  // The value associated with each coverage item isn't used for now.
  var coverage = coverageRaw.keys.toSet();

  int totalProgramSize = info.program.size;
  int totalLibSize = info.libraries.fold(0, (n, lib) => n + lib.size);

  int totalCode = 0;
  int usedCode = 0;
  var packageData = <String, PackageInfo>{};
  var unused = PriorityQueue<Info>((a, b) => b.size.compareTo(a.size));

  void tallyCode(Info i) {
    totalCode += i.size;
    var name = qualifiedName(i);
    var used = coverage.contains(name);

    var groupName = libraryGroupName(i);
    packageData.putIfAbsent(groupName, () => PackageInfo());
    packageData[groupName].add(i, used: used);

    if (used) {
      usedCode += i.size;
    } else {
      unused.add(i);
    }
  }

  info.classes.forEach(tallyCode);
  info.closures.forEach(tallyCode);

  _section('Runtime Coverage Summary');
  _showHeader('', 'bytes', '%');
  _show('Program size', totalProgramSize, totalProgramSize);
  _show('Libraries (excluding statics)', totalLibSize, totalProgramSize);
  _show('Code (classes + closures)', totalCode, totalProgramSize);
  _show('Used', usedCode, totalProgramSize);

  print('');
  _showHeader('', 'count', '%');
  var total = info.classes.length + info.closures.length;
  _show('Classes + closures', total, total);
  _show('Used', total - unused.length, total);

  print('');
  var unusedTotal = totalCode - usedCode;
  _section('Runtime Coverage Breakdown (packages)', size: unusedTotal);
  for (var entry in packageData.entries.sortedBy((e) => -e.value.unusedSize)) {
    var packageLabel = entry.key;
    var packageInfo = entry.value;

    print(' $packageLabel (${packageInfo.unusedSize} bytes unused)');

    var packageRatioString = (packageInfo.usedRatio * 100).toStringAsFixed(2);
    _leftPadded(
        '  proportion of package used:',
        '${packageInfo.usedSize}/${packageInfo.totalSize} '
            '($packageRatioString%)');

    var codeRatioString =
        (packageInfo.unusedSize / totalCode * 100).toStringAsFixed(2);
    _leftPadded('  proportion of unused code to all code:',
        '${packageInfo.unusedSize}/$totalCode ($codeRatioString%)');

    var unusedCodeRatioString =
        (packageInfo.unusedSize / unusedTotal * 100).toStringAsFixed(2);
    _leftPadded('  proportion of unused code to all unused code:',
        '${packageInfo.unusedSize}/$unusedTotal ($unusedCodeRatioString%)');

    _leftPadded('  package breakdown: ', '');
    for (var item in packageInfo.elements.toList()) {
      var percent =
          (item.size * 100 / packageInfo.totalSize).toStringAsFixed(2);
      var name = qualifiedName(item);
      var used = coverage.contains(name);
      var usedNotch = used ? '+' : '-';
      _leftPadded('    $usedNotch ${qualifiedName(item)}:',
          '${item.size} bytes ($percent% of package)');
    }

    print('');
  }
}

void _section(String title, {int size}) {
  if (size == null) {
    print(title);
  } else {
    print('$title ($size bytes)');
  }
  print('=' * 72);
}

_showHeader(String msg, String header1, String header2) {
  print(' ${pad(msg, 30, right: true)} ${pad(header1, 8)} ${pad(header2, 6)}');
}

_show(String msg, int size, int total) {
  var percent = (size * 100 / total).toStringAsFixed(2);
  print(' ${pad(msg, 30, right: true)} ${pad(size, 8)} ${pad(percent, 6)}%');
}

_leftPadded(String msg1, String msg2) {
  print(' ${pad(msg1, 50, right: true)} $msg2');
}

class PackageInfo {
  final elements = PriorityQueue<Info>((a, b) => b.size.compareTo(a.size));
  num totalSize = 0;
  num usedSize = 0;
  num unusedSize = 0;
  num usedRatio = 0.0;

  PackageInfo();

  void add(Info i, {bool used = true}) {
    totalSize += i.size;
    if (used) {
      usedSize += i.size;
    } else {
      unusedSize += i.size;
    }
    elements.add(i);
    usedRatio = usedSize / totalSize;
  }
}

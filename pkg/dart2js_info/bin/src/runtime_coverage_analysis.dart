// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

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
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';
import 'package:dart2js_info/src/runtime_coverage_utils.dart';

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
    argParser.addOption('class-filter',
        defaultsTo: '', help: "Show coverage details filtered by class.");
  }

  @override
  void run() async {
    var args = argResults!.rest;
    if (args.length < 2) {
      usageException('Missing arguments, expected: info.data coverage.json');
    }
    var showPackages = argResults!['show-packages'] as bool;
    var filterFile = argResults!['class-filter'] as String;
    if (showPackages && filterFile.isNotEmpty) {
      throw StateError('Cannot specify both packages view and filtered view.');
    }
    if (showPackages) {
      await _reportWithPackages(args[0], args[1]);
    } else if (filterFile.isNotEmpty) {
      await _reportWithClassFilter(args[0], args[1], filterFile);
    } else {
      await _report(args[0], args[1]);
    }
  }
}

Future<void> _report(
  String infoFile,
  String coverageFile,
) async {
  final info = await infoFromFile(infoFile);
  final coverageRaw = jsonDecode(File(coverageFile).readAsStringSync());
  // The value associated with each coverage item isn't used for now.
  final coverage = coverageRaw.keys.toSet();

  // Ensure that a used class's super, mixed in, and implemented classes are
  // correctly marked as used.
  final seen = <ClassInfo>{};
  void collectSupers(ClassInfo c) {
    if (seen.contains(c)) return;
    seen.add(c);
    coverage.add(qualifiedName(c));
    c.supers.forEach(collectSupers);
  }

  for (final c in info.classes) {
    if (coverage.contains(qualifiedName(c))) {
      c.supers.forEach(collectSupers);
    }
  }

  int totalProgramSize = info.program!.size;
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

/// Generates a report aggregated at the package level.
Future<void> _reportWithPackages(
  String infoFile,
  String coverageFile,
) async {
  final info = await infoFromFile(infoFile);
  final coverageRaw = jsonDecode(File(coverageFile).readAsStringSync());
  // The value associated with each coverage item isn't used for now.
  final coverage = coverageRaw.keys.toSet();

  // Ensure that a used class's super, mixed in, and implemented classes are
  // correctly marked as used.
  final seen = <ClassInfo>{};
  void collectSupers(ClassInfo c) {
    if (seen.contains(c)) return;
    seen.add(c);
    coverage.add(qualifiedName(c));
    c.supers.forEach(collectSupers);
  }

  for (final c in info.classes) {
    if (coverage.contains(qualifiedName(c))) {
      c.supers.forEach(collectSupers);
    }
  }

  int totalProgramSize = info.program!.size;
  int totalLibSize = info.libraries.fold(0, (n, lib) => n + lib.size);

  int totalCode = 0;
  int usedCode = 0;
  var packageData = <String, RuntimePackageInfo>{};
  var unused = PriorityQueue<Info>((a, b) => b.size.compareTo(a.size));

  void tallyCode(BasicInfo i) {
    totalCode += i.size;
    var name = qualifiedName(i);
    var used = coverage.contains(name);

    var groupName = libraryGroupName(i);
    packageData.putIfAbsent(groupName!, () => RuntimePackageInfo());
    packageData[groupName]!.add(i, used: used);

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

    var mainUnitPackageRatioString =
        (packageInfo.mainUnitSize / packageInfo.totalSize * 100)
            .toStringAsFixed(2);
    _leftPadded(
        '  proportion of main unit code to package code:',
        '${packageInfo.mainUnitSize}/${packageInfo.totalSize} '
            '($mainUnitPackageRatioString%)');

    var unusedMainUnitRatioString =
        (packageInfo.unusedMainUnitSize / packageInfo.mainUnitSize * 100)
            .toStringAsFixed(2);
    _leftPadded(
        '  proportion of main unit code that is unused:',
        '${packageInfo.unusedMainUnitSize}/${packageInfo.mainUnitSize} '
            '($unusedMainUnitRatioString%)');

    print('   package breakdown:');
    for (var item in packageInfo.elements.toList()) {
      var percent =
          (item.size * 100 / packageInfo.totalSize).toStringAsFixed(2);
      var name = qualifiedName(item);
      var used = coverage.contains(name);
      var usedTick = used ? '+' : '-';
      var mainUnitTick = item.outputUnit!.name == 'main' ? 'M' : 'D';
      _leftPadded('    [$usedTick$mainUnitTick] ${qualifiedName(item)}:',
          '${item.size} bytes ($percent% of package)');
    }

    print('');
  }
}

/// Generates a report filtered by class.
Future<void> _reportWithClassFilter(
    String infoFile, String coverageFile, String filterFile,
    {bool showUncategorizedClasses = false}) async {
  final info = await infoFromFile(infoFile);
  final coverageRaw = jsonDecode(File(coverageFile).readAsStringSync());
  // The value associated with each coverage item isn't used for now.
  Set<String> coverage = coverageRaw.keys.toSet();

  final classFilterData = {
    for (final info in runtimeInfoFromAngularInfo(filterFile)) info.key: info
  };

  // Ensure that a used class's super, mixed in, and implemented classes are
  // correctly marked as used.
  final seen = <ClassInfo>{};
  void collectSupers(ClassInfo c) {
    if (seen.contains(c)) return;
    seen.add(c);
    coverage.add(qualifiedName(c));
    c.supers.forEach(collectSupers);
  }

  for (final c in info.classes) {
    if (coverage.contains(qualifiedName(c))) {
      c.supers.forEach(collectSupers);
    }
  }

  int totalProgramSize = info.program!.size;
  int totalLibSize = info.libraries.fold(0, (n, lib) => n + lib.size);

  int usedCode = 0;
  int filterTotalCode = 0;
  int filterUsedCode = 0;
  int usedProcessedCode = 0;

  final uncategorizedClasses = <ClassInfo>{};
  final categorizedClasses = <ClassInfo>{};

  void processInfoForClass(ClassInfo info) {
    final name = qualifiedName(info);
    final used = coverage.contains(name);
    final nameWithoutPrefix =
        name.substring(name.indexOf(':') + 1, name.length);

    final runtimeClassInfo = classFilterData[nameWithoutPrefix];
    if (runtimeClassInfo == null) {
      uncategorizedClasses.add(info);
      return;
    }
    if (categorizedClasses.contains(info)) {
      runtimeClassInfo.annotateWithClassInfo(info, used: used);
      return;
    }
    categorizedClasses.add(info);
    runtimeClassInfo.annotateWithClassInfo(info, used: used);
    filterTotalCode += info.size;

    if (used) {
      usedProcessedCode += 1;
      filterUsedCode += info.size;
    }
  }

  info.classes.forEach(processInfoForClass);

  int totalCode = 0;

  for (final closure in info.closures) {
    totalCode += closure.size;
    final name = qualifiedName(closure);
    final used = coverage.contains(name);
    if (used) {
      usedCode += closure.size;
    }
  }

  for (final classInfo in uncategorizedClasses) {
    totalCode += classInfo.size;
    final name = qualifiedName(classInfo);
    final used = coverage.contains(name);
    if (used) {
      usedCode += classInfo.size;
    }
  }

  for (final classInfo in categorizedClasses) {
    totalCode += classInfo.size;
    final name = qualifiedName(classInfo);
    final used = coverage.contains(name);
    if (used) {
      usedCode += classInfo.size;
    }
  }

  _section('Runtime Coverage Summary');
  _showHeader('', 'bytes', '%');
  _show('Program size', totalProgramSize, totalProgramSize);
  _show('Libraries (excluding statics)', totalLibSize, totalProgramSize);
  _show('Code (classes + closures)', totalCode, totalProgramSize);
  _show('Used', usedCode, totalProgramSize);

  print('');
  final unusedTotal = totalCode - usedCode;
  _section('Runtime Coverage Breakdown (filtered)', size: unusedTotal);
  print('Filtered Breakdown:');
  print('Total (count): ${categorizedClasses.length}');
  print('Used  (count): $usedProcessedCode '
      '(${usedProcessedCode / categorizedClasses.length * 100}%)');
  print('Total (bytes): $filterTotalCode');
  print('Used  (bytes): $filterUsedCode '
      '(${filterUsedCode / filterTotalCode * 100}%)');
  for (final runtimeClassInfo in classFilterData.values
      .sortedBy((v) => v.annotated ? (v.used ? v.size : -v.size) : 0)) {
    if (!runtimeClassInfo.annotated) continue;
    final classInfo = runtimeClassInfo.info;
    final percent = (classInfo.size * 100 / filterTotalCode).toStringAsFixed(2);
    final name = qualifiedName(classInfo);
    final used = coverage.contains(name);
    final usedTick = used ? '+' : '-';
    final mainUnitTick = classInfo.outputUnit?.name == 'main' ? 'M' : 'D';
    _leftPadded('    [$usedTick$mainUnitTick] ${qualifiedName(classInfo)}:',
        '${classInfo.size} bytes ($percent% of filtered items)');
  }

  print('');
  print('Unaccounted classes in filter:');
  for (final runtimeClassInfo
      in classFilterData.values.where((v) => !v.annotated)) {
    print('    ${runtimeClassInfo.key}');
  }

  if (showUncategorizedClasses) {
    int uncategorizedSize = 0;
    for (final info in uncategorizedClasses) {
      uncategorizedSize += info.size;
    }
    _section('Uncategorized Info', size: uncategorizedSize);
    for (var info in uncategorizedClasses) {
      final percent = (info.size * 100 / totalProgramSize).toStringAsFixed(2);
      final name = qualifiedName(info);
      final used = coverage.contains(name);
      final usedTick = used ? '+' : '-';
      final mainUnitTick = info.outputUnit?.name == 'main' ? 'M' : 'D';
      _leftPadded('    [$usedTick$mainUnitTick] $name:',
          '${info.size} bytes ($percent% of program)');
    }
  }

  print('');
}

void _section(String title, {int? size}) {
  if (size == null) {
    print(title);
  } else {
    print('$title ($size bytes)');
  }
  print('=' * 72);
}

void _showHeader(String msg, String header1, String header2) {
  print(' ${pad(msg, 30, right: true)} ${pad(header1, 8)} ${pad(header2, 6)}');
}

void _show(String msg, int size, int total) {
  var percent = (size * 100 / total).toStringAsFixed(2);
  print(' ${pad(msg, 30, right: true)} ${pad(size, 8)} ${pad(percent, 6)}%');
}

void _leftPadded(String msg1, String msg2) {
  print(' ${pad(msg1, 50, right: true)} $msg2');
}

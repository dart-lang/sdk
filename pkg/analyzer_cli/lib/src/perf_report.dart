// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.perf_report;

import 'dart:convert' show JsonEncoder;
import 'dart:io' show Platform;

import 'package:analyzer/src/generated/utilities_general.dart'
    show PerformanceTag;
import 'package:analyzer/task/model.dart' show AnalysisTask;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart' show CommandLineOptions;

const _JSON = const JsonEncoder.withIndent("  ");

bool _isCheckedMode = () {
  bool x = true;
  try {
    // Trigger an exception if we're in checked mode.
    x = "" as dynamic;
    return x != ""; // return false; suppress unused variable warning
  } catch (e) {
    return true;
  }
}();

String _osType = () {
  if (Platform.isLinux) {
    return "linux";
  } else if (Platform.isMacOS) {
    return "mac";
  } else if (Platform.isWindows) {
    return "windows";
  } else if (Platform.isAndroid) {
    return "android";
  } else {
    return "unknown";
  }
}();

String makePerfReport(int startTime, int endTime, CommandLineOptions options,
    int analyzedFileCount, AnalysisStats stats) {
  int totalTime = endTime - startTime;
  int otherTime = totalTime;

  var platformJson = <String, dynamic>{
    'osType': _osType,
    'dartSdkVersion': Platform.version,
    'checkedMode': _isCheckedMode,
  };

  var optionsJson = <String, dynamic>{
    'dartSdkPath': options.dartSdkPath,
    'strongMode': options.strongMode,
    'showPackageWarnings': options.showPackageWarnings,
    'showPackageWarningsPrefix': options.showPackageWarningsPrefix,
    'showSdkWarnings': options.showSdkWarnings,
    'definedVariables': options.definedVariables,
    'packageRootPath': options.packageRootPath,
    'packageConfigPath': options.packageConfigPath,
    'sourceFiles': options.sourceFiles,
  };

  // Convert performance tags to JSON representation.
  var perfTagsJson = <String, dynamic>{};
  for (PerformanceTag tag in PerformanceTag.all) {
    if (tag != PerformanceTag.unknown) {
      int tagTime = tag.elapsedMs;
      perfTagsJson[tag.label] = tagTime;
      otherTime -= tagTime;
    }
  }
  perfTagsJson['other'] = otherTime;

  // Generate task table.
  var taskRows = <_TaskRow>[];
  int totalTaskTime = 0;
  for (var key in AnalysisTask.stopwatchMap.keys) {
    var time = AnalysisTask.stopwatchMap[key].elapsedMilliseconds;
    if (time == 0) continue;
    totalTaskTime += time;
    var count = AnalysisTask.countMap[key];
    taskRows.add(new _TaskRow(key.toString(), time, count));
  }
  taskRows.sort((a, b) => b.time.compareTo(a.time));

  var reportJson = <String, dynamic>{
    'perfReportVersion': 0,
    'platform': platformJson,
    'options': optionsJson,
    'totalElapsedTime': totalTime,
    'totalTaskTime': totalTaskTime,
    'analyzedFiles': analyzedFileCount,
    'generatedDiagnostics': stats.unfilteredCount,
    'reportedDiagnostics': stats.filteredCount,
    'performanceTags': perfTagsJson,
    'tasks': taskRows.map((r) => r.toJson()).toList(),
  };

  return _JSON.convert(reportJson);
}

class _TaskRow {
  final String name;
  final int time;
  final int count;
  _TaskRow(this.name, this.time, this.count);

  Map toJson() => <String, dynamic>{'name': name, 'time': time, 'count': count};
}

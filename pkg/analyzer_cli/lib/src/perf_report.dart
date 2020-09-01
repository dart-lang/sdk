// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JsonEncoder;
import 'dart:io' show Platform;

import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart' show CommandLineOptions;

const _JSON = JsonEncoder.withIndent('  ');

final String _osType = () {
  if (Platform.isLinux) {
    return 'linux';
  } else if (Platform.isMacOS) {
    return 'mac';
  } else if (Platform.isWindows) {
    return 'windows';
  } else if (Platform.isAndroid) {
    return 'android';
  } else {
    return 'unknown';
  }
}();

String makePerfReport(int startTime, int endTime, CommandLineOptions options,
    int analyzedFileCount, AnalysisStats stats) {
  var totalTime = endTime - startTime;

  var platformJson = <String, dynamic>{
    'osType': _osType,
    'dartSdkVersion': Platform.version,
  };

  var optionsJson = <String, dynamic>{
    'dartSdkPath': options.dartSdkPath,
    'showPackageWarnings': options.showPackageWarnings,
    'showPackageWarningsPrefix': options.showPackageWarningsPrefix,
    'showSdkWarnings': options.showSdkWarnings,
    'definedVariables': options.definedVariables,
    'packageConfigPath': options.packageConfigPath,
    'sourceFiles': options.sourceFiles,
  };

  var reportJson = <String, dynamic>{
    'perfReportVersion': 0,
    'platform': platformJson,
    'options': optionsJson,
    'totalElapsedTime': totalTime,
    'analyzedFiles': analyzedFileCount,
    'generatedDiagnostics': stats.unfilteredCount,
    'reportedDiagnostics': stats.filteredCount,
  };

  return _JSON.convert(reportJson);
}

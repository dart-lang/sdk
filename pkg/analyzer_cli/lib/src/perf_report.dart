// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.perf_report;

import 'dart:convert' show JsonEncoder;
import 'dart:io' show File, Platform;

import 'package:analyzer/src/generated/utilities_general.dart'
    show PerformanceTag;
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

String makePerfReport(int startTime, int endTime, CommandLineOptions options) {
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
    'showSdkWarnings': options.showSdkWarnings,
    'definedVariables': options.definedVariables,
    'packageRootPath': options.packageRootPath,
    'packageConfigPath': options.packageConfigPath,
    'sourceFiles': options.sourceFiles,
  };

  // Convert performance tags to JSON representation.
  var perfTagsJson = <String, dynamic>{};
  for (PerformanceTag tag in PerformanceTag.all) {
    if (tag != PerformanceTag.UNKNOWN) {
      int tagTime = tag.elapsedMs;
      perfTagsJson[tag.label] = tagTime;
      otherTime -= tagTime;
    }
  }
  perfTagsJson['other'] = otherTime;

  var json = <String, dynamic>{
    'perfReportVersion': 0,
    'platform': platformJson,
    'options': optionsJson,
    'totalElapsedTime': totalTime,
    'performanceTags': perfTagsJson
  };

  return _JSON.convert(json);
}

// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/summary/summary_file_builder.dart';
import 'package:meta/meta.dart';

void main(List<String> args) {
  String command;
  String outFilePath;
  String sdkPath;
  if (args.length == 2) {
    command = args[0];
    outFilePath = args[1];
  } else if (args.length == 3) {
    command = args[0];
    outFilePath = args[1];
    sdkPath = args[2];
  } else {
    _printUsage();
    exitCode = 1;
    return;
  }

  //
  // Validate the SDK path.
  //
  sdkPath ??=
      FolderBasedDartSdk.defaultSdkDirectory(PhysicalResourceProvider.INSTANCE)
          .path;
  if (!FileSystemEntity.isDirectorySync('$sdkPath/lib')) {
    print("'$sdkPath/lib' does not exist.");
    _printUsage();
    return;
  }

  //
  // Handle commands.
  //
  if (command == 'build-non-nullable') {
    _buildSummary(
      sdkPath,
      outFilePath,
      enabledExperiments: ['non-nullable'],
      title: 'non-nullable',
    );
  } else if (command == 'build-legacy' || command == 'build-strong') {
    _buildSummary(
      sdkPath,
      outFilePath,
      enabledExperiments: [],
      title: 'legacy',
    );
  } else {
    _printUsage();
    return;
  }
}

/**
 * The name of the SDK summaries builder application.
 */
const BINARY_NAME = "build_sdk_summaries";

void _buildSummary(
  String sdkPath,
  String outPath, {
  @required List<String> enabledExperiments,
  @required String title,
}) {
  print('Generating $title summary.');
  Stopwatch sw = Stopwatch()..start();
  var featureSet = FeatureSet.fromEnableFlags(enabledExperiments);
  List<int> bytes = SummaryBuilder.forSdk(sdkPath).build(
    featureSet: featureSet,
  );
  File(outPath).writeAsBytesSync(bytes, mode: FileMode.writeOnly);
  print('\tDone in ${sw.elapsedMilliseconds} ms.');
}

/**
 * Print information about how to use the SDK summaries builder.
 */
void _printUsage() {
  print('Usage: $BINARY_NAME command arguments');
  print('Where command can be one of the following:');
  print('  build-non-nullable output_file [sdk_path]');
  print('    Generate non-nullable summary file.');
  print('  build-legacy output_file [sdk_path]');
  print('    Generate legacy summary file.');
}

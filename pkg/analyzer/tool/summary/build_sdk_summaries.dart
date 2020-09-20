// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:cli_util/cli_util.dart';

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
  sdkPath ??= getSdkPath();
  if (!FileSystemEntity.isDirectorySync('$sdkPath/lib')) {
    print("'$sdkPath/lib' does not exist.");
    _printUsage();
    return;
  }

  //
  // Handle commands.
  //
  if (command == 'build' || command == 'build-strong') {
    _buildSummary(sdkPath, outFilePath);
  } else {
    _printUsage();
    return;
  }
}

/// The name of the SDK summaries builder application.
const BINARY_NAME = "build_sdk_summaries";

void _buildSummary(String sdkPath, String outPath) {
  print('Generating summary.');
  Stopwatch sw = Stopwatch()..start();
  List<int> bytes = buildSdkSummary(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    sdkPath: sdkPath,
  );
  File(outPath).writeAsBytesSync(bytes, mode: FileMode.writeOnly);
  print('\tDone in ${sw.elapsedMilliseconds} ms.');
}

/// Print information about how to use the SDK summaries builder.
void _printUsage() {
  print('Usage: $BINARY_NAME command arguments');
  print('Where command can be one of the following:');
  print('  build output_file [sdk_path]');
  print('    Generate summary file.');
}

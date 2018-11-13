import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/summary/summary_file_builder.dart';

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
  if (command == 'build-strong') {
    _buildSummary(sdkPath, outFilePath);
  } else {
    _printUsage();
    return;
  }
}

/**
 * The name of the SDK summaries builder application.
 */
const BINARY_NAME = "build_sdk_summaries";

void _buildSummary(String sdkPath, String outPath) {
  print('Generating strong mode summary.');
  Stopwatch sw = new Stopwatch()..start();
  List<int> bytes = new SummaryBuilder.forSdk(sdkPath).build();
  new File(outPath).writeAsBytesSync(bytes, mode: FileMode.writeOnly);
  print('\tDone in ${sw.elapsedMilliseconds} ms.');
}

/**
 * Print information about how to use the SDK summaries builder.
 */
void _printUsage() {
  print('Usage: $BINARY_NAME command arguments');
  print('Where command can be one of the following:');
  print('  build-strong output_file [sdk_path]');
  print('    Generate strong mode summary file.');
}

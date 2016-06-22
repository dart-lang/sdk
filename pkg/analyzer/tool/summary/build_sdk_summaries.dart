import 'dart:io';

import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;
import 'package:analyzer/src/summary/summary_file_builder.dart';

main(List<String> args) {
  if (args.length < 1) {
    _printUsage();
    exitCode = 1;
    return;
  }
  String command = args[0];
  if ((command == 'multiple-outputs' || command == 'strong-outputs') &&
      args.length >= 2 &&
      args.length <= 3) {
    bool includeSpec = command != 'strong-outputs';
    //
    // Prepare the output path.
    //
    String outputDirectoryPath = args[1];
    if (!FileSystemEntity.isDirectorySync(outputDirectoryPath)) {
      print("'$outputDirectoryPath' is not a directory.");
      _printUsage();
      exitCode = 1;
      return;
    }
    //
    // Prepare results.
    //
    String sdkPath = args.length > 2 ? args[2] : null;
    SummaryOutput output = _buildMultipleOutputs(sdkPath, includeSpec);
    if (output == null) {
      exitCode = 1;
      return;
    }
    //
    // Write results.
    //
    if (includeSpec) {
      output.spec.writeMultiple(outputDirectoryPath, 'spec');
    }
    output.strong.writeMultiple(outputDirectoryPath, 'strong');
  } else if (command == 'single-output' &&
      args.length >= 2 &&
      args.length <= 3) {
    String outputPath = args[1];
    String sdkPath = args.length > 2 ? args[2] : null;
    //
    // Prepare results.
    //
    SummaryOutput output = _buildMultipleOutputs(sdkPath, true);
    if (output == null) {
      exitCode = 1;
      return;
    }

    //
    // Write results.
    //
    output.write(outputPath);
  } else if (command == 'extract-spec-sum' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, FIELD_SPEC_SUM, outputPath);
  } else if (command == 'extract-spec-index' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, FIELD_SPEC_INDEX, outputPath);
  } else if (command == 'extract-strong-sum' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, FIELD_STRONG_SUM, outputPath);
  } else if (command == 'extract-strong-index' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, FIELD_STRONG_INDEX, outputPath);
  } else {
    _printUsage();
    exitCode = 1;
    return;
  }
}

/**
 * The name of the SDK summaries builder application.
 */
const BINARY_NAME = "build_sdk_summaries";

SummaryOutput _buildMultipleOutputs(String sdkPath, bool includeSpec) {
  //
  // Validate the SDK path.
  //
  if (sdkPath != null) {
    if (!FileSystemEntity.isDirectorySync('$sdkPath/lib')) {
      print("'$sdkPath/lib' does not exist.");
      _printUsage();
      return null;
    }
  } else {
    sdkPath = DirectoryBasedDartSdk.defaultSdkDirectory.getAbsolutePath();
  }

  //
  // Build spec and strong outputs.
  //
  BuilderOutput spec = includeSpec ? _buildOutput(sdkPath, false) : null;
  BuilderOutput strong = _buildOutput(sdkPath, true);
  return new SummaryOutput(spec, strong);
}

BuilderOutput _buildOutput(String sdkPath, bool strongMode) {
  String modeName = strongMode ? 'strong' : 'spec';
  print('Generating $modeName mode summary and index.');
  Stopwatch sw = new Stopwatch()..start();
  SummaryBuildConfig config = new SummaryBuildConfig(strongMode: strongMode);
  BuilderOutput output = new SummaryBuilder.forSdk(sdkPath, config).build();
  print('\tDone in ${sw.elapsedMilliseconds} ms.');
  return output;
}

/**
 * Open the flat buffer in [inputPath] and extract the byte array in the [field]
 * into the [outputPath] file.
 */
void _extractSingleOutput(String inputPath, int field, String outputPath) {
  List<int> bytes = new File(inputPath).readAsBytesSync();
  fb.BufferContext root = new fb.BufferContext.fromBytes(bytes);
  int tableOffset = root.derefObject(0);
  List<int> fieldBytes =
      const fb.Uint8ListReader().vTableGet(root, tableOffset, field);
  new File(outputPath).writeAsBytesSync(fieldBytes, mode: FileMode.WRITE_ONLY);
}

/**
 * Print information about how to use the SDK summaries builder.
 */
void _printUsage() {
//  print('Usage: $BINARY_NAME command output_directory_path [sdk_path]');
  print('Usage: $BINARY_NAME command arguments');
  print('Where command can be one of the following:');
  print('  multiple-outputs output_directory_path [sdk_path]');
  print('    Generate separate summary and index files.');
  print('  strong-outputs output_directory_path [sdk_path]');
  print('    Generate separate summary and index files (strong mode only).');
  print('  single-output output_file_path [sdk_path]');
  print('    Generate a single file with summary and index.');
  print('  extract-spec-sum input_file output_file');
  print('    Extract the spec-mode summary file.');
  print('  extract-strong-sum input_file output_file');
  print('    Extract the strong-mode summary file.');
  print('  extract-spec-index input_file output_file');
  print('    Extract the spec-mode index file.');
  print('  extract-strong-index input_file output_file');
  print('    Extract the strong-mode index file.');
}

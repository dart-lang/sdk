import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;
import 'package:analyzer/src/summary/index_unit.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:path/path.dart';

main(List<String> args) {
  if (args.length < 1) {
    _printUsage();
    exitCode = 1;
    return;
  }
  String command = args[0];
  if (command == 'multiple-outputs' && args.length >= 2 && args.length <= 3) {
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
    _Output output = _buildMultipleOutputs(sdkPath);
    if (output == null) {
      exitCode = 1;
      return;
    }
    //
    // Write results.
    //
    output.spec.writeMultiple(outputDirectoryPath, 'spec');
    output.strong.writeMultiple(outputDirectoryPath, 'strong');
  } else if (command == 'single-output' &&
      args.length >= 2 &&
      args.length <= 3) {
    String outputPath = args[1];
    String sdkPath = args.length > 2 ? args[2] : null;
    //
    // Prepare results.
    //
    _Output output = _buildMultipleOutputs(sdkPath);
    if (output == null) {
      exitCode = 1;
      return;
    }
    //
    // Write results.
    //
    fb.Builder builder = new fb.Builder();
    fb.Offset specSumOffset = builder.writeListUint8(output.spec.sum);
    fb.Offset specIndexOffset = builder.writeListUint8(output.spec.index);
    fb.Offset strongSumOffset = builder.writeListUint8(output.strong.sum);
    fb.Offset strongIndexOffset = builder.writeListUint8(output.strong.index);
    builder.startTable();
    builder.addOffset(_FIELD_SPEC_SUM, specSumOffset);
    builder.addOffset(_FIELD_SPEC_INDEX, specIndexOffset);
    builder.addOffset(_FIELD_STRONG_SUM, strongSumOffset);
    builder.addOffset(_FIELD_STRONG_INDEX, strongIndexOffset);
    fb.Offset offset = builder.endTable();
    new File(outputPath)
        .writeAsBytesSync(builder.finish(offset), mode: FileMode.WRITE_ONLY);
  } else if (command == 'extract-spec-sum' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, _FIELD_SPEC_SUM, outputPath);
  } else if (command == 'extract-spec-index' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, _FIELD_SPEC_INDEX, outputPath);
  } else if (command == 'extract-strong-sum' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, _FIELD_STRONG_SUM, outputPath);
  } else if (command == 'extract-strong-index' && args.length == 3) {
    String inputPath = args[1];
    String outputPath = args[2];
    _extractSingleOutput(inputPath, _FIELD_STRONG_INDEX, outputPath);
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

const int _FIELD_SPEC_INDEX = 1;
const int _FIELD_SPEC_SUM = 0;
const int _FIELD_STRONG_INDEX = 3;
const int _FIELD_STRONG_SUM = 2;

_Output _buildMultipleOutputs(String sdkPath) {
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
  _BuilderOutput spec = new _Builder(sdkPath, false).build();
  _BuilderOutput strong = new _Builder(sdkPath, true).build();
  return new _Output(spec, strong);
}

/**
 * Open the flat buffer in [inputPath] and extract the byte array in the [field]
 * into the [outputPath] file.
 */
void _extractSingleOutput(String inputPath, int field, String outputPath) {
  List<int> bytes = new File(inputPath).readAsBytesSync();
  fb.BufferPointer root = new fb.BufferPointer.fromBytes(bytes);
  fb.BufferPointer table = root.derefObject();
  List<int> fieldBytes = const fb.Uint8ListReader().vTableGet(table, field);
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

class _Builder {
  final String sdkPath;
  final bool strongMode;

  AnalysisContext context;
  final Set<Source> processedSources = new Set<Source>();

  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
  final PackageIndexAssembler indexAssembler = new PackageIndexAssembler();

  _Builder(this.sdkPath, this.strongMode);

  /**
   * Build a strong or spec mode summary for the Dart SDK at [sdkPath].
   */
  _BuilderOutput build() {
    String modeName = strongMode ? 'strong' : 'spec';
    print('Generating $modeName mode summary and index.');
    Stopwatch sw = new Stopwatch()..start();
    //
    // Prepare SDK.
    //
    DirectoryBasedDartSdk sdk =
        new DirectoryBasedDartSdk(new JavaFile(sdkPath), strongMode);
    sdk.useSummary = false;
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = strongMode;
    context = sdk.context;
    //
    // Prepare 'dart:' URIs to serialize.
    //
    Set<String> uriSet =
        sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
    if (!strongMode) {
      uriSet.add('dart:html/nativewrappers.dart');
    }
    uriSet.add('dart:html_common/html_common_dart2js.dart');
    //
    // Serialize each SDK library.
    //
    for (String uri in uriSet) {
      Source libSource = sdk.mapDartUri(uri);
      _serializeLibrary(libSource);
    }
    //
    // Assemble the output.
    //
    List<int> sumBytes = bundleAssembler.assemble().toBuffer();
    List<int> indexBytes = indexAssembler.assemble().toBuffer();
    print('\tDone in ${sw.elapsedMilliseconds} ms.');
    return new _BuilderOutput(sumBytes, indexBytes);
  }

  /**
   * Serialize the library with the given [source] and all its direct or
   * indirect imports and exports.
   */
  void _serializeLibrary(Source source) {
    if (!processedSources.add(source)) {
      return;
    }
    LibraryElement element = context.computeLibraryElement(source);
    bundleAssembler.serializeLibraryElement(element);
    element.importedLibraries.forEach((e) => _serializeLibrary(e.source));
    element.exportedLibraries.forEach((e) => _serializeLibrary(e.source));
    // Index every unit of the library.
    for (CompilationUnitElement unitElement in element.units) {
      Source unitSource = unitElement.source;
      CompilationUnit unit =
          context.resolveCompilationUnit2(unitSource, source);
      indexAssembler.indexUnit(unit);
    }
  }
}

class _BuilderOutput {
  final List<int> sum;
  final List<int> index;

  _BuilderOutput(this.sum, this.index);

  void writeMultiple(String outputDirectoryPath, String modeName) {
    // Write summary.
    {
      String outputPath = join(outputDirectoryPath, '$modeName.sum');
      File file = new File(outputPath);
      file.writeAsBytesSync(sum, mode: FileMode.WRITE_ONLY);
    }
    // Write index.
    {
      String outputPath = join(outputDirectoryPath, '$modeName.index');
      File file = new File(outputPath);
      file.writeAsBytesSync(index, mode: FileMode.WRITE_ONLY);
    }
  }
}

class _Output {
  final _BuilderOutput spec;
  final _BuilderOutput strong;

  _Output(this.spec, this.strong);
}

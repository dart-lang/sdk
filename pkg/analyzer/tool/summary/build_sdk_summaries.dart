import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/index_unit.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:path/path.dart';

main(List<String> args) {
  if (args.length < 1 || args.length > 2) {
    _printUsage();
    exitCode = 1;
    return;
  }
  //
  // Prepare output file path.
  //
  String outputDirectoryPath = args[0];
  if (!FileSystemEntity.isDirectorySync(outputDirectoryPath)) {
    print("'$outputDirectoryPath' is not a directory.");
    _printUsage();
    exitCode = 1;
    return;
  }
  //
  // Prepare SDK path.
  //
  String sdkPath;
  if (args.length == 2) {
    sdkPath = args[1];
    if (!FileSystemEntity.isDirectorySync('$sdkPath/lib')) {
      print("'$sdkPath/lib' does not exist.");
      _printUsage();
      exitCode = 1;
      return;
    }
  } else {
    sdkPath = DirectoryBasedDartSdk.defaultSdkDirectory.getAbsolutePath();
  }
  //
  // Build spec and strong summaries.
  //
  new _Builder(sdkPath, outputDirectoryPath, false).build();
  new _Builder(sdkPath, outputDirectoryPath, true).build();
}

/**
 * The name of the SDK summaries builder application.
 */
const BINARY_NAME = "build_sdk_summaries";

/**
 * Print information about how to use the SDK summaries builder.
 */
void _printUsage() {
  print('Usage: $BINARY_NAME output_directory_path [sdk_path]');
  print('Build files spec.sum and strong.sum in the output directory.');
}

class _Builder {
  final String sdkPath;
  final String outputDirectoryPath;
  final bool strongMode;

  AnalysisContext context;
  final Set<Source> processedSources = new Set<Source>();

  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
  final PackageIndexAssembler indexAssembler = new PackageIndexAssembler();

  _Builder(this.sdkPath, this.outputDirectoryPath, this.strongMode);

  /**
   * Build a strong or spec mode summary for the Dart SDK at [sdkPath].
   */
  void build() {
    String modeName = strongMode ? 'strong' : 'spec';
    print('Generating $modeName mode summary and index.');
    Stopwatch sw = new Stopwatch()..start();
    //
    // Prepare SDK.
    //
    DirectoryBasedDartSdk sdk =
        new DirectoryBasedDartSdk(new JavaFile(sdkPath));
    sdk.useSummary = false;
    context = sdk.context;
    context.analysisOptions = new AnalysisOptionsImpl()
      ..strongMode = strongMode;
    //
    // Prepare 'dart:' URIs to serialize.
    //
    Set<String> uriSet =
        sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
    uriSet.add('dart:html/nativewrappers.dart');
    uriSet.add('dart:html_common/html_common_dart2js.dart');
    //
    // Serialize each SDK library.
    //
    for (String uri in uriSet) {
      Source libSource = sdk.mapDartUri(uri);
      _serializeLibrary(libSource);
    }
    //
    // Write the whole SDK bundle.
    //
    {
      PackageBundleBuilder bundle = bundleAssembler.assemble();
      String outputPath = join(outputDirectoryPath, '$modeName.sum');
      File file = new File(outputPath);
      file.writeAsBytesSync(bundle.toBuffer(), mode: FileMode.WRITE_ONLY);
    }
    //
    // Write the whole SDK index.
    //
    {
      PackageIndexBuilder index = indexAssembler.assemble();
      String outputPath = join(outputDirectoryPath, '$modeName.index');
      File file = new File(outputPath);
      file.writeAsBytesSync(index.toBuffer(), mode: FileMode.WRITE_ONLY);
    }
    //
    // Done.
    //
    print('\tDone in ${sw.elapsedMilliseconds} ms.');
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
      indexAssembler.index(unit);
    }
  }
}

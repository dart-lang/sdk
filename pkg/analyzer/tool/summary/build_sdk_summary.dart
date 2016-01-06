import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';

main(List<String> args) {
  if (args.length < 1 || args.length > 2) {
    _printUsage();
    return;
  }
  //
  // Prepare output file path.
  //
  String outputFilePath = args[0];
  if (FileSystemEntity.isDirectorySync(outputFilePath)) {
    print("'$outputFilePath' is a directory.");
    _printUsage();
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
      return;
    }
  } else {
    sdkPath = DirectoryBasedDartSdk.defaultSdkDirectory.getAbsolutePath();
  }
  //
  // Prepare SDK.
  //
  DirectoryBasedDartSdk sdk = new DirectoryBasedDartSdk(new JavaFile(sdkPath));
  AnalysisContext context = sdk.context;
  //
  // Serialize each SDK library.
  //
  List<String> prelinkedLibraryUris = <String>[];
  List<PrelinkedLibraryBuilder> prelinkedLibraries =
      <PrelinkedLibraryBuilder>[];
  List<String> unlinkedUnitUris = <String>[];
  List<UnlinkedUnitBuilder> unlinkedUnits = <UnlinkedUnitBuilder>[];
  BuilderContext builderContext = new BuilderContext();
  for (SdkLibrary lib in sdk.sdkLibraries) {
    print('Resolving and serializing: ${lib.shortName}');
    Source librarySource = sdk.mapDartUri(lib.shortName);
    LibraryElement libraryElement =
        context.computeLibraryElement(librarySource);
    LibrarySerializationResult libraryResult =
        serializeLibrary(builderContext, libraryElement, context.typeProvider);
    prelinkedLibraryUris.add(lib.shortName);
    prelinkedLibraries.add(libraryResult.prelinked);
    unlinkedUnitUris.addAll(libraryResult.unitUris);
    unlinkedUnits.addAll(libraryResult.unlinkedUnits);
  }
  //
  // Write the whole SDK bundle.
  //
  SdkBundleBuilder sdkBundle = encodeSdkBundle(builderContext,
      prelinkedLibraryUris: prelinkedLibraryUris,
      prelinkedLibraries: prelinkedLibraries,
      unlinkedUnitUris: unlinkedUnitUris,
      unlinkedUnits: unlinkedUnits);
  File file = new File(outputFilePath);
  file.writeAsBytesSync(sdkBundle.toBuffer(), mode: FileMode.WRITE_ONLY);
}

/**
 * The name of the SDK summary builder application.
 */
const BINARY_NAME = "build_sdk_summary";

/**
 * Print information about how to use the SDK summary builder.
 */
void _printUsage() {
  print('Usage: $BINARY_NAME output_file_path [sdk_path]');
}

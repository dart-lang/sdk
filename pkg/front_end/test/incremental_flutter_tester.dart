// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, exit;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, CfeDiagnosticMessage;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/kernel/utils.dart' show serializeComponent;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/import_table.dart' show ImportTable;
import 'package:kernel/kernel.dart'
    show Component, Library, LibraryPart, MetadataRepository, Name, Reference;
import 'package:kernel/target/targets.dart' show Target, TargetFlags;
import 'package:kernel/text/ast_to_text.dart'
    show Annotator, NameSystem, Printer;
import "package:vm/modular/target/flutter.dart" show FlutterTarget;

import 'incremental_suite.dart' as helper;
import "incremental_utils.dart" as util;

Never usage(String extraMessage) {
  print("""Usage as something like:
    out/ReleaseX64/dart pkg/front_end/test/incremental_flutter_tester.dart \
      --fast --experimental \
      --input=/wherever/flutter/examples/flutter_gallery/lib/main.dart \
      --flutter_patched_sdk_dir=/wherever/flutter_patched_sdk/

    Note that the flutter stuff can be fetched, prepared and compiled via the
    script "tools/bots/flutter/compile_flutter.sh --prepareOnly".

  $extraMessage""");
  exit(1);
}

Future<void> main(List<String> args) async {
  bool fast = false;
  bool useExperimentalInvalidation = false;
  File? inputFile;
  Directory? flutterPatchedSdk;
  for (String arg in args) {
    if (arg == "--fast") {
      fast = true;
    } else if (arg == "--experimental") {
      useExperimentalInvalidation = true;
    } else if (arg.startsWith("--input=")) {
      inputFile = new File(arg.substring("--input=".length));
      if (!inputFile.existsSync()) {
        throw "$inputFile doesn't exist!";
      }
    } else if (arg.startsWith("--flutter_patched_sdk_dir=")) {
      flutterPatchedSdk = new Directory(
        arg.substring("--flutter_patched_sdk_dir=".length),
      );
      if (!flutterPatchedSdk.existsSync()) {
        throw "$flutterPatchedSdk doesn't exist!";
      }
    } else {
      throw "Unsupported argument: $arg";
    }
  }
  if (inputFile == null) {
    usage("No input to compile given; Use --input=<input>");
  }
  if (flutterPatchedSdk == null) {
    usage("No patched sdk dir given; Use --flutter_patched_sdk_dir=<dir>");
  }

  Stopwatch stopwatch = new Stopwatch()..start();
  CompilerOptions options = getOptions(flutterPatchedSdk.uri);
  options.explicitExperimentalFlags[ExperimentalFlag
          .alternativeInvalidationStrategy] =
      useExperimentalInvalidation;
  helper.TestIncrementalCompiler compiler = new helper.TestIncrementalCompiler(
    options,
    inputFile.uri,
  );
  IncrementalCompilerResult compilerResult = await compiler.computeDelta();
  Component? c = compilerResult.component;
  print(
    "Compiled to Component with ${c.libraries.length} "
    "libraries in ${stopwatch.elapsedMilliseconds} ms.",
  );
  stopwatch.reset();
  late Uint8List firstCompileData;
  late Map<Uri, Uint8List> libToData;
  if (fast) {
    libToData = {};
    c.libraries.sort((l1, l2) {
      return "${l1.fileUri}".compareTo("${l2.fileUri}");
    });

    c.problemsAsJson?.sort();

    c.computeCanonicalNames();

    for (Library library in c.libraries) {
      library.additionalExports.sort();
      library.problemsAsJson?.sort();

      Uint8List libSerialized = serializeComponent(
        c,
        filter: (l) => l == library,
      );
      libToData[library.importUri] = libSerialized;
    }
  } else {
    firstCompileData = util.postProcess(c);
  }
  print("Serialized in ${stopwatch.elapsedMilliseconds} ms");
  stopwatch.reset();

  List<Uri> uris = c.uriToSource.values
      .map((s) => s.importUri)
      .whereType<Uri>()
      .where((u) => !u.isScheme("dart"))
      .toSet()
      .toList();

  c = null;

  List<Uri> diffs = <Uri>[];
  Set<Uri> componentUris = new Set<Uri>();

  Stopwatch localStopwatch = new Stopwatch()..start();
  for (int i = 0; i < uris.length; i++) {
    Uri uri = uris[i];
    print("Invalidating $uri ($i)");
    compiler.invalidate(uri);
    localStopwatch.reset();
    IncrementalCompilerResult compilerResult = await compiler.computeDelta(
      fullComponent: true,
    );
    Component c2 = compilerResult.component;
    print("Recompiled in ${localStopwatch.elapsedMilliseconds} ms");
    print(
      "invalidatedImportUrisForTesting: "
      "${compiler.recorderForTesting.invalidatedImportUrisForTesting}",
    );
    print(
      "rebuildBodiesCount: "
      "${compiler.recorderForTesting.rebuildBodiesCount}",
    );
    localStopwatch.reset();
    Set<Uri> thisUris = new Set<Uri>.from(c2.libraries.map((l) => l.importUri));
    if (componentUris.isNotEmpty) {
      Set<Uri> diffUris = {};
      diffUris.addAll(thisUris.difference(componentUris));
      diffUris.addAll(componentUris.difference(thisUris));
      if (diffUris.isNotEmpty) {
        print("Diffs for this compile: $diffUris");
      }
    }
    componentUris.clear();
    componentUris.addAll(thisUris);

    if (fast) {
      print("Got ${c2.libraries.length} libraries");
      c2.libraries.sort((l1, l2) {
        return "${l1.fileUri}".compareTo("${l2.fileUri}");
      });

      c2.problemsAsJson?.sort();

      c2.computeCanonicalNames();

      int foundCount = 0;
      for (Library library in c2.libraries) {
        Set<Uri> uris = new Set<Uri>();
        uris.add(library.importUri);
        for (LibraryPart part in library.parts) {
          Uri uri = library.importUri.resolve(part.partUri);
          uris.add(uri);
        }
        if (!uris.contains(uri)) continue;

        foundCount++;
        library.additionalExports.sort();
        library.problemsAsJson?.sort();

        Uint8List libSerialized = serializeComponent(
          c2,
          filter: (l) => l == library,
        );
        if (!isEqual(libToData[library.importUri]!, libSerialized)) {
          print("=====");
          print("=====");
          print("=====");
          print("Notice diff on $uri ($i)!");
          libToData[library.importUri] = libSerialized;
          diffs.add(uri);
          print("=====");
          print("=====");
          print("=====");
        }
      }
      if (foundCount != 1) {
        throw "Expected to find $uri, but it $foundCount times.";
      }
      print("Serialized library in ${localStopwatch.elapsedMilliseconds} ms");
    } else {
      Uint8List thisCompileData = util.postProcess(c2);
      print("Serialized in ${localStopwatch.elapsedMilliseconds} ms");
      if (!isEqual(firstCompileData, thisCompileData)) {
        print("=====");
        print("=====");
        print("=====");
        print("Notice diff on $uri ($i)!");
        firstCompileData = thisCompileData;
        diffs.add(uri);
        print("=====");
        print("=====");
        print("=====");
      }
    }
    print("-----");
  }

  print("A total of ${diffs.length} diffs:");
  for (Uri uri in diffs) {
    print(" - $uri");
  }

  print(
    "Done after ${uris.length} recompiles in "
    "${stopwatch.elapsedMilliseconds} ms",
  );
}

bool isEqual(Uint8List a, Uint8List b) {
  bool result = isEqualBitForBit(a, b);
  if (result) return result;
  // Not binary equal. Do a to-text, if that is not equal, do a to to-text
  // without interface targets. If that is equal, assume that's the only
  // difference and return true too.

  String aString = toText(a);
  String bString = toText(b);
  if (aString != bString) {
    aString = toText(a, skipInterfaceTarget: true);
    bString = toText(b, skipInterfaceTarget: true);
    if (aString == bString) return true;
  }

  return false;
}

String toText(Uint8List data, {bool skipInterfaceTarget = false}) {
  Component component = new Component();
  new BinaryBuilder(data).readComponent(component);
  StringBuffer buffer = new StringBuffer();
  Printer printer;
  if (skipInterfaceTarget) {
    printer = new PrinterPrime(buffer, showOffsets: true);
  } else {
    printer = new Printer(buffer, showOffsets: true);
  }
  printer.writeComponentFile(component);
  return buffer.toString();
}

bool isEqualBitForBit(List<int> a, List<int> b) {
  int length = a.length;
  if (b.length != length) {
    return false;
  }
  for (int i = 0; i < length; ++i) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

CompilerOptions getOptions(Uri sdkRoot) {
  Target target = new FlutterTarget(new TargetFlags(trackWidgetCreation: true));
  CompilerOptions options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..target = target
    ..omitPlatform = true
    ..onDiagnostic = (CfeDiagnosticMessage message) {
      if (message.severity == CfeSeverity.error) {
        throw "Unexpected error: ${message.plainTextFormatted.join('\n')}";
      }
    }
    ..sdkSummary = sdkRoot.resolve("platform_strong.dill")
    ..environmentDefines = const {};
  return options;
}

class PrinterPrime extends Printer {
  PrinterPrime(
    StringSink sink, {
    NameSystem? syntheticNames,
    bool showOffsets = false,
    bool showMetadata = false,
    ImportTable? importTable,
    Annotator? annotator,
    Map<String, MetadataRepository<dynamic>>? metadata,
  }) : super(
         sink,
         showOffsets: showOffsets,
         showMetadata: showMetadata,
         importTable: importTable,
         annotator: annotator,
         metadata: metadata,
       );

  @override
  PrinterPrime createInner(
    ImportTable importTable,
    Map<String, MetadataRepository<dynamic>>? metadata,
  ) {
    return new PrinterPrime(
      sink,
      importTable: importTable,
      metadata: metadata,
      syntheticNames: syntheticNames,
      annotator: annotator,
      showOffsets: showOffsets,
      showMetadata: showMetadata,
    );
  }

  @override
  void writeInterfaceTarget(Name name, Reference? target) {
    // Skipped!
  }
}

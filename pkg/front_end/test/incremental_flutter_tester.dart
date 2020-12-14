// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, exit;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/import_table.dart' show ImportTable;

import 'package:kernel/kernel.dart'
    show Component, Library, LibraryPart, MetadataRepository, Name, Reference;

import 'package:kernel/target/targets.dart' show Target, TargetFlags;

import 'package:kernel/text/ast_to_text.dart'
    show Annotator, NameSystem, Printer;

import 'incremental_load_from_dill_suite.dart' as helper;

import "package:vm/target/flutter.dart" show FlutterTarget;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import "incremental_utils.dart" as util;

void usage(String extraMessage) {
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

main(List<String> args) async {
  bool fast = false;
  bool useExperimentalInvalidation = false;
  File inputFile;
  Directory flutterPatchedSdk;
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
      flutterPatchedSdk =
          new Directory(arg.substring("--flutter_patched_sdk_dir=".length));
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
      .alternativeInvalidationStrategy] = useExperimentalInvalidation;
  helper.TestIncrementalCompiler compiler =
      new helper.TestIncrementalCompiler(options, inputFile.uri);
  Component c = await compiler.computeDelta();
  print("Compiled to Component with ${c.libraries.length} "
      "libraries in ${stopwatch.elapsedMilliseconds} ms.");
  stopwatch.reset();
  List<int> firstCompileData;
  Map<Uri, List<int>> libToData;
  if (fast) {
    libToData = {};
    c.libraries.sort((l1, l2) {
      return "${l1.fileUri}".compareTo("${l2.fileUri}");
    });

    c.problemsAsJson?.sort();

    c.computeCanonicalNames();

    for (Library library in c.libraries) {
      library.additionalExports.sort((Reference r1, Reference r2) {
        return "${r1.canonicalName}".compareTo("${r2.canonicalName}");
      });
      library.problemsAsJson?.sort();

      List<int> libSerialized =
          serializeComponent(c, filter: (l) => l == library);
      libToData[library.importUri] = libSerialized;
    }
  } else {
    firstCompileData = util.postProcess(c);
  }
  print("Serialized in ${stopwatch.elapsedMilliseconds} ms");
  stopwatch.reset();

  List<Uri> uris = c.uriToSource.values
      .map((s) => s != null ? s.importUri : null)
      .where((u) => u != null && u.scheme != "dart")
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
    Component c2 = await compiler.computeDelta(fullComponent: true);
    print("Recompiled in ${localStopwatch.elapsedMilliseconds} ms");
    print("invalidatedImportUrisForTesting: "
        "${compiler.invalidatedImportUrisForTesting}");
    print("rebuildBodiesCount: ${compiler.rebuildBodiesCount}");
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
        library.additionalExports.sort((Reference r1, Reference r2) {
          return "${r1.canonicalName}".compareTo("${r2.canonicalName}");
        });
        library.problemsAsJson?.sort();

        List<int> libSerialized =
            serializeComponent(c2, filter: (l) => l == library);
        if (!isEqual(libToData[library.importUri], libSerialized)) {
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
      List<int> thisCompileData = util.postProcess(c2);
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

  print("Done after ${uris.length} recompiles in "
      "${stopwatch.elapsedMilliseconds} ms");
}

bool isEqual(List<int> a, List<int> b) {
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

String toText(List<int> data, {bool skipInterfaceTarget: false}) {
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
    ..onDiagnostic = (DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        throw "Unexpected error: ${message.plainTextFormatted.join('\n')}";
      }
    }
    ..sdkSummary = sdkRoot.resolve("platform_strong.dill")
    ..environmentDefines = const {};
  return options;
}

class PrinterPrime extends Printer {
  PrinterPrime(StringSink sink,
      {NameSystem syntheticNames,
      bool showOffsets: false,
      bool showMetadata: false,
      ImportTable importTable,
      Annotator annotator,
      Map<String, MetadataRepository<Object>> metadata})
      : super(sink,
            showOffsets: showOffsets,
            showMetadata: showMetadata,
            importTable: importTable,
            annotator: annotator,
            metadata: metadata);

  PrinterPrime createInner(ImportTable importTable,
      Map<String, MetadataRepository<Object>> metadata) {
    return new PrinterPrime(sink,
        importTable: importTable,
        metadata: metadata,
        syntheticNames: syntheticNames,
        annotator: annotator,
        showOffsets: showOffsets,
        showMetadata: showMetadata);
  }

  void writeInterfaceTarget(Name name, Reference target) {
    // Skipped!
  }
}

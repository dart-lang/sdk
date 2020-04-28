// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;

import 'dart:io' show BytesBuilder, File;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, Token;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:kernel/ast.dart' show Component;

import 'parser_test_listener.dart' show ParserTestListener;

import 'parser_suite.dart' as parser_suite;

import 'incremental_load_from_dill_suite.dart' show getOptions;

Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
Uri base = Uri.parse("org-dartlang-test:///");
Uri sdkSummary = base.resolve("vm_platform.dill");
Uri platformUri = sdkRoot.resolve("vm_platform_strong.dill");

main(List<String> arguments) async {
  String filename;
  bool nnbd = false;
  for (String arg in arguments) {
    if (arg.startsWith("--")) {
      if (arg == "--nnbd") {
        nnbd = true;
      } else {
        throw "Unknown option $arg";
      }
    } else if (filename != null) {
      throw "Already got '$filename', '$arg' is also a filename; "
          "can only get one";
    } else {
      filename = arg;
    }
  }
  if (filename == null) {
    throw "Need file to operate on";
  }
  File file = new File(filename);
  if (!file.existsSync()) throw "File $filename doesn't exist.";

  await tryToMinimize(file, nnbd);
}

Future tryToMinimize(File file, bool nnbd) async {
  Uint8List data;
  try {
    String parsedString = getFileAsStringContent(file, nnbd);
    data = utf8.encode(parsedString);
  } catch (e) {
    // If this crash it's a crash in the scanner/parser. It's good to minimize
    // that too.
    data = file.readAsBytesSync();
  }

  print("Got data");

  Uri main = base.resolve("main.dart");

  CompilerContext compilerContext = setupCompilerContext(main);
  Component initialComponent = await getInitialComponent(compilerContext);
  MemoryFileSystem fs = compilerContext.options.fileSystem;

  print("Compiled initially (without data)");

  // First assure it actually crash on the input.
  if (!await crashesOnCompile(
      fs, main, data, compilerContext, initialComponent)) {
    throw "Input doesn't crash the compiler: ${dataToText(data)}";
  }
  print("Step #1: We did crash on the input!");

  // Try to delete lines.
  Uint8List latestCrashData =
      await deleteLines(data, fs, main, compilerContext, initialComponent);
  print("We're now at ${latestCrashData.length} bytes.");

  // Now try to delete 'arbitrarily' (for any given start offset do an
  // exponential binary search).
  int prevLength = latestCrashData.length;
  while (true) {
    latestCrashData = await binarySearchDeleteData(
        latestCrashData, fs, main, compilerContext, initialComponent);

    if (latestCrashData.length == prevLength) {
      // No progress.
      break;
    } else {
      print("We're now at ${latestCrashData.length} bytes");
      prevLength = latestCrashData.length;
    }
  }

  print("Got it down to ${latestCrashData.length} bytes: "
      "${dataToText(latestCrashData)}");
  try {
    String utfDecoded = utf8.decode(latestCrashData, allowMalformed: true);
    print("That's '$utfDecoded' as text");
  } catch (e) {
    print("(which crashes when trying to decode as utf8)");
  }
}

Uint8List sublist(Uint8List data, int start, int end) {
  Uint8List result = new Uint8List(end - start);
  result.setRange(0, result.length, data, start);
  return result;
}

String dataToText(Uint8List data) {
  StringBuffer sb = new StringBuffer();
  String comma = "[";
  for (int i = 0; i < data.length; i++) {
    sb.write(comma);
    sb.write(data[i]);
    comma = ", ";
    if (i > 100) break;
  }
  if (data.length > 100) {
    sb.write("...");
  }
  sb.write("]");
  return sb.toString();
}

Future<Uint8List> binarySearchDeleteData(
    Uint8List latestCrashData,
    MemoryFileSystem fs,
    Uri main,
    CompilerContext compilerContext,
    Component initialComponent) async {
  int offset = 0;
  while (offset < latestCrashData.length) {
    print("Working at offset $offset of ${latestCrashData.length}");
    BytesBuilder builder = new BytesBuilder();
    builder.add(sublist(latestCrashData, 0, offset));
    builder.add(sublist(latestCrashData, offset + 1, latestCrashData.length));
    Uint8List candidate = builder.takeBytes();
    if (!await crashesOnCompile(
        fs, main, candidate, compilerContext, initialComponent)) {
      // Deleting 1 char didn't crash; don't try to delete anymore starting
      // here.
      offset++;
      continue;
    }

    // Find how long we can go.
    int crashingAt = 1;
    int noLongerCrashingAt;
    while (true) {
      int deleteChars = 2 * crashingAt;
      if (offset + deleteChars > latestCrashData.length) {
        deleteChars = latestCrashData.length - offset;
      }
      builder = new BytesBuilder();
      builder.add(sublist(latestCrashData, 0, offset));
      builder.add(sublist(
          latestCrashData, offset + deleteChars, latestCrashData.length));
      candidate = builder.takeBytes();
      if (!await crashesOnCompile(
          fs, main, candidate, compilerContext, initialComponent)) {
        noLongerCrashingAt = deleteChars;
        break;
      }
      crashingAt = deleteChars;
      if (crashingAt + offset == latestCrashData.length) break;
    }

    if (noLongerCrashingAt == null) {
      // We can delete the rest.
      latestCrashData = candidate;
      continue;
    }

    // Binary search between [crashingAt] and [noLongerCrashingAt].
    while (crashingAt < noLongerCrashingAt) {
      int mid = noLongerCrashingAt -
          ((noLongerCrashingAt - crashingAt) >> 1); // Get middle, rounding up.
      builder = new BytesBuilder();
      builder.add(sublist(latestCrashData, 0, offset));
      builder
          .add(sublist(latestCrashData, offset + mid, latestCrashData.length));
      candidate = builder.takeBytes();
      if (await crashesOnCompile(
          fs, main, candidate, compilerContext, initialComponent)) {
        crashingAt = mid;
      } else {
        // [noLongerCrashingAt] might actually crash now.
        noLongerCrashingAt = mid - 1;
      }
    }

    // This is basically an assert.
    builder = new BytesBuilder();
    builder.add(sublist(latestCrashData, 0, offset));
    builder.add(
        sublist(latestCrashData, offset + crashingAt, latestCrashData.length));
    candidate = builder.takeBytes();
    if (!await crashesOnCompile(
        fs, main, candidate, compilerContext, initialComponent)) {
      throw "Error in binary search.";
    }
    latestCrashData = candidate;
  }
  return latestCrashData;
}

Future<Uint8List> deleteLines(Uint8List data, MemoryFileSystem fs, Uri main,
    CompilerContext compilerContext, Component initialComponent) async {
  // Try to delete "lines".
  const int $LF = 10;
  Uint8List latestCrashData = data;
  List<Uint8List> lines = [];
  int start = 0;
  for (int i = 0; i < data.length; i++) {
    if (data[i] == $LF) {
      lines.add(sublist(data, start, i));
      start = i + 1;
    }
  }
  lines.add(sublist(data, start, data.length));
  List<bool> include = new List.filled(lines.length, true);
  for (int i = 0; i < lines.length; i++) {
    include[i] = false;
    final BytesBuilder builder = new BytesBuilder();
    for (int j = 0; j < lines.length; j++) {
      if (include[j]) {
        builder.add(lines[j]);
        if (j + 1 < lines.length) {
          builder.addByte($LF);
        }
      }
    }
    Uint8List candidate = builder.takeBytes();
    if (!await crashesOnCompile(
        fs, main, candidate, compilerContext, initialComponent)) {
      // Didn't crash => Can't remove line i.
      include[i] = true;
    } else {
      print("Can delete line $i");
      latestCrashData = candidate;
    }
  }
  return latestCrashData;
}

Future<bool> crashesOnCompile(MemoryFileSystem fs, Uri main, Uint8List data,
    CompilerContext compilerContext, Component initialComponent) async {
  fs.entityForUri(main).writeAsBytesSync(data);
  IncrementalCompiler incrementalCompiler =
      new IncrementalCompiler.fromComponent(compilerContext, initialComponent);
  incrementalCompiler.invalidate(main);
  try {
    await incrementalCompiler.computeDelta();
    return false;
  } catch (e) {
    return true;
  }
}

Future<Component> getInitialComponent(CompilerContext compilerContext) async {
  IncrementalCompiler incrementalCompiler =
      new IncrementalCompiler(compilerContext);
  Component originalComponent = await incrementalCompiler.computeDelta();
  return originalComponent;
}

CompilerContext setupCompilerContext(Uri main) {
  Uint8List sdkSummaryData = new File.fromUri(platformUri).readAsBytesSync();
  MemoryFileSystem fs = new MemoryFileSystem(base);
  CompilerOptions options = getOptions();

  options.fileSystem = fs;
  options.sdkRoot = null;
  options.sdkSummary = sdkSummary;
  options.omitPlatform = false;
  options.onDiagnostic = (DiagnosticMessage message) {
    // don't care.
  };
  fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);
  fs.entityForUri(main).writeAsStringSync("main() {}");

  CompilerContext compilerContext = new CompilerContext(
      new ProcessedOptions(options: options, inputs: [main]));
  return compilerContext;
}

String getFileAsStringContent(File file, bool nnbd) {
  Uint8List rawBytes = file.readAsBytesSync();
  List<int> lineStarts = new List<int>();

  Token firstToken = parser_suite.scanRawBytes(rawBytes,
      nnbd ? scannerConfiguration : scannerConfigurationNonNNBD, lineStarts);

  if (firstToken == null) {
    throw "Got null token from scanner";
  }

  ParserTestListener parserTestListener = new ParserTestListener(false);
  Parser parser = new Parser(parserTestListener);
  parser.parseUnit(firstToken);
  String parsedString =
      parser_suite.tokenStreamToString(firstToken, lineStarts).toString();
  return parsedString;
}

ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
    enableTripleShift: true,
    enableExtensionMethods: true,
    enableNonNullable: true);

ScannerConfiguration scannerConfigurationNonNNBD = new ScannerConfiguration(
    enableTripleShift: true,
    enableExtensionMethods: true,
    enableNonNullable: false);

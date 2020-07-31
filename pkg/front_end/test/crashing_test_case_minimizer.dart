// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;

import 'dart:io' show BytesBuilder, File, stdin;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, Token;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:kernel/ast.dart' show Component;

import 'package:kernel/target/targets.dart' show Target, TargetFlags;

import "package:vm/target/flutter.dart" show FlutterTarget;

import "package:vm/target/vm.dart" show VmTarget;

import 'incremental_load_from_dill_suite.dart' show getOptions;

import 'parser_test_listener.dart' show ParserTestListener;

import 'parser_suite.dart' as parser_suite;

final FakeFileSystem fs = new FakeFileSystem();
Uri mainUri;
Uri platformUri;
bool noPlatform = false;
bool nnbd = false;
bool widgetTransformation = false;
List<Uri> invalidate = [];
String targetString = "VM";
String expectedCrashLine;
bool byteDelete = false;
bool askAboutRedirectCrashTarget = false;
Set<String> askedAboutRedirect = {};

main(List<String> arguments) async {
  String filename;
  for (String arg in arguments) {
    if (arg.startsWith("--")) {
      if (arg == "--nnbd") {
        nnbd = true;
      } else if (arg.startsWith("--platform=")) {
        String platform = arg.substring("--platform=".length);
        platformUri = Uri.base.resolve(platform);
      } else if (arg == "--no-platform") {
        noPlatform = true;
      } else if (arg.startsWith("--invalidate=")) {
        for (String s in arg.substring("--invalidate=".length).split(",")) {
          invalidate.add(Uri.base.resolve(s));
        }
      } else if (arg.startsWith("--widgetTransformation")) {
        widgetTransformation = true;
      } else if (arg.startsWith("--target=VM")) {
        targetString = "VM";
      } else if (arg.startsWith("--target=flutter")) {
        targetString = "flutter";
      } else if (arg.startsWith("--target=ddc")) {
        targetString = "ddc";
      } else if (arg == "--byteDelete") {
        byteDelete = true;
      } else if (arg == "--ask-redirect-target") {
        askAboutRedirectCrashTarget = true;
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
  if (noPlatform) {
    int i = 0;
    while (platformUri == null || new File.fromUri(platformUri).existsSync()) {
      platformUri = Uri.base.resolve("nonexisting_$i");
      i++;
    }
  } else {
    if (platformUri == null) {
      throw "No platform given. Use --platform=/path/to/platform.dill";
    }
    if (!new File.fromUri(platformUri).existsSync()) {
      throw "The platform file '$platformUri' doesn't exist";
    }
  }
  if (filename == null) {
    throw "Need file to operate on";
  }
  File file = new File(filename);
  if (!file.existsSync()) throw "File $filename doesn't exist.";
  mainUri = file.absolute.uri;

  await tryToMinimize();
}

Future tryToMinimize() async {
  // Set main to be basically empty up front.
  fs.data[mainUri] = utf8.encode("main() {}");
  Component initialComponent = await getInitialComponent();
  print("Compiled initially (without data)");
  // Remove fake cache.
  fs.data.remove(mainUri);

  // First assure it actually crash on the input.
  if (!await crashesOnCompile(initialComponent)) {
    throw "Input doesn't crash the compiler.";
  }
  print("Step #1: We did crash on the input!");

  // All file should now be cached.
  fs._redirectAndRecord = false;

  // For all dart files: Parse them as set their source as the parsed source
  // to "get around" any encoding issues when printing later.
  Map<Uri, Uint8List> copy = new Map.from(fs.data);
  for (Uri uri in fs.data.keys) {
    String uriString = uri.toString();
    if (uriString.endsWith(".json") ||
        uriString.endsWith(".json") ||
        uriString.endsWith(".packages") ||
        uriString.endsWith(".dill") ||
        fs.data[uri] == null ||
        fs.data[uri].isEmpty) {
      // skip
    } else {
      try {
        String parsedString = getFileAsStringContent(fs.data[uri], nnbd);
        fs.data[uri] = utf8.encode(parsedString);
      } catch (e) {
        // crash in scanner/parser --- keep original file. This crash might
        // be what we're looking for!
      }
    }
  }
  if (!await crashesOnCompile(initialComponent)) {
    // Now - for whatever reason - we didn't crash. Restore.
    fs.data.clear();
    fs.data.addAll(copy);
  }

  // Operate on one file at a time: Try to delete all content in file.
  List<Uri> uris = new List<Uri>.from(fs.data.keys);

  bool removedSome = true;
  while (removedSome) {
    while (removedSome) {
      removedSome = false;
      for (int i = 0; i < uris.length; i++) {
        Uri uri = uris[i];
        if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;
        print("About to work on file $i of ${uris.length}");
        await deleteContent(uris, i, false, initialComponent);
        if (fs.data[uri] == null || fs.data[uri].isEmpty) removedSome = true;
      }
    }
    int left = 0;
    for (Uri uri in uris) {
      if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;
      left++;
    }
    print("There's now $left files of ${fs.data.length} files left");

    // Operate on one file at a time.
    for (Uri uri in fs.data.keys) {
      if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;

      print("Now working on $uri");

      // Try to delete lines.
      int prevLength = fs.data[uri].length;
      await deleteLines(uri, initialComponent);
      print("We're now at ${fs.data[uri].length} bytes for $uri.");
      if (prevLength != fs.data[uri].length) removedSome = true;
      if (fs.data[uri].isEmpty) continue;

      if (byteDelete) {
        // Now try to delete 'arbitrarily' (for any given start offset do an
        // exponential binary search).
        int prevLength = fs.data[uri].length;
        while (true) {
          await binarySearchDeleteData(uri, initialComponent);

          if (fs.data[uri].length == prevLength) {
            // No progress.
            break;
          } else {
            print("We're now at ${fs.data[uri].length} bytes");
            prevLength = fs.data[uri].length;
            removedSome = true;
          }
        }
      }
    }
  }

  print("\n\nDONE\n\n");

  for (Uri uri in uris) {
    if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;
    print("Uri $uri has this content:");

    try {
      String utfDecoded = utf8.decode(fs.data[uri], allowMalformed: true);
      print(utfDecoded);
    } catch (e) {
      print(fs.data[uri]);
      print("(which crashes when trying to decode as utf8)");
    }
    print("\n\n====================\n\n");
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

void binarySearchDeleteData(Uri uri, Component initialComponent) async {
  Uint8List latestCrashData = fs.data[uri];
  int offset = 0;
  while (offset < latestCrashData.length) {
    print("Working at offset $offset of ${latestCrashData.length}");
    BytesBuilder builder = new BytesBuilder();
    builder.add(sublist(latestCrashData, 0, offset));
    builder.add(sublist(latestCrashData, offset + 1, latestCrashData.length));
    Uint8List candidate = builder.takeBytes();
    fs.data[uri] = candidate;
    if (!await crashesOnCompile(initialComponent)) {
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
      fs.data[uri] = candidate;
      if (!await crashesOnCompile(initialComponent)) {
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
      fs.data[uri] = candidate;
      if (await crashesOnCompile(initialComponent)) {
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
    fs.data[uri] = candidate;
    if (!await crashesOnCompile(initialComponent)) {
      throw "Error in binary search.";
    }
    latestCrashData = candidate;
  }

  fs.data[uri] = latestCrashData;
}

void _tryToRemoveUnreferencedFileContent(Component initialComponent) async {
  // Check if there now are any unused files.
  if (_latestComponent == null) return;
  Set<Uri> neededUris = _latestComponent.uriToSource.keys.toSet();
  Map<Uri, Uint8List> copy = new Map.from(fs.data);
  bool removedSome = false;
  for (MapEntry<Uri, Uint8List> entry in fs.data.entries) {
    if (entry.value == null || entry.value.isEmpty) continue;
    if (!entry.key.toString().endsWith(".dart")) continue;
    if (!neededUris.contains(entry.key) && fs.data[entry.key].length != 0) {
      fs.data[entry.key] = new Uint8List(0);
      print(" => Can probably also delete ${entry.key}");
      removedSome = true;
    }
  }
  if (removedSome) {
    if (await crashesOnCompile(initialComponent)) {
      print(" => Yes; Could remove those too!");
    } else {
      print(" => No; Couldn't remove those too!");
      fs.data.clear();
      fs.data.addAll(copy);
    }
  }
}

void deleteContent(List<Uri> uris, int uriIndex, bool limitTo1,
    Component initialComponent) async {
  if (!limitTo1) {
    Map<Uri, Uint8List> copy = new Map.from(fs.data);
    // Try to remove content of i and the next 9 (10 files in total).
    for (int j = uriIndex; j < uriIndex + 10 && j < uris.length; j++) {
      Uri uri = uris[j];
      fs.data[uri] = new Uint8List(0);
    }
    if (!await crashesOnCompile(initialComponent)) {
      // Couldn't delete all 10 files. Restore and try the single one.
      fs.data.clear();
      fs.data.addAll(copy);
    } else {
      for (int j = uriIndex; j < uriIndex + 10 && j < uris.length; j++) {
        Uri uri = uris[j];
        print("Can delete all content of file $uri");
      }
      await _tryToRemoveUnreferencedFileContent(initialComponent);
      return;
    }
  }

  Uri uri = uris[uriIndex];
  Uint8List data = fs.data[uri];
  fs.data[uri] = new Uint8List(0);
  if (!await crashesOnCompile(initialComponent)) {
    print("Can't delete all content of file $uri -- keeping it (for now)");
    fs.data[uri] = data;
  } else {
    print("Can delete all content of file $uri");
    await _tryToRemoveUnreferencedFileContent(initialComponent);
  }
}

void deleteLines(Uri uri, Component initialComponent) async {
  // Try to delete "lines".
  Uint8List data = fs.data[uri];
  const int $LF = 10;
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
  Uint8List latestCrashData = data;
  int length = 1;
  int i = 0;
  while (i < lines.length) {
    if (i + length > lines.length) {
      length = lines.length - i;
    }
    for (int j = i; j < i + length; j++) {
      include[j] = false;
    }
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
    fs.data[uri] = candidate;
    if (!await crashesOnCompile(initialComponent)) {
      // Didn't crash => Can't remove line i-j.
      for (int j = i; j < i + length; j++) {
        include[j] = true;
      }
      if (length > 2) {
        // Retry with length 2 at same i.
        // The idea here is that for instance formatted json might have lines
        // looking like
        // {
        // }
        // where deleting just one line makes it invalid.
        length = 2;
      } else if (length > 1) {
        // Retry with length 1 at same i.
        length = 1;
      } else {
        // Couldn't with length 1 either.
        i++;
      }
    } else {
      print("Can delete line $i (inclusive) - ${i + length} (exclusive) "
          "(of ${lines.length})");
      latestCrashData = candidate;
      i += length;
      length *= 2;
    }
  }
  fs.data[uri] = latestCrashData;
}

Component _latestComponent;

Future<bool> crashesOnCompile(Component initialComponent) async {
  IncrementalCompiler incrementalCompiler;
  if (noPlatform) {
    incrementalCompiler = new IncrementalCompiler(setupCompilerContext());
  } else {
    incrementalCompiler = new IncrementalCompiler.fromComponent(
        setupCompilerContext(), initialComponent);
  }
  incrementalCompiler.invalidate(mainUri);
  try {
    _latestComponent = await incrementalCompiler.computeDelta();
    for (Uri uri in invalidate) {
      incrementalCompiler.invalidate(uri);
      await incrementalCompiler.computeDelta();
    }
    _latestComponent = null; // if it didn't crash this isn't relevant.
    return false;
  } catch (e, st) {
    // Find line with #0 in it.
    String eWithSt = "$e\n\n$st";
    List<String> lines = eWithSt.split("\n");
    String foundLine;
    for (String line in lines) {
      if (line.startsWith("#0")) {
        foundLine = line;
        break;
      }
    }
    if (foundLine == null) throw "Unexpected crash without stacktrace: $e";
    if (expectedCrashLine == null) {
      print("Got $foundLine");
      expectedCrashLine = foundLine;
      return true;
    } else if (foundLine == expectedCrashLine) {
      return true;
    } else {
      print("Crashed, but another place: $foundLine");
      if (askAboutRedirectCrashTarget &&
          !askedAboutRedirect.contains(foundLine)) {
        while (true) {
          askedAboutRedirect.add(foundLine);
          print(eWithSt);
          print("Should we redirect to searching for that? (y/n)");
          String answer = stdin.readLineSync();
          if (answer == "yes" || answer == "y") {
            expectedCrashLine = foundLine;
            return true;
          } else if (answer == "no" || answer == "n") {
            break;
          } else {
            print("Didn't get that answer. "
                "Please answer 'yes, 'y', 'no' or 'n'");
          }
        }
      }
      return false;
    }
  }
}

Future<Component> getInitialComponent() async {
  IncrementalCompiler incrementalCompiler =
      new IncrementalCompiler(setupCompilerContext());
  Component originalComponent = await incrementalCompiler.computeDelta();
  return originalComponent;
}

CompilerContext setupCompilerContext() {
  CompilerOptions options = getOptions();

  TargetFlags targetFlags = new TargetFlags(
      enableNullSafety: nnbd, trackWidgetCreation: widgetTransformation);
  Target target;
  switch (targetString) {
    case "VM":
      target = new VmTarget(targetFlags);
      break;
    case "flutter":
      target = new FlutterTarget(targetFlags);
      break;
    case "ddc":
      target = new DevCompilerTarget(targetFlags);
      break;
    default:
      throw "Unknown target '$target'";
  }
  options.target = target;
  options.fileSystem = fs;
  options.sdkRoot = null;
  options.sdkSummary = platformUri;
  options.omitPlatform = false;
  options.onDiagnostic = (DiagnosticMessage message) {
    // don't care.
  };
  if (noPlatform) {
    options.librariesSpecificationUri = null;
  }

  CompilerContext compilerContext = new CompilerContext(
      new ProcessedOptions(options: options, inputs: [mainUri]));
  return compilerContext;
}

String getFileAsStringContent(Uint8List rawBytes, bool nnbd) {
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

class FakeFileSystem extends FileSystem {
  bool _redirectAndRecord = true;
  final Map<Uri, Uint8List> data = {};

  @override
  FileSystemEntity entityForUri(Uri uri) {
    return new FakeFileSystemEntity(this, uri);
  }
}

class FakeFileSystemEntity extends FileSystemEntity {
  final FakeFileSystem fs;
  final Uri uri;
  FakeFileSystemEntity(this.fs, this.uri);

  void _ensureCachedIfOk() {
    if (fs.data.containsKey(uri)) return;
    if (!fs._redirectAndRecord) {
      throw "Asked for file in non-recording mode that wasn't known";
    }
    File f = new File.fromUri(uri);
    if (!f.existsSync()) {
      fs.data[uri] = null;
      return;
    }
    fs.data[uri] = f.readAsBytesSync();
  }

  @override
  Future<bool> exists() {
    _ensureCachedIfOk();
    Uint8List data = fs.data[uri];
    if (data == null) return Future.value(false);
    return Future.value(true);
  }

  @override
  Future<List<int>> readAsBytes() {
    _ensureCachedIfOk();
    Uint8List data = fs.data[uri];
    if (data == null) throw new FileSystemException(uri, "File doesn't exist.");
    return Future.value(data);
  }

  @override
  Future<String> readAsString() {
    _ensureCachedIfOk();
    Uint8List data = fs.data[uri];
    if (data == null) throw new FileSystemException(uri, "File doesn't exist.");
    return Future.value(utf8.decode(data));
  }
}

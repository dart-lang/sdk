// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future, StreamSubscription;

import 'dart:convert' show JsonEncoder, jsonDecode, utf8;

import 'dart:io' show BytesBuilder, File, stdin, stdout;
import 'dart:math' show max;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ErrorToken, ScannerConfiguration, Token;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;

import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/kernel/utils.dart' show ByteSink;
import 'package:front_end/src/fasta/util/direct_parser_ast.dart';
import 'package:front_end/src/fasta/util/direct_parser_ast_helper.dart';

import 'package:front_end/src/fasta/util/textual_outline.dart'
    show textualOutline;

import 'package:kernel/ast.dart' show Component;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/target/targets.dart' show Target, TargetFlags;
import 'package:package_config/package_config.dart';

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
bool experimentalInvalidation = false;
bool serialize = false;
bool widgetTransformation = false;
List<Uri> invalidate = [];
String targetString = "VM";
String expectedCrashLine;
bool oldBlockDelete = false;
bool lineDelete = false;
bool byteDelete = false;
bool askAboutRedirectCrashTarget = false;
int stackTraceMatches = 1;
Set<String> askedAboutRedirect = {};
bool _quit = false;
bool skip = false;

Future<bool> shouldQuit() async {
  // allow some time for stdin.listen to process data.
  await new Future.delayed(new Duration(milliseconds: 5));
  return _quit;
}

// TODO(jensj): Option to automatically find and search for _all_ crashes that
// it uncovers --- i.e. it currently has an option to ask if we want to search
// for the other crash instead --- add an option so it does that automatically
// for everything it sees. One can possibly just make a copy of the state of
// the file system and save that for later...

main(List<String> arguments) async {
  String filename;
  Uri loadFsJson;
  for (String arg in arguments) {
    if (arg.startsWith("--")) {
      if (arg == "--nnbd") {
        nnbd = true;
      } else if (arg == "--experimental-invalidation") {
        experimentalInvalidation = true;
      } else if (arg == "--serialize") {
        serialize = true;
      } else if (arg.startsWith("--fsJson=")) {
        String jsJson = arg.substring("--fsJson=".length);
        loadFsJson = Uri.base.resolve(jsJson);
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
      } else if (arg == "--oldBlockDelete") {
        oldBlockDelete = true;
      } else if (arg == "--lineDelete") {
        lineDelete = true;
      } else if (arg == "--byteDelete") {
        byteDelete = true;
      } else if (arg == "--ask-redirect-target") {
        askAboutRedirectCrashTarget = true;
      } else if (arg.startsWith("--stack-matches=")) {
        String stackMatches = arg.substring("--stack-matches=".length);
        stackTraceMatches = int.parse(stackMatches);
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

  try {
    await tryToMinimize(loadFsJson);
  } catch (e) {
    print("\n\n\nABOUT TO CRASH. DUMPING FS.");
    dumpFsToJson();
    print("\n\n\nABOUT TO CRASH. FS DUMPED.");
    rethrow;
  }
}

Future tryToMinimize(Uri loadFsJson) async {
  // Set main to be basically empty up front.
  fs.data[mainUri] = utf8.encode("main() {}");
  Component initialComponent = await getInitialComponent();
  print("Compiled initially (without data)");
  // Remove fake cache.
  fs.data.remove(mainUri);

  if (loadFsJson != null) {
    File f = new File.fromUri(loadFsJson);
    fs.initializeFromJson((jsonDecode(f.readAsStringSync())));
  }

  // First assure it actually crash on the input.
  if (!await crashesOnCompile(initialComponent)) {
    throw "Input doesn't crash the compiler.";
  }
  print("Step #1: We did crash on the input!");

  // All file should now be cached.
  fs._redirectAndRecord = false;

  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (e) {
    print("error setting settings on stdin");
  }
  StreamSubscription<List<int>> stdinSubscription =
      stdin.listen((List<int> event) {
    if (event.length == 1 && event.single == "q".codeUnits.single) {
      print("\n\nGot told to quit!\n\n");
      _quit = true;
    } else if (event.length == 1 && event.single == "s".codeUnits.single) {
      print("\n\nGot told to skip!\n\n");
      skip = true;
    } else if (event.length == 1 && event.single == "i".codeUnits.single) {
      print("\n\n--- STATUS INFORMATION START ---\n\n");
      int totalFiles = 0;
      int emptyFiles = 0;
      int combinedSize = 0;
      for (Uri uri in fs.data.keys) {
        final Uint8List originalBytes = fs.data[uri];
        if (originalBytes == null) continue;
        totalFiles++;
        if (originalBytes.isEmpty) emptyFiles++;
        combinedSize += originalBytes.length;
      }
      print("Total files left: $totalFiles.");
      print("Of which empty: $emptyFiles.");
      print("Combined size left: $combinedSize bytes.");
      print("\n\n--- STATUS INFORMATION END ---\n\n");
      skip = true;
    } else {
      print("\n\nGot stdin input: $event\n\n");
    }
  });

  // For all dart files: Parse them as set their source as the parsed source
  // to "get around" any encoding issues when printing later.
  Map<Uri, Uint8List> copy = new Map.from(fs.data);
  for (Uri uri in fs.data.keys) {
    if (await shouldQuit()) break;
    String uriString = uri.toString();
    if (uriString.endsWith(".json") ||
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

  // TODO(jensj): Can we "thread" this?
  bool changedSome = true;
  while (changedSome) {
    if (await shouldQuit()) break;
    while (changedSome) {
      if (await shouldQuit()) break;
      changedSome = false;
      for (int i = 0; i < uris.length; i++) {
        if (await shouldQuit()) break;
        Uri uri = uris[i];
        if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;
        print("About to work on file $i of ${uris.length}");
        await deleteContent(uris, i, false, initialComponent);
        if (fs.data[uri] == null || fs.data[uri].isEmpty) changedSome = true;
      }
    }

    // Try to delete empty files.
    bool changedSome2 = true;
    while (changedSome2) {
      if (await shouldQuit()) break;
      changedSome2 = false;
      for (int i = 0; i < uris.length; i++) {
        if (await shouldQuit()) break;
        Uri uri = uris[i];
        if (fs.data[uri] == null || fs.data[uri].isNotEmpty) continue;
        print("About to work on file $i of ${uris.length}");
        await deleteContent(uris, i, false, initialComponent, deleteFile: true);
        if (fs.data[uri] == null) {
          changedSome = true;
          changedSome2 = true;
        }
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
      if (await shouldQuit()) break;
      if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;

      print("Now working on $uri");

      int prevLength = fs.data[uri].length;

      await deleteBlocks(uri, initialComponent);
      await deleteEmptyLines(uri, initialComponent);

      if (oldBlockDelete) {
        // Try to delete blocks.
        await deleteBlocksOld(uri, initialComponent);
      }

      if (lineDelete) {
        // Try to delete lines.
        await deleteLines(uri, initialComponent);
      }

      print("We're now at ${fs.data[uri].length} bytes for $uri "
          "(was $prevLength).");
      if (prevLength != fs.data[uri].length) changedSome = true;
      if (fs.data[uri].isEmpty) continue;

      if (byteDelete) {
        // Now try to delete 'arbitrarily' (for any given start offset do an
        // exponential binary search).
        int prevLength = fs.data[uri].length;
        while (true) {
          if (await shouldQuit()) break;
          await binarySearchDeleteData(uri, initialComponent);

          if (fs.data[uri].length == prevLength) {
            // No progress.
            break;
          } else {
            print("We're now at ${fs.data[uri].length} bytes");
            prevLength = fs.data[uri].length;
            changedSome = true;
          }
        }
      }
    }
    for (Uri uri in fs.data.keys) {
      if (fs.data[uri] == null || fs.data[uri].isEmpty) continue;
      if (await shouldQuit()) break;
      if (await attemptInline(uri, initialComponent)) {
        changedSome = true;
      }
    }
  }

  if (await shouldQuit()) {
    print("\n\nASKED TO QUIT\n\n");
  } else {
    print("\n\nDONE\n\n");
  }

  Uri jsonFsOut = dumpFsToJson();

  await stdinSubscription.cancel();

  if (!await shouldQuit()) {
    // Test converting to incremental compiler yaml test.
    outputIncrementalCompilerYamlTest();
    print("\n\n\n");

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

    print("Wrote json file system to $jsonFsOut");
  }
}

Uri dumpFsToJson() {
  JsonEncoder jsonEncoder = new JsonEncoder.withIndent("  ");
  String jsonFs = jsonEncoder.convert(fs);
  int i = 0;
  Uri jsonFsOut;
  while (jsonFsOut == null || new File.fromUri(jsonFsOut).existsSync()) {
    jsonFsOut = Uri.base.resolve("crash_minimizer_result_$i");
    i++;
  }
  new File.fromUri(jsonFsOut).writeAsStringSync(jsonFs);
  print("Wrote json file system to $jsonFsOut");
  return jsonFsOut;
}

/// Attempts to inline small files in other files.
/// Returns true if anything was changed, i.e. if at least one inlining was a
/// success.
Future<bool> attemptInline(Uri uri, Component initialComponent) async {
  // Don't attempt to inline the main uri --- that's our entry!
  if (uri == mainUri) return false;

  Uint8List inlineData = fs.data[uri];
  bool hasMultipleLines = false;
  for (int i = 0; i < inlineData.length; i++) {
    if (inlineData[i] == $LF) {
      hasMultipleLines = true;
      break;
    }
  }
  // TODO(jensj): Maybe inline slightly bigger files too?
  if (hasMultipleLines) {
    return false;
  }

  Uri inlinableUri = uri;

  int compileTry = 0;
  bool changed = false;

  for (Uri uri in fs.data.keys) {
    final Uint8List originalBytes = fs.data[uri];
    if (originalBytes == null || originalBytes.isEmpty) continue;
    DirectParserASTContentCompilationUnitEnd ast = getAST(originalBytes,
        includeBody: false,
        includeComments: false,
        enableExtensionMethods: true,
        enableNonNullable: nnbd);
    // Find all imports/exports of this file (if any).
    // If finding any:
    // * remove all of them, then
    // * find the end of the last import/export, and
    // * insert the content of the file there.
    // * if that *doesn't* work and we've inserted an export,
    //   try converting that to an import instead.
    List<Replacement> replacements = [];
    for (DirectParserASTContentImportEnd import in ast.getImports()) {
      Token importUriToken = import.importKeyword.next;
      Uri importUri = _getUri(importUriToken, uri);
      if (inlinableUri == importUri) {
        replacements.add(new Replacement(
            import.importKeyword.offset - 1, import.semicolon.offset + 1));
      }
    }
    for (DirectParserASTContentExportEnd export in ast.getExports()) {
      Token exportUriToken = export.exportKeyword.next;
      Uri exportUri = _getUri(exportUriToken, uri);
      if (inlinableUri == exportUri) {
        replacements.add(new Replacement(
            export.exportKeyword.offset - 1, export.semicolon.offset + 1));
      }
    }
    if (replacements.isEmpty) continue;

    // Step 1: Remove all imports/exports of this file.
    Uint8List candidate = _replaceRange(replacements, originalBytes);

    // Step 2: Find the last import/export.
    int offsetOfLast = 0;
    ast = getAST(candidate,
        includeBody: false,
        includeComments: false,
        enableExtensionMethods: true,
        enableNonNullable: nnbd);
    for (DirectParserASTContentImportEnd import in ast.getImports()) {
      offsetOfLast = max(offsetOfLast, import.semicolon.offset + 1);
    }
    for (DirectParserASTContentExportEnd export in ast.getExports()) {
      offsetOfLast = max(offsetOfLast, export.semicolon.offset + 1);
    }

    // Step 3: Insert the content of the file there. Note, though,
    // that any imports/exports in _that_ file should be changed to be valid
    // in regards to the new placement.
    BytesBuilder builder = new BytesBuilder();
    for (int i = 0; i < offsetOfLast; i++) {
      builder.addByte(candidate[i]);
    }
    builder.addByte($LF);
    builder.add(_rewriteImportsExportsToUri(inlineData, uri, inlinableUri));
    builder.addByte($LF);
    for (int i = offsetOfLast; i < candidate.length; i++) {
      builder.addByte(candidate[i]);
    }
    candidate = builder.takeBytes();

    // Step 4: Try it out.
    if (await shouldQuit()) break;
    if (skip) {
      skip = false;
      break;
    }
    stdout.write(".");
    compileTry++;
    if (compileTry % 50 == 0) {
      stdout.write("(at $compileTry)\n");
    }
    fs.data[uri] = candidate;
    if (await crashesOnCompile(initialComponent)) {
      print("Could inline $inlinableUri into $uri.");
      changed = true;
      // File was already updated.
    } else {
      // Couldn't replace that.
      // Insert the original again.
      fs.data[uri] = originalBytes;

      // If we've inlined an export, try changing that to an import.
      builder = new BytesBuilder();
      for (int i = 0; i < offsetOfLast; i++) {
        builder.addByte(candidate[i]);
      }
      // TODO(jensj): Only try compile again, if export was actually converted
      // to import.
      builder.addByte($LF);
      builder.add(_rewriteImportsExportsToUri(inlineData, uri, inlinableUri,
          convertExportToImport: true));
      builder.addByte($LF);
      for (int i = offsetOfLast; i < candidate.length; i++) {
        builder.addByte(candidate[i]);
      }
      candidate = builder.takeBytes();

      // Step 4: Try it out.
      if (await shouldQuit()) break;
      if (skip) {
        skip = false;
        break;
      }
      stdout.write(".");
      compileTry++;
      if (compileTry % 50 == 0) {
        stdout.write("(at $compileTry)\n");
      }
      fs.data[uri] = candidate;
      if (await crashesOnCompile(initialComponent)) {
        print("Could inline $inlinableUri into $uri "
            "(by converting export to import).");
        changed = true;
        // File was already updated.
      } else {
        // Couldn't replace that.
        // Insert the original again.
        fs.data[uri] = originalBytes;
      }
    }
  }

  return changed;
}

Uint8List _rewriteImportsExportsToUri(Uint8List oldData, Uri newUri, Uri oldUri,
    {bool convertExportToImport: false}) {
  DirectParserASTContentCompilationUnitEnd ast = getAST(oldData,
      includeBody: false,
      includeComments: false,
      enableExtensionMethods: true,
      enableNonNullable: nnbd);
  List<Replacement> replacements = [];
  for (DirectParserASTContentImportEnd import in ast.getImports()) {
    _rewriteImportsExportsToUriInternal(
        import.importKeyword.next, oldUri, replacements, newUri);
  }
  for (DirectParserASTContentExportEnd export in ast.getExports()) {
    if (convertExportToImport) {
      replacements.add(new Replacement(
        export.exportKeyword.offset - 1,
        export.exportKeyword.offset + export.exportKeyword.length,
        nullOrReplacement: utf8.encode('import'),
      ));
    }
    _rewriteImportsExportsToUriInternal(
        export.exportKeyword.next, oldUri, replacements, newUri);
  }
  if (replacements.isNotEmpty) {
    Uint8List candidate = _replaceRange(replacements, oldData);
    return candidate;
  }
  return oldData;
}

void _rewriteImportsExportsToUriInternal(
    Token uriToken, Uri oldUri, List<Replacement> replacements, Uri newUri) {
  Uri tokenUri = _getUri(uriToken, oldUri, resolvePackage: false);
  if (tokenUri.scheme == "package" || tokenUri.scheme == "dart") return;
  Uri asPackageUri = _getImportUri(tokenUri);
  if (asPackageUri.scheme == "package") {
    // Just replace with this package uri.
    replacements.add(new Replacement(
      uriToken.offset - 1,
      uriToken.offset + uriToken.length,
      nullOrReplacement: utf8.encode('"${asPackageUri.toString()}"'),
    ));
  } else {
    // TODO(jensj): Rewrite relative path to be correct.
    throw "Rewrite $oldUri importing/exporting $tokenUri as $uriToken "
        "for $newUri (notice $asPackageUri)";
  }
}

Uri _getUri(Token uriToken, Uri uri, {bool resolvePackage: true}) {
  String uriString = uriToken.lexeme;
  uriString = uriString.substring(1, uriString.length - 1);
  Uri uriTokenUri = uri.resolve(uriString);
  if (resolvePackage && uriTokenUri.scheme == "package") {
    Package package = _latestIncrementalCompiler
        .currentPackagesMap[uriTokenUri.pathSegments.first];
    uriTokenUri = package.packageUriRoot
        .resolve(uriTokenUri.pathSegments.skip(1).join("/"));
  }
  return uriTokenUri;
}

Uri _getImportUri(Uri uri) {
  return _latestIncrementalCompiler.userCode
      .getEntryPointUri(uri, issueProblem: false);
}

void outputIncrementalCompilerYamlTest() {
  int dartFiles = 0;
  for (MapEntry<Uri, Uint8List> entry in fs.data.entries) {
    if (entry.key.pathSegments.last.endsWith(".dart")) {
      if (entry.value != null) dartFiles++;
    }
  }

  print("------ Reproduction as semi-done incremental yaml test file ------");

  // TODO(jensj): don't use full uris.
  print("""
# Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Reproduce a crash.

type: newworld""");
  if (widgetTransformation) {
    print("trackWidgetCreation: true");
    print("target: DDC # basically needed for widget creation to be run");
  }
  print("""
worlds:
  - entry: $mainUri""");
  if (experimentalInvalidation) {
    print("    experiments: alternative-invalidation-strategy");
  }
  print("    sources:");
  for (MapEntry<Uri, Uint8List> entry in fs.data.entries) {
    if (entry.value == null) continue;
    print("      ${entry.key}: |");
    String string = utf8.decode(entry.value);
    List<String> lines = string.split("\n");
    for (String line in lines) {
      print("        $line");
    }
  }
  print("    expectedLibraryCount: $dartFiles "
      "# with parts this is not right");
  print("");

  for (Uri uri in invalidate) {
    print("  - entry: $mainUri");
    if (experimentalInvalidation) {
      print("    experiments: alternative-invalidation-strategy");
    }
    print("    worldType: updated");
    print("    expectInitializeFromDill: false # or true?");
    print("    invalidate:");
    print("      - $uri");
    print("    expectedLibraryCount: $dartFiles "
        "# with parts this is not right");
    print("    expectsRebuildBodiesOnly: true # or false?");
    print("");
  }

  print("------------------------------------------------------------------");
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

void _tryToRemoveUnreferencedFileContent(Component initialComponent,
    {bool deleteFile: false}) async {
  // Check if there now are any unused files.
  if (_latestComponent == null) return;
  Set<Uri> neededUris = _latestComponent.uriToSource.keys.toSet();
  Map<Uri, Uint8List> copy = new Map.from(fs.data);
  bool removedSome = false;
  if (await shouldQuit()) return;
  for (MapEntry<Uri, Uint8List> entry in fs.data.entries) {
    if (entry.value == null || entry.value.isEmpty) continue;
    if (!entry.key.toString().endsWith(".dart")) continue;
    if (!neededUris.contains(entry.key) && fs.data[entry.key].length != 0) {
      if (deleteFile) {
        fs.data[entry.key] = null;
      } else {
        fs.data[entry.key] = new Uint8List(0);
      }
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

void deleteContent(
    List<Uri> uris, int uriIndex, bool limitTo1, Component initialComponent,
    {bool deleteFile: false}) async {
  String extraMessageText = "all content of ";
  if (deleteFile) extraMessageText = "";

  if (!limitTo1) {
    if (await shouldQuit()) return;
    Map<Uri, Uint8List> copy = new Map.from(fs.data);
    // Try to remove content of i and the next 9 (10 files in total).
    for (int j = uriIndex; j < uriIndex + 10 && j < uris.length; j++) {
      Uri uri = uris[j];
      if (deleteFile) {
        fs.data[uri] = null;
      } else {
        fs.data[uri] = new Uint8List(0);
      }
    }
    if (!await crashesOnCompile(initialComponent)) {
      // Couldn't delete all 10 files. Restore and try the single one.
      fs.data.clear();
      fs.data.addAll(copy);
    } else {
      for (int j = uriIndex; j < uriIndex + 10 && j < uris.length; j++) {
        Uri uri = uris[j];
        print("Can delete ${extraMessageText}file $uri");
      }
      await _tryToRemoveUnreferencedFileContent(initialComponent,
          deleteFile: deleteFile);
      return;
    }
  }

  if (await shouldQuit()) return;
  Uri uri = uris[uriIndex];
  Uint8List data = fs.data[uri];
  if (deleteFile) {
    fs.data[uri] = null;
  } else {
    fs.data[uri] = new Uint8List(0);
  }
  if (!await crashesOnCompile(initialComponent)) {
    print("Can't delete ${extraMessageText}file $uri -- keeping it (for now)");
    fs.data[uri] = data;

    // For dart files we can't truncate completely try to "outline" them
    // instead.
    if (uri.toString().endsWith(".dart")) {
      String textualOutlined =
          textualOutline(data)?.replaceAll(RegExp(r'\n+'), "\n");

      bool outlined = false;
      if (textualOutlined != null) {
        Uint8List candidate = utf8.encode(textualOutlined);
        if (candidate.length != fs.data[uri].length) {
          if (await shouldQuit()) return;
          fs.data[uri] = candidate;
          if (!await crashesOnCompile(initialComponent)) {
            print("Can't outline the file $uri -- keeping it (for now)");
            fs.data[uri] = data;
          } else {
            outlined = true;
            print(
                "Can outline the file $uri (now ${fs.data[uri].length} bytes)");
          }
        }
      }
      if (!outlined) {
        // We can probably at least remove all comments then...
        try {
          List<String> strings = utf8.decode(fs.data[uri]).split("\n");
          List<String> stringsLeft = [];
          for (String string in strings) {
            if (!string.trim().startsWith("//")) stringsLeft.add(string);
          }

          Uint8List candidate = utf8.encode(stringsLeft.join("\n"));
          if (candidate.length != fs.data[uri].length) {
            if (await shouldQuit()) return;
            fs.data[uri] = candidate;
            if (!await crashesOnCompile(initialComponent)) {
              print("Can't remove comments for file $uri -- "
                  "keeping it (for now)");
              fs.data[uri] = data;
            } else {
              print("Removed comments for the file $uri");
            }
          }
        } catch (e) {
          // crash in scanner/parser --- keep original file. This crash might
          // be what we're looking for!
        }
      }
    }
  } else {
    print("Can delete ${extraMessageText}file $uri");
    await _tryToRemoveUnreferencedFileContent(initialComponent);
  }
}

void deleteBlocksOld(Uri uri, Component initialComponent) async {
  if (uri.toString().endsWith(".json")) {
    // Try to find annoying
    //
    //    },
    //    {
    //    }
    //
    // part of json and remove it.
    Uint8List data = fs.data[uri];
    String string = utf8.decode(data);
    List<String> lines = string.split("\n");
    for (int i = 0; i < lines.length - 2; i++) {
      if (lines[i].trim() == "}," &&
          lines[i + 1].trim() == "{" &&
          lines[i + 2].trim() == "}") {
        // This is the pattern we wanted to find. Remove it.
        lines.removeRange(i, i + 2);
        i--;
      }
    }
    string = lines.join("\n");
    fs.data[uri] = utf8.encode(string);
    if (!await crashesOnCompile(initialComponent)) {
      // For some reason that didn't work.
      fs.data[uri] = data;
    }
  }
  if (!uri.toString().endsWith(".dart")) return;

  Uint8List data = fs.data[uri];
  Uint8List latestCrashData = data;

  List<int> lineStarts = <int>[];

  Token firstToken = parser_suite.scanRawBytes(data,
      nnbd ? scannerConfiguration : scannerConfigurationNonNNBD, lineStarts);

  if (firstToken == null) {
    print("Got null token from scanner for $uri");
    return;
  }

  int compileTry = 0;
  Token token = firstToken;
  while (token is ErrorToken) {
    token = token.next;
  }
  List<Replacement> replacements = [];
  while (token != null && !token.isEof) {
    bool tryCompile = false;
    Token skipToToken = token;
    // Skip very small blocks (e.g. "{}" or "{\n}");
    if (token.endGroup != null && token.offset + 3 < token.endGroup.offset) {
      replacements.add(new Replacement(token.offset, token.endGroup.offset));
      tryCompile = true;
      skipToToken = token.endGroup;
    } else if (token.lexeme == "@") {
      if (token.next.next.endGroup != null) {
        int end = token.next.next.endGroup.offset;
        skipToToken = token.next.next.endGroup;
        replacements.add(new Replacement(token.offset - 1, end + 1));
        tryCompile = true;
      }
    } else if (token.lexeme == "assert") {
      if (token.next.endGroup != null) {
        int end = token.next.endGroup.offset;
        skipToToken = token.next.endGroup;
        if (token.next.endGroup.next.lexeme == ",") {
          end = token.next.endGroup.next.offset;
          skipToToken = token.next.endGroup.next;
        }
        // +/- 1 to not include the start and the end character.
        replacements.add(new Replacement(token.offset - 1, end + 1));
        tryCompile = true;
      }
    } else if ((token.lexeme == "abstract" && token.next.lexeme == "class") ||
        token.lexeme == "class" ||
        token.lexeme == "enum" ||
        token.lexeme == "mixin" ||
        token.lexeme == "static" ||
        token.next.lexeme == "get" ||
        token.next.lexeme == "set" ||
        token.next.next.lexeme == "(" ||
        (token.next.lexeme == "<" &&
            token.next.endGroup != null &&
            token.next.endGroup.next.next.lexeme == "(")) {
      // Try to find and remove the entire class/enum/mixin/
      // static procedure/getter/setter/simple procedure.
      Token bracket = token;
      for (int i = 0; i < 20; i++) {
        // Find "{", but only go a maximum of 20 tokens to do that.
        bracket = bracket.next;
        if (bracket.lexeme == "{" && bracket.endGroup != null) {
          break;
        } else if ((bracket.lexeme == "(" || bracket.lexeme == "<") &&
            bracket.endGroup != null) {
          bracket = bracket.endGroup;
        }
      }
      if (bracket.lexeme == "{" && bracket.endGroup != null) {
        int end = bracket.endGroup.offset;
        skipToToken = bracket.endGroup;
        // +/- 1 to not include the start and the end character.
        replacements.add(new Replacement(token.offset - 1, end + 1));
        tryCompile = true;
      }
    }

    if (tryCompile) {
      if (await shouldQuit()) break;
      if (skip) {
        skip = false;
        break;
      }
      stdout.write(".");
      compileTry++;
      if (compileTry % 50 == 0) {
        stdout.write("(at $compileTry)\n");
      }
      Uint8List candidate = _replaceRange(replacements, data);
      fs.data[uri] = candidate;
      if (await crashesOnCompile(initialComponent)) {
        print("Found block from "
            "${replacements.last.from} to "
            "${replacements.last.to} "
            "that can be removed.");
        latestCrashData = candidate;
        token = skipToToken;
      } else {
        // Couldn't delete that.
        replacements.removeLast();
      }
    }
    token = token.next;
  }
  fs.data[uri] = latestCrashData;
}

void deleteBlocks(final Uri uri, Component initialComponent) async {
  if (uri.toString().endsWith(".json")) {
    // Try to find annoying
    //
    //    },
    //    {
    //    }
    //
    // part of json and remove it.
    Uint8List data = fs.data[uri];
    String string = utf8.decode(data);
    List<String> lines = string.split("\n");
    for (int i = 0; i < lines.length - 2; i++) {
      if (lines[i].trim() == "}," &&
          lines[i + 1].trim() == "{" &&
          lines[i + 2].trim() == "}") {
        // This is the pattern we wanted to find. Remove it.
        lines.removeRange(i, i + 2);
        i--;
      }
    }
    string = lines.join("\n");
    Uint8List candidate = utf8.encode(string);
    if (candidate.length != data.length) {
      fs.data[uri] = candidate;
      if (!await crashesOnCompile(initialComponent)) {
        // For some reason that didn't work.
        fs.data[uri] = data;
      }
    }

    // Try to load json and remove blocks.
    try {
      Map json = jsonDecode(utf8.decode(data));
      Map jsonModified = new Map.from(json);
      List packages = json["packages"];
      List packagesModified = new List.from(packages);
      jsonModified["packages"] = packagesModified;
      int i = 0;
      print("Note there's ${packagesModified.length} packages in .json");
      JsonEncoder jsonEncoder = new JsonEncoder.withIndent("  ");
      while (i < packagesModified.length) {
        var oldEntry = packagesModified.removeAt(i);
        String jsonString = jsonEncoder.convert(jsonModified);
        candidate = utf8.encode(jsonString);
        Uint8List previous = fs.data[uri];
        fs.data[uri] = candidate;
        if (!await crashesOnCompile(initialComponent)) {
          // Couldn't remove that part.
          fs.data[uri] = previous;
          packagesModified.insert(i, oldEntry);
          i++;
        } else {
          print(
              "Removed package from .json (${packagesModified.length} left).");
        }
      }
    } catch (e) {
      // Couldn't decode it, so don't try to do anything.
    }
    return;
  }
  if (!uri.toString().endsWith(".dart")) return;

  Uint8List data = fs.data[uri];
  DirectParserASTContentCompilationUnitEnd ast = getAST(data,
      includeBody: true,
      includeComments: false,
      enableExtensionMethods: true,
      enableNonNullable: nnbd);

  CompilationHelperClass helper = new CompilationHelperClass(data);

  // Try to remove top level things on at a time.
  for (DirectParserASTContent child in ast.children) {
    bool shouldCompile = false;
    String what = "";
    if (child.isClass()) {
      DirectParserASTContentClassDeclarationEnd cls = child.asClass();
      helper.replacements.add(
          new Replacement(cls.beginToken.offset - 1, cls.endToken.offset + 1));
      shouldCompile = true;
      what = "class";
    } else if (child.isMixinDeclaration()) {
      DirectParserASTContentMixinDeclarationEnd decl =
          child.asMixinDeclaration();
      helper.replacements.add(new Replacement(
          decl.mixinKeyword.offset - 1, decl.endToken.offset + 1));
      shouldCompile = true;
      what = "mixin";
    } else if (child.isNamedMixinDeclaration()) {
      DirectParserASTContentNamedMixinApplicationEnd decl =
          child.asNamedMixinDeclaration();
      helper.replacements.add(
          new Replacement(decl.begin.offset - 1, decl.endToken.offset + 1));
      shouldCompile = true;
      what = "named mixin";
    } else if (child.isExtension()) {
      DirectParserASTContentExtensionDeclarationEnd decl = child.asExtension();
      helper.replacements.add(new Replacement(
          decl.extensionKeyword.offset - 1, decl.endToken.offset + 1));
      shouldCompile = true;
      what = "extension";
    } else if (child.isTopLevelFields()) {
      DirectParserASTContentTopLevelFieldsEnd decl = child.asTopLevelFields();
      helper.replacements.add(new Replacement(
          decl.beginToken.offset - 1, decl.endToken.offset + 1));
      shouldCompile = true;
      what = "toplevel fields";
    } else if (child.isTopLevelMethod()) {
      DirectParserASTContentTopLevelMethodEnd decl = child.asTopLevelMethod();
      helper.replacements.add(new Replacement(
          decl.beginToken.offset - 1, decl.endToken.offset + 1));
      shouldCompile = true;
      what = "toplevel method";
    } else if (child.isEnum()) {
      DirectParserASTContentEnumEnd decl = child.asEnum();
      helper.replacements.add(new Replacement(
          decl.enumKeyword.offset - 1, decl.leftBrace.endGroup.offset + 1));
      shouldCompile = true;
      what = "enum";
    } else if (child.isTypedef()) {
      DirectParserASTContentFunctionTypeAliasEnd decl = child.asTypedef();
      helper.replacements.add(new Replacement(
          decl.typedefKeyword.offset - 1, decl.endToken.offset + 1));
      shouldCompile = true;
      what = "typedef";
    } else if (child.isMetadata()) {
      DirectParserASTContentMetadataStarEnd decl = child.asMetadata();
      List<DirectParserASTContentMetadataEnd> metadata =
          decl.getMetadataEntries();
      if (metadata.isNotEmpty) {
        helper.replacements.add(new Replacement(
            metadata.first.beginToken.offset - 1,
            metadata.last.endToken.offset));
        shouldCompile = true;
      }
      what = "metadata";
    } else if (child.isImport()) {
      DirectParserASTContentImportEnd decl = child.asImport();
      helper.replacements.add(new Replacement(
          decl.importKeyword.offset - 1, decl.semicolon.offset + 1));
      shouldCompile = true;
      what = "import";
    } else if (child.isExport()) {
      DirectParserASTContentExportEnd decl = child.asExport();
      helper.replacements.add(new Replacement(
          decl.exportKeyword.offset - 1, decl.semicolon.offset + 1));
      shouldCompile = true;
      what = "export";
    } else if (child.isLibraryName()) {
      DirectParserASTContentLibraryNameEnd decl = child.asLibraryName();
      helper.replacements.add(new Replacement(
          decl.libraryKeyword.offset - 1, decl.semicolon.offset + 1));
      shouldCompile = true;
      what = "library name";
    } else if (child.isPart()) {
      DirectParserASTContentPartEnd decl = child.asPart();
      helper.replacements.add(new Replacement(
          decl.partKeyword.offset - 1, decl.semicolon.offset + 1));
      shouldCompile = true;
      what = "part";
    } else if (child.isPartOf()) {
      DirectParserASTContentPartOfEnd decl = child.asPartOf();
      helper.replacements.add(new Replacement(
          decl.partKeyword.offset - 1, decl.semicolon.offset + 1));
      shouldCompile = true;
      what = "part of";
    } else if (child.isScript()) {
      var decl = child.asScript();
      helper.replacements.add(new Replacement(
          decl.token.offset - 1, decl.token.offset + decl.token.length));
      shouldCompile = true;
      what = "script";
    }

    if (shouldCompile) {
      bool success =
          await _tryReplaceAndCompile(helper, uri, initialComponent, what);
      if (helper.shouldQuit) return;
      if (!success) {
        if (child.isClass()) {
          // Also try to remove all content of the class.
          DirectParserASTContentClassDeclarationEnd decl = child.asClass();
          DirectParserASTContentClassOrMixinBodyEnd body =
              decl.getClassOrMixinBody();
          if (body.beginToken.offset + 2 < body.endToken.offset) {
            helper.replacements.add(
                new Replacement(body.beginToken.offset, body.endToken.offset));
            what = "class body";
            success = await _tryReplaceAndCompile(
                helper, uri, initialComponent, what);
            if (helper.shouldQuit) return;
          }

          if (!success) {
            // Also try to remove members one at a time.
            for (DirectParserASTContent child in body.children) {
              shouldCompile = false;
              if (child is DirectParserASTContentMemberEnd) {
                if (child.isClassConstructor()) {
                  DirectParserASTContentClassConstructorEnd memberDecl =
                      child.getClassConstructor();
                  helper.replacements.add(new Replacement(
                      memberDecl.beginToken.offset - 1,
                      memberDecl.endToken.offset + 1));
                  what = "class constructor";
                  shouldCompile = true;
                } else if (child.isClassFields()) {
                  DirectParserASTContentClassFieldsEnd memberDecl =
                      child.getClassFields();
                  helper.replacements.add(new Replacement(
                      memberDecl.beginToken.offset - 1,
                      memberDecl.endToken.offset + 1));
                  what = "class fields";
                  shouldCompile = true;
                } else if (child.isClassMethod()) {
                  DirectParserASTContentClassMethodEnd memberDecl =
                      child.getClassMethod();
                  helper.replacements.add(new Replacement(
                      memberDecl.beginToken.offset - 1,
                      memberDecl.endToken.offset + 1));
                  what = "class method";
                  shouldCompile = true;
                } else if (child.isClassFactoryMethod()) {
                  DirectParserASTContentClassFactoryMethodEnd memberDecl =
                      child.getClassFactoryMethod();
                  helper.replacements.add(new Replacement(
                      memberDecl.beginToken.offset - 1,
                      memberDecl.endToken.offset + 1));
                  what = "class factory method";
                  shouldCompile = true;
                } else {
                  // throw "$child --- ${child.children}";
                  continue;
                }
              } else if (child.isMetadata()) {
                DirectParserASTContentMetadataStarEnd decl = child.asMetadata();
                List<DirectParserASTContentMetadataEnd> metadata =
                    decl.getMetadataEntries();
                if (metadata.isNotEmpty) {
                  helper.replacements.add(new Replacement(
                      metadata.first.beginToken.offset - 1,
                      metadata.last.endToken.offset));
                  shouldCompile = true;
                }
                what = "metadata";
              }
              if (shouldCompile) {
                success = await _tryReplaceAndCompile(
                    helper, uri, initialComponent, what);
                if (helper.shouldQuit) return;
                if (!success) {
                  DirectParserASTContentBlockFunctionBodyEnd decl;
                  if (child is DirectParserASTContentMemberEnd) {
                    if (child.isClassMethod()) {
                      decl = child.getClassMethod().getBlockFunctionBody();
                    } else if (child.isClassConstructor()) {
                      decl = child.getClassConstructor().getBlockFunctionBody();
                    }
                  }
                  if (decl != null &&
                      decl.beginToken.offset + 2 < decl.endToken.offset) {
                    helper.replacements.add(new Replacement(
                        decl.beginToken.offset, decl.endToken.offset));
                    what = "class member content";
                    await _tryReplaceAndCompile(
                        helper, uri, initialComponent, what);
                    if (helper.shouldQuit) return;
                  }
                }
              }
            }
          }

          // Try to remove "extends", "implements" etc.
          if (decl.getClassExtends().extendsKeyword != null) {
            helper.replacements.add(new Replacement(
                decl.getClassExtends().extendsKeyword.offset - 1,
                body.beginToken.offset));
            what = "class extends";
            success = await _tryReplaceAndCompile(
                helper, uri, initialComponent, what);
            if (helper.shouldQuit) return;
          }
          if (decl.getClassImplements().implementsKeyword != null) {
            helper.replacements.add(new Replacement(
                decl.getClassImplements().implementsKeyword.offset - 1,
                body.beginToken.offset));
            what = "class implements";
            success = await _tryReplaceAndCompile(
                helper, uri, initialComponent, what);
            if (helper.shouldQuit) return;
          }
          if (decl.getClassWithClause() != null) {
            helper.replacements.add(new Replacement(
                decl.getClassWithClause().withKeyword.offset - 1,
                body.beginToken.offset));
            what = "class with clause";
            success = await _tryReplaceAndCompile(
                helper, uri, initialComponent, what);
            if (helper.shouldQuit) return;
          }
        }
      }
    }
  }
}

class CompilationHelperClass {
  int compileTry = 0;
  bool shouldQuit = false;
  List<Replacement> replacements = [];
  Uint8List latestCrashData;
  final Uint8List originalData;

  CompilationHelperClass(this.originalData) : latestCrashData = originalData;
}

Future<bool> _tryReplaceAndCompile(CompilationHelperClass data, Uri uri,
    Component initialComponent, String what) async {
  if (await shouldQuit()) {
    data.shouldQuit = true;
    return false;
  }
  stdout.write(".");
  data.compileTry++;
  if (data.compileTry % 50 == 0) {
    stdout.write("(at ${data.compileTry})\n");
  }
  Uint8List candidate = _replaceRange(data.replacements, data.originalData);

  fs.data[uri] = candidate;
  if (await crashesOnCompile(initialComponent)) {
    print("Found $what from "
        "${data.replacements.last.from} to "
        "${data.replacements.last.to} "
        "that can be removed.");
    data.latestCrashData = candidate;
    return true;
  } else {
    // Couldn't delete that.
    data.replacements.removeLast();
    fs.data[uri] = data.latestCrashData;
    return false;
  }
}

class Replacement implements Comparable<Replacement> {
  final int from;
  final int to;
  final Uint8List nullOrReplacement;

  Replacement(this.from, this.to, {this.nullOrReplacement});

  @override
  int compareTo(Replacement other) {
    return from - other.from;
  }
}

Uint8List _replaceRange(
    List<Replacement> unsortedReplacements, Uint8List data) {
  // The below assumes these are sorted.
  List<Replacement> sortedReplacements =
      new List<Replacement>.from(unsortedReplacements)..sort();
  final BytesBuilder builder = new BytesBuilder();
  int prev = 0;
  for (int i = 0; i < sortedReplacements.length; i++) {
    Replacement replacement = sortedReplacements[i];
    for (int j = prev; j <= replacement.from; j++) {
      builder.addByte(data[j]);
    }
    if (replacement.nullOrReplacement != null) {
      builder.add(replacement.nullOrReplacement);
    }
    prev = replacement.to;
  }
  for (int j = prev; j < data.length; j++) {
    builder.addByte(data[j]);
  }
  Uint8List candidate = builder.takeBytes();
  return candidate;
}

const int $LF = 10;

void deleteEmptyLines(Uri uri, Component initialComponent) async {
  Uint8List data = fs.data[uri];
  List<Uint8List> lines = [];
  int start = 0;
  for (int i = 0; i < data.length; i++) {
    if (data[i] == $LF) {
      if (i - start > 0) {
        lines.add(sublist(data, start, i));
      }
      start = i + 1;
    }
  }
  if (data.length - start > 0) {
    lines.add(sublist(data, start, data.length));
  }

  final BytesBuilder builder = new BytesBuilder();
  for (int j = 0; j < lines.length; j++) {
    if (builder.isNotEmpty) {
      builder.addByte($LF);
    }
    builder.add(lines[j]);
  }
  Uint8List candidate = builder.takeBytes();
  if (candidate.length == data.length) return;

  if (await shouldQuit()) return;
  fs.data[uri] = candidate;
  if (!await crashesOnCompile(initialComponent)) {
    // For some reason the empty lines are important.
    fs.data[uri] = data;
  } else {
    print("\nDeleted empty lines.");
  }
}

void deleteLines(Uri uri, Component initialComponent) async {
  // Try to delete "lines".
  Uint8List data = fs.data[uri];
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
    if (await shouldQuit()) break;
    if (skip) {
      skip = false;
      break;
    }
    stdout.write(".");
    if (i % 50 == 0) {
      stdout.write("(at $i of ${lines.length})\n");
    }
    if (i + length > lines.length) {
      length = lines.length - i;
    }
    for (int j = i; j < i + length; j++) {
      include[j] = false;
    }
    final BytesBuilder builder = new BytesBuilder();
    for (int j = 0; j < lines.length; j++) {
      if (include[j]) {
        if (builder.isNotEmpty) {
          builder.addByte($LF);
        }
        builder.add(lines[j]);
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
      print("\nCan delete line $i (inclusive) - ${i + length} (exclusive) "
          "(of ${lines.length})");
      latestCrashData = candidate;
      i += length;
      length *= 2;
    }
  }
  fs.data[uri] = latestCrashData;
}

Component _latestComponent;
IncrementalCompiler _latestIncrementalCompiler;

Future<bool> crashesOnCompile(Component initialComponent) async {
  IncrementalCompiler incrementalCompiler;
  if (noPlatform) {
    incrementalCompiler = new IncrementalCompiler(setupCompilerContext());
  } else {
    incrementalCompiler = new IncrementalCompiler.fromComponent(
        setupCompilerContext(), initialComponent);
  }
  _latestIncrementalCompiler = incrementalCompiler;
  incrementalCompiler.invalidate(mainUri);
  try {
    _latestComponent = await incrementalCompiler.computeDelta();
    if (serialize) {
      ByteSink sink = new ByteSink();
      BinaryPrinter printer = new BinaryPrinter(sink);
      printer.writeComponentFile(_latestComponent);
      sink.builder.takeBytes();
    }
    for (Uri uri in invalidate) {
      incrementalCompiler.invalidate(uri);
      Component delta = await incrementalCompiler.computeDelta();
      if (serialize) {
        ByteSink sink = new ByteSink();
        BinaryPrinter printer = new BinaryPrinter(sink);
        printer.writeComponentFile(delta);
        sink.builder.takeBytes();
      }
    }
    _latestComponent = null; // if it didn't crash this isn't relevant.
    return false;
  } catch (e, st) {
    // Find line with #0 in it.
    String eWithSt = "$e\n\n$st";
    List<String> lines = eWithSt.split("\n");
    String foundLine = "";
    int lookFor = 0;
    for (String line in lines) {
      if (line.startsWith("#$lookFor")) {
        foundLine += line;
        lookFor++;
        if (lookFor >= stackTraceMatches) {
          break;
        } else {
          foundLine += "\n";
        }
      }
    }
    if (foundLine == null) throw "Unexpected crash without stacktrace: $e";
    if (expectedCrashLine == null) {
      print("Got '$foundLine'");
      expectedCrashLine = foundLine;
      return true;
    } else if (foundLine == expectedCrashLine) {
      return true;
    } else {
      if (askAboutRedirectCrashTarget &&
          !askedAboutRedirect.contains(foundLine)) {
        print("Crashed, but another place: $foundLine");
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

  if (nnbd) {
    options.explicitExperimentalFlags = {ExperimentalFlag.nonNullable: true};
  }
  if (experimentalInvalidation) {
    options.explicitExperimentalFlags ??= {};
    options.explicitExperimentalFlags[
        ExperimentalFlag.alternativeInvalidationStrategy] = true;
  }

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
  List<int> lineStarts = <int>[];

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
  bool _initialized = false;
  final Map<Uri, Uint8List> data = {};

  @override
  FileSystemEntity entityForUri(Uri uri) {
    return new FakeFileSystemEntity(this, uri);
  }

  initializeFromJson(Map<String, dynamic> json) {
    _initialized = true;
    _redirectAndRecord = json['_redirectAndRecord'];
    data.clear();
    List tmp = json['data'];
    for (int i = 0; i < tmp.length; i += 2) {
      Uri key = tmp[i] == null ? null : Uri.parse(tmp[i]);
      if (tmp[i + 1] == null) {
        data[key] = null;
      } else if (tmp[i + 1] is String) {
        data[key] = utf8.encode(tmp[i + 1]);
      } else {
        data[key] = Uint8List.fromList(new List<int>.from(tmp[i + 1]));
      }
    }
  }

  Map<String, dynamic> toJson() {
    List tmp = [];
    for (var entry in data.entries) {
      if (entry.value == null) continue;
      tmp.add(entry.key == null ? null : entry.key.toString());
      dynamic out = entry.value;
      if (entry.value != null && entry.value.isNotEmpty) {
        try {
          String string = utf8.decode(entry.value);
          out = string;
        } catch (e) {
          // not a string...
        }
      }
      tmp.add(out);
    }
    return {
      '_redirectAndRecord': _redirectAndRecord,
      'data': tmp,
    };
  }
}

class FakeFileSystemEntity extends FileSystemEntity {
  final FakeFileSystem fs;
  final Uri uri;
  FakeFileSystemEntity(this.fs, this.uri);

  void _ensureCachedIfOk() {
    if (fs.data.containsKey(uri)) return;
    if (fs._initialized) return;
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

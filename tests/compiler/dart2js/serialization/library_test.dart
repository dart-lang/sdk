// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_library_test;

import 'dart:async';
import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:expect/expect.dart';
import '../equivalence/check_functions.dart';
import '../memory_compiler.dart';
import 'equivalence_test.dart';
import 'helper.dart';

main(List<String> arguments) {
  // Ensure that we can print out constant expressions.
  DEBUG_MODE = true;

  Uri entryPoint;
  String outPath;
  int shardCount = 3;
  bool prettyPrint = false;
  for (String arg in arguments) {
    if (arg.startsWith('--')) {
      if (arg.startsWith('--out=')) {
        outPath = arg.substring('--out='.length);
      } else if (arg == '--pretty-print') {
        prettyPrint = true;
      } else if (arg.startsWith('--shards=')) {
        shardCount = int.parse(arg.substring('--shards='.length));
      } else {
        print("Unknown option $arg");
      }
    } else {
      if (entryPoint != null) {
        print("Multiple entrypoints are not supported.");
      }
      entryPoint = Uri.parse(arg);
    }
  }
  if (entryPoint == null) {
    entryPoint = Uris.dart_core;
  }
  asyncTest(() async {
    Compiler compiler =
        await compilerFor(entryPoint: entryPoint, options: [Flags.analyzeAll]);
    compiler.serialization.supportSerialization = true;
    await compiler.run(entryPoint);
    List<SerializedData> data = createData(compiler,
        outPath: outPath, prettyPrint: prettyPrint, shardCount: shardCount);
    await testAnalysis(compiler, data, entryPoint);
  });
}

List<SerializedData> createData(Compiler compiler,
    {String outPath, bool prettyPrint, int shardCount: 3}) {
  Iterable<LibraryElement> libraries1 = compiler.libraryLoader.libraries;
  if (shardCount < 1 || shardCount > libraries1.length) {
    shardCount = libraries1.length;
  }
  List<List<LibraryElement>> librarySplits = <List<LibraryElement>>[];
  int offset = 0;
  int shardSize = (libraries1.length / shardCount).ceil();
  for (int shard = 0; shard < shardCount; shard++) {
    List<LibraryElement> libraries = <LibraryElement>[];
    for (int index = 0; index < shardSize; index++) {
      if (offset + index < libraries1.length) {
        libraries.add(libraries1.elementAt(offset + index));
      }
    }
    librarySplits.add(libraries);
    offset += shardSize;
  }
  print(librarySplits.join('\n'));
  List<SerializedData> data = <SerializedData>[];
  for (int shard = 0; shard < shardCount; shard++) {
    List<LibraryElement> libraries = librarySplits[shard];
    Serializer serializer = compiler.serialization.createSerializer(libraries);
    String text = serializer.toText(const JsonSerializationEncoder());
    String outText = text;
    if (prettyPrint) {
      outText = serializer.prettyPrint();
    }
    if (outPath != null) {
      String name = outPath;
      String ext = '';
      int dotPos = outPath.lastIndexOf('.');
      if (dotPos != -1) {
        name = outPath.substring(0, dotPos);
        ext = outPath.substring(dotPos);
      }
      new File('$name$shard$ext').writeAsStringSync(outText);
    } else if (prettyPrint) {
      print(outText);
    }
    data.add(new SerializedData(Uri.parse('memory:out$shard.data'), text));
  }
  return data;
}

Future testAnalysis(
    Compiler compiler1, List<SerializedData> data, Uri entryPoint) async {
  Map<String, String> memorySourceFiles = <String, String>{};
  List<Uri> resolutionInputs = <Uri>[];
  for (int index = 0; index < data.length; index++) {
    SerializedData serializedData = data[index];
    serializedData.expandMemorySourceFiles(memorySourceFiles);
    serializedData.expandUris(resolutionInputs);
  }
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      resolutionInputs: resolutionInputs,
      options: [Flags.analyzeAll]);
  Compiler compiler2 = result.compiler;
  for (LibraryElement library1 in compiler1.libraryLoader.libraries) {
    LibraryElement library2 =
        compiler2.libraryLoader.lookupLibrary(library1.canonicalUri);
    if (library2 == null) {
      throw new ArgumentError('No library ${library1.canonicalUri} found.');
    }
    checkLibraryContent('library1', 'library2', 'library', library1, library2);
    checkAllResolvedAsts(compiler1, compiler2);
    checkAllImpacts(compiler1, compiler2);
  }
  Expect.isFalse(compiler2.reporter.hasReportedError, "Unexpected errors");
}

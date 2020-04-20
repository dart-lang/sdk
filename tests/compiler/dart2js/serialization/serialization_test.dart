// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/serialization/strategies.dart';
import 'package:expect/expect.dart';
import 'serialization_test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    Directory libDir = new Directory.fromUri(Platform.script.resolve('libs'));
    await checkTests(dataDir, options: [], args: args, libDirectory: libDir);
  });
}

Future checkTests(Directory dataDir,
    {List<String> options: const <String>[],
    List<String> args: const <String>[],
    Directory libDirectory: null,
    bool forUserLibrariesOnly: true,
    int shards: 1,
    int shardIndex: 0,
    void onTest(Uri uri)}) async {
  args = args.toList();
  bool shouldContinue = args.remove('-c');
  bool continued = false;
  bool hasFailures = false;
  SerializationStrategy strategy = const BytesInMemorySerializationStrategy();
  if (args.remove('-d')) {
    strategy = const ObjectsInMemorySerializationStrategy();
  }

  var relativeDir = dataDir.uri.path.replaceAll(Uri.base.path, '');
  print('Data dir: ${relativeDir}');
  List<FileSystemEntity> entities = dataDir.listSync();
  if (shards > 1) {
    int start = entities.length * shardIndex ~/ shards;
    int end = entities.length * (shardIndex + 1) ~/ shards;
    entities = entities.sublist(start, end);
  }
  int testCount = 0;
  for (FileSystemEntity entity in entities) {
    String name = entity.uri.pathSegments.last;
    if (args.isNotEmpty && !args.contains(name) && !continued) continue;
    if (shouldContinue) continued = true;
    testCount++;
    List<String> testOptions = options.toList();
    testOptions.add(Flags.dumpInfo);
    testOptions.add('--out=out.js');
    if (onTest != null) {
      onTest(entity.uri);
    }
    print('----------------------------------------------------------------');
    print('Test file: ${entity.uri}');
    // Pretend this is a dart2js_native test to allow use of 'native' keyword
    // and import of private libraries.
    String commonTestPath = 'sdk/tests/compiler';
    Uri entryPoint =
        Uri.parse('memory:$commonTestPath/dart2js_native/main.dart');
    String mainCode = await new File.fromUri(entity.uri).readAsString();
    Map<String, String> memorySourceFiles = {entryPoint.path: mainCode};

    if (libDirectory != null) {
      print('Supporting libraries:');
      String filePrefix = name.substring(0, name.lastIndexOf('.'));
      await for (FileSystemEntity libEntity in libDirectory.list()) {
        String libFileName = libEntity.uri.pathSegments.last;
        if (libFileName.startsWith(filePrefix)) {
          print('    - libs/$libFileName');
          Uri libFileUri =
              Uri.parse('memory:$commonTestPath/libs/$libFileName');
          String libCode = await new File.fromUri(libEntity.uri).readAsString();
          memorySourceFiles[libFileUri.path] = libCode;
        }
      }
    }

    await runTest(
        entryPoint: entryPoint,
        memorySourceFiles: memorySourceFiles,
        options: testOptions,
        strategy: strategy);
  }
  Expect.isFalse(hasFailures, 'Errors found.');
  Expect.isTrue(testCount > 0, "No files were tested.");
}

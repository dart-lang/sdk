// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "vm_service_heap_helper.dart" as helper;

Future<void> main(List<String> args) async {
  List<helper.Interest> interests = <helper.Interest>[];
  interests.add(new helper.Interest(
    Uri.parse("package:front_end/src/source/source_library_builder.dart"),
    "SourceLibraryBuilder",
    ["fileUri"],
  ));
  interests.add(new helper.Interest(
    Uri.parse("package:front_end/src/source/source_extension_builder.dart"),
    "SourceExtensionBuilder",
    ["extension"],
  ));
  interests.add(new helper.Interest(
    Uri.parse("package:kernel/ast.dart"),
    "Library",
    ["fileUri"],
  ));
  interests.add(new helper.Interest(
    Uri.parse("package:kernel/ast.dart"),
    "Extension",
    ["name", "fileUri"],
  ));

  helper.VMServiceHeapHelperSpecificExactLeakFinder createNewLeakFinder() =>
      new helper.VMServiceHeapHelperSpecificExactLeakFinder(
        interests: interests,
        prettyPrints: [
          new helper.Interest(
            Uri.parse("package:kernel/ast.dart"),
            "Library",
            ["fileUri", "libraryIdForTesting"],
          ),
        ],
        throwOnPossibleLeak: true,
      );

  helper.VMServiceHeapHelperSpecificExactLeakFinder heapHelper =
      createNewLeakFinder();

  if (args.length > 0 && args[0] == "--dart2js") {
    await heapHelper.start([
      "--enable-asserts",
      Platform.script.resolve("incremental_dart2js_tester.dart").toString(),
      "--addDebugBreaks",
      "--fast",
      "--experimental",
    ]);
  } else if (args.length > 0 && args[0] == "--weekly") {
    await heapHelper.start([
      "--enable-asserts",
      Platform.script.resolve("incremental_suite.dart").toString(),
      "-DaddDebugBreaks=true",
      // "import_package_by_file_uri" by design imports the same file in two
      // different ways, thus getting two copies of the same library.
      // "issue_49968" gets "by design" the same library twice because of
      // mixups with import urls and file urls.
      "-DskipTests=import_package_by_file_uri,issue_49968"
    ]);
  } else if (args.length > 0 && args[0].startsWith("--connect=")) {
    // Connect to already running process.
    String uriString = args[0].substring("--connect=".length);
    Uri uri = Uri.parse(uriString);
    while (true) {
      try {
        heapHelper.timeout = 30;
        heapHelper.verbose = true;
        await heapHelper.startWithoutRunning(uri);
      } catch (e) {
        print("Got $e...");
        if ("$e".contains("Leaks found")) {
          rethrow;
        }
        print("Will retry in a few seconds.");
        heapHelper = createNewLeakFinder();
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  } else if (args.length > 0 && args[0] == "--dart-leak-test") {
    // Connect to already running process via file specifying uri.
    while (true) {
      try {
        final String uriString = new File.fromUri(
                Directory.systemTemp.uri.resolve('./dart_leak_test_uri'))
            .readAsStringSync();
        final Uri uri = Uri.parse(uriString);
        heapHelper.timeout = 30;
        heapHelper.verbose = true;
        await heapHelper.startWithoutRunning(uri);
      } catch (e) {
        print("Got $e...");
        if ("$e".contains("Leaks found")) {
          rethrow;
        }
        print("Will retry in a few seconds.");
        heapHelper = createNewLeakFinder();
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  } else {
    await heapHelper.start([
      "--enable-asserts",
      Platform.script.resolve("incremental_suite.dart").toString(),
      "-DaddDebugBreaks=true",
      "--",
      "incremental/no_outline_change_38",
    ]);
  }
}

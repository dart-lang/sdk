// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "vm_service_heap_helper.dart" as helper;

Future<void> main(List<String> args) async {
  List<helper.Interest> interests = <helper.Interest>[];
  interests.add(new helper.Interest(
    Uri.parse("package:front_end/src/fasta/source/source_library_builder.dart"),
    "SourceLibraryBuilder",
    ["fileUri"],
  ));
  interests.add(new helper.Interest(
    Uri.parse(
        "package:front_end/src/fasta/source/source_extension_builder.dart"),
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
  helper.VMServiceHeapHelperSpecificExactLeakFinder heapHelper =
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
    ]);
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

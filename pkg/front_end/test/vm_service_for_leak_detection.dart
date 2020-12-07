import 'dart:io';

import "vm_service_heap_helper.dart" as helper;

main(List<String> args) async {
  List<helper.Interest> interests = <helper.Interest>[];
  interests.add(new helper.Interest(
      Uri.parse(
          "package:front_end/src/fasta/source/source_library_builder.dart"),
      "SourceLibraryBuilder",
      ["fileUri"]));
  interests.add(new helper.Interest(
      Uri.parse(
          "package:front_end/src/fasta/source/source_extension_builder.dart"),
      "SourceExtensionBuilder",
      ["_extension"]));
  interests.add(new helper.Interest(
      Uri.parse("package:kernel/ast.dart"), "Library", ["fileUri"]));
  helper.VMServiceHeapHelperSpecificExactLeakFinder heapHelper =
      new helper.VMServiceHeapHelperSpecificExactLeakFinder(
          interests,
          [
            new helper.Interest(
                Uri.parse(
                    "package:front_end/src/fasta/source/source_extension_builder.dart"),
                "SourceExtensionBuilder",
                ["_extension"]),
            new helper.Interest(Uri.parse("package:kernel/ast.dart"),
                "Extension", ["name", "fileUri"]),
            new helper.Interest(Uri.parse("package:kernel/ast.dart"), "Library",
                ["fileUri", "_libraryIdString"]),
          ],
          true,
          true);

  if (args.length > 0 && args[0] == "--dart2js") {
    heapHelper.start([
      "--enable-asserts",
      Platform.script.resolve("incremental_dart2js_tester.dart").toString(),
      "--addDebugBreaks",
      "--fast",
      "--experimental",
    ]);
  } else {
    heapHelper.start([
      "--enable-asserts",
      Platform.script
          .resolve("incremental_load_from_dill_suite.dart")
          .toString(),
      "-DaddDebugBreaks=true",
      "--",
      "incremental_load_from_dill/no_outline_change_38",
    ]);
  }
}

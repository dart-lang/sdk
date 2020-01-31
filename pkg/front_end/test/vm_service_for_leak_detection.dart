import 'dart:io';

import "vm_service_heap_helper.dart" as helper;

main(List<String> args) async {
  List<helper.Interest> interests = new List<helper.Interest>();
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
  helper.VMServiceHeapHelper heapHelper = new helper.VMServiceHeapHelper(
      interests,
      [
        new helper.Interest(
            Uri.parse(
                "package:front_end/src/fasta/source/source_extension_builder.dart"),
            "SourceExtensionBuilder",
            ["_extension"]),
        new helper.Interest(Uri.parse("package:kernel/ast.dart"), "Extension",
            ["name", "fileUri"]),
      ],
      true);
  heapHelper.start([
    Platform.script.resolve("incremental_dart2js_tester.dart").toString(),
    "--fast",
    "--addDebugBreaks",
  ]);
}

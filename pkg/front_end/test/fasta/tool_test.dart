// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests the tool `pkg/front_end/tool/fasta`.

import "dart:convert";

import "dart:io";

import "package:expect/expect.dart";

import "package:front_end/src/fasta/fasta_codes.dart"
    show messageFastaUsageShort;

const String toolPath = "pkg/front_end/tool/fasta";

const List<String> subtools = const <String>[
  "abcompile",
  "analyzer-compile",
  "compile",
  "compile-platform",
  "log",
  "logd",
  "outline",
  "parser",
  "run",
  "scanner",
  "dump-partial",
  "dump-ir",
  "kernel-service",
  "testing",
  "generate-messages",
];

/// An unsafe tool is a tool that shouldn't be run during this test. Please
/// document below why the tool shouldn't be run, and how it is tested.
const List<String> unsafeTools = const <String>[
  // This modifies the source code in the repository, and that could cause
  // other tests to fail. This tool is tested as we invoke it everytime we edit
  // messages.yaml.
  "generate-messages",

  // This is a daemon process that never terminates. It's not currently tested
  // directly.
  "logd",

  // This would eventually run this test again, recursively, and never
  // finish. As this tool is part of the workflow for testing Fasta, we assume
  // is exercised sufficiently.
  "testing",
];

const JsonEncoder prettyJson = const JsonEncoder.withIndent("  ");

main() {
  if (!Platform.isMacOS && !Platform.isLinux) {
    // The tool is a shell script and only works on Mac and Linux.
    return;
  }
  Set<String> testedSubtools = new Set<String>.from(subtools)
      .difference(new Set<String>.from(unsafeTools));
  Map<String, Map<String, dynamic>> resultMap =
      <String, Map<String, dynamic>>{};
  for (String subtool in testedSubtools) {
    print("Testing $subtool");
    ProcessResult result =
        Process.runSync("/bin/bash", <String>[toolPath, subtool]);
    resultMap[subtool] = {
      "exitCode": result.exitCode,
      "stdout": result.stdout,
      "stderr": result.stderr,
    };
  }
  Map<String, dynamic> scanner = resultMap["scanner"];
  Expect.isTrue(scanner["stdout"].startsWith("Reading files took: "));
  scanner["stdout"] = "was checked above";

  Map<String, dynamic> kernelService = resultMap["kernel-service"];
  Expect.isTrue(kernelService["stderr"].startsWith("Usage: dart ["));
  kernelService["stderr"] = "was checked above";

  String jsonResult = prettyJson.convert(resultMap);
  String usage = messageFastaUsageShort.message;

  String jsonExpectation = prettyJson.convert({
    "abcompile": {
      "exitCode": 1,
      "stdout": """[]
Expected -DbRoot=/absolute/path/to/other/sdk/repo
""",
      "stderr": "",
    },
    "analyzer-compile": {
      "exitCode": 2,
      "stdout": "",
      "stderr": "'analyzer-compile' isn't supported anymore,"
          " please use 'compile' instead.\n",
    },
    "compile": {
      "exitCode": 1,
      "stdout": """Usage: compile [options] dartfile

Compiles a Dart program to the Dill/Kernel IR format.

$usage
Error: No Dart file specified.
""",
      "stderr": "",
    },
    "compile-platform": {
      "exitCode": 1,
      "stdout": """
Usage: compile_platform [options] patched_sdk fullOutput outlineOutput

Compiles Dart SDK platform to the Dill/Kernel IR format.

$usage
Error: Expected three arguments.
""",
      "stderr": "",
    },
    "log": {
      "exitCode": 0,
      "stdout": "",
      "stderr": "",
    },
    "outline": {
      "exitCode": 1,
      "stdout": """Usage: outline [options] dartfile

Creates an outline of a Dart program in the Dill/Kernel IR format.

$usage
Error: No Dart file specified.
""",
      "stderr": "",
    },
    "parser": {
      "exitCode": 0,
      "stdout": "",
      "stderr": "",
    },
    "run": {
      "exitCode": 2,
      "stdout": "",
      "stderr": "'run' isn't supported anymore,"
          " please use 'kernel-service' instead.\n",
    },
    "scanner": {
      "exitCode": 0,
      "stdout": "was checked above",
      "stderr": "",
    },
    "dump-partial": {
      "exitCode": 1,
      "stdout": "usage: pkg/front_end/tool/fasta dump_partial"
          " partial.dill [extra1.dill] ... [extraN.dill]\n",
      "stderr": "",
    },
    "dump-ir": {
      "exitCode": 2,
      "stdout": "",
      "stderr": "Usage: dump-ir dillfile [output]\n",
    },
    "kernel-service": {
      "exitCode": 255,
      "stdout": "",
      "stderr": "was checked above",
    },
  });
  Expect.stringEquals(jsonExpectation, jsonResult);
}

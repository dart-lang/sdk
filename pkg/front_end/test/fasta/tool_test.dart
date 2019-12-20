// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests the tool `pkg/front_end/tool/fasta`.

import "dart:io";

import "package:expect/expect.dart";

import "package:front_end/src/fasta/fasta_codes.dart"
    show messageFastaUsageShort;

const String toolPath = "pkg/front_end/tool/fasta";

const List<String> subtools = const <String>[
  "abcompile",
  "compile",
  "compile-platform",
  "log",
  "logd",
  "outline",
  "parser",
  "scanner",
  "dump-ir",
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

main() {
  if (!Platform.isMacOS && !Platform.isLinux) {
    // The tool is a shell script and only works on Mac and Linux.
    return;
  }
  Set<String> testedSubtools = new Set<String>.from(subtools)
      .difference(new Set<String>.from(unsafeTools));
  String usage = messageFastaUsageShort.message;
  Map expectations = {
    "abcompile": {
      "exitCode": 1,
      "stdout": """[]
Expected -DbRoot=/absolute/path/to/other/sdk/repo
""",
      "stderr": "",
    },
    "compile": {
      "exitCode": 1,
      "stdout": """
Usage: compile [options] dartfile

Compiles a Dart program to the Dill/Kernel IR format.

$usage
Error: No Dart file specified.
""",
      "stderr": "",
    },
    "compile-platform": {
      "exitCode": 1,
      "stdout": """
Usage: compile_platform [options] dart-library-uri libraries.json vm_outline_strong.dill platform.dill outline.dill

Compiles Dart SDK platform to the Dill/Kernel IR format.

$usage
Error: Expected five arguments.
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
      "stdout": """
Usage: outline [options] dartfile

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
    "scanner": {
      "exitCode": 0,
      "stderr": "",
    },
    "dump-ir": {
      "exitCode": 2,
      "stdout": "",
      "stderr": "Usage: dump-ir dillfile [output]\n",
    },
  };

  for (String subtool in testedSubtools) {
    print("Testing $subtool");
    ProcessResult result = Process.runSync(
        "/bin/bash", <String>[toolPath, subtool],
        environment: <String, String>{"DART_VM": Platform.resolvedExecutable});
    Map expectation = expectations.remove(subtool);
    String combinedOutput = """
stdout:
${result.stdout}
stderr:
${result.stderr}
""";
    Expect.equals(expectation["exitCode"], result.exitCode, combinedOutput);

    switch (subtool) {
      case "scanner":
        Expect.isTrue(result.stdout.startsWith("Reading files took: "));
        Expect.stringEquals(expectation["stderr"], result.stderr);
        break;

      default:
        Expect.stringEquals(expectation["stdout"], result.stdout);
        Expect.stringEquals(expectation["stderr"], result.stderr);
        break;
    }
  }
  Expect.isTrue(expectations.isEmpty);
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_command_line;

import 'dart:io' show
    exit;

import 'command_line.dart' show
    CommandLine,
    argumentError;

const Map<String, dynamic> optionSpecification = const <String, dynamic>{
  "-o": Uri,
  "--output": Uri,
  "--platform": Uri,
  "--packages": Uri,
};

class CompilerCommandLine extends CommandLine {
  final String programName;

  CompilerCommandLine(String programName, List<String> arguments)
      : programName = programName,
        super(arguments, specification: optionSpecification,
            usage: computeUsage(programName, false));

  bool get verify => options.containsKey("--verify");

  bool get dumpIr => options.containsKey("--dump-ir");

  bool get help {
    return options.containsKey("--help") ||
        options.containsKey("-h") ||
        options.containsKey("/h") ||
        options.containsKey("/?");
  }

  void validate() {
    if (help) {
      print(computeUsage(programName, verbose));
      exit(0);
    }

    if (options.containsKey("-o") && options.containsKey("--output")) {
      return argumentError(usage, "Can't specify both '-o' and '--output'.");
    }
    if (options.containsKey("--packages")) {
      return argumentError(usage, "Option '--packages' isn't supported yet.");
    }
    if (arguments.isEmpty) {
      return argumentError(usage, "No Dart file specified.");
    }
  }

  Uri get output {
    return options["-o"] ?? options["--output"] ?? defaultOutput;
  }

  Uri get defaultOutput => Uri.base.resolve("${arguments.first}.dill");

  Uri get platform {
    return options["--platform"] ?? Uri.base.resolve("platform.dill");
  }
}

String computeUsage(String programName, bool verbose) {
  String basicUsage = "Usage: $programName [options] dartfile\n";
  String summary;
  String options = (verbose ? allOptions : frequentOptions).trim();
  switch (programName) {
    case "outline":
      summary =
          "Creates an outline of a Dart program in the Dill/Kernel IR format.";
      break;

    case "compile":
      summary = "Compiles a Dart program to the Dill/Kernel IR format.";
      break;

    case "kompile":
      summary =
          "Compiles a Dart program to the Dill/Kernel IR format via dartk.";
      break;

    case "run":
      summary = "Runs a Dart program.";
      break;
  }
  StringBuffer sb = new StringBuffer(basicUsage);
  if (summary != null) {
    sb.writeln();
    sb.writeln(summary);
    sb.writeln();
  }
  sb.write(options);
  return "$sb";
}

const String frequentOptions = """
Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).
""";

const String allOptions = """
Supported options:

  -o <file>, --out=<file>
    Generate the output into <file>.

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

  --
    Stop option parsing, the rest of the command line is assumed to be
    file names or arguments to the Dart program.

  --packages=<file>
    Use package resolution configuration <file>, which should contain a mapping
    of package names to paths.

  --platform=<file>
    Read the SDK platform from <file>, which should be in Dill/Kernel IR format
    and contain the Dart SDK.

  --verify
    Check that the generated output is free of various problems. This is mostly
    useful for developers of this compiler or Kernel transformations.

  --dump-ir
    Print compiled libraries in Kernel source notation.
""";

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io';

import 'package:kernel/binary/tag.dart' show Tag;

import 'package:front_end/src/base/command_line_options.dart';

import 'package:testing/testing.dart'
    show ChainContext, Result, Step, TestDescription, Chain, runMe;

Future<Null> main([List<String> arguments = const []]) async {
  if (arguments.length == 1 && arguments[0] == "--generate") {
    print("Should now generate a dill of dart2js.");
    await generateDill();
    return null;
  } else if (arguments.length == 1 && arguments[0] == "--checkDill") {
    await checkDill();
    return null;
  }
  await runMe(arguments, createContext, configurationPath: "../testing.json");
  await checkDill();
}

String get dartVm => Platform.resolvedExecutable;

Uri generateOutputUri(int binaryVersion, int compileNumber) {
  return Uri.base.resolve("pkg/front_end/testcases/old_dills/dills/"
      "dart2js"
      ".version.$binaryVersion"
      ".compile.$compileNumber"
      ".dill");
}

verifyNotUsingCheckedInDart() {
  String vm = dartVm.replaceAll(r"\", "/");
  if (vm.contains("tools/sdks/dart-sdk/bin/dart")) {
    throw "Running with checked-in VM which is not supported";
  }
}

Future<Null> checkDill() async {
  Uri uri = generateOutputUri(Tag.BinaryFormatVersion, 1);
  if (!new File.fromUri(uri).existsSync()) {
    print("File $uri doesn't exist. Generate running script");
    print("${Platform.script.toFilePath()} --generate");
    exit(1);
  }
}

Future<Null> generateDill() async {
  Uri fastaCompile = Uri.base.resolve("pkg/front_end/tool/_fasta/compile.dart");
  if (!new File.fromUri(fastaCompile).existsSync()) {
    throw "compile.dart from fasta tools couldn't be found";
  }

  Uri dart2js = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  if (!new File.fromUri(dart2js).existsSync()) {
    throw "dart2js couldn't be found";
  }

  int compileNumber = 0;
  Uri output;
  do {
    compileNumber++;
    output = generateOutputUri(Tag.BinaryFormatVersion, compileNumber);
  } while (new File.fromUri(output).existsSync());

  ProcessResult result = await Process.run(
      dartVm,
      [
        fastaCompile.toFilePath(),
        "sdkroot:/pkg/compiler/bin/dart2js.dart",
        "${Flags.output}",
        output.toFilePath(),
        "${Flags.target}=vm",
        "${Flags.singleRootBase}=${Uri.base.toFilePath()}",
        "${Flags.singleRootScheme}=sdkroot",
      ],
      workingDirectory: Uri.base.toFilePath());
  if (result.exitCode != 0) {
    print("stdout: ${result.stdout}");
    print("stderr: ${result.stderr}");
    print("Exit code: ${result.exitCode}");
    throw "Got exit code ${result.exitCode}";
  } else {
    print("File generated.");
    print("");
    print("You should now upload via CIPD:");
    print("");
    print("cipd create -name dart/cfe/dart2js_dills "
        "-in pkg/front_end/testcases/old_dills/dills/ "
        "-install-mode copy "
        "-tag \"binary_version:${Tag.BinaryFormatVersion}\"");
    print("");
    print("And update the DEPS file to say "
        "binary_version:${Tag.BinaryFormatVersion} "
        "under /pkg/front_end/testcases/old_dills/dills");
  }
}

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context();
}

class Context extends ChainContext {
  final List<Step> steps = const <Step>[
    const RunDill(),
  ];
}

class RunDill extends Step<TestDescription, TestDescription, Context> {
  const RunDill();

  String get name => "RunDill";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    verifyNotUsingCheckedInDart();
    ProcessResult result = await Process.run(
        dartVm,
        [
          "--compile_all",
          description.uri.toFilePath(),
          "-h",
        ],
        workingDirectory: Uri.base.toFilePath());
    print("stdout: ${result.stdout}");
    print("stderr: ${result.stderr}");
    print("Exit code: ${result.exitCode}");
    if (result.exitCode != 0) {
      return fail(description, "Got exit code ${result.exitCode}");
    }
    return pass(description);
  }
}

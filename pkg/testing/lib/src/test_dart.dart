// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.test_dart;

import 'dart:convert' show json;

import 'dart:io' show Platform;

import 'suite.dart' show Suite;

/// A suite that runs test.dart.
class TestDart extends Suite {
  final String common;

  final String processes;

  final List<String> commandLines;

  TestDart(String name, this.common, this.processes, this.commandLines)
      : super(
            name,
            "test_dart",
            // This suite doesn't know what it's status file is because
            // test.dart doesn't know.
            null);

  factory TestDart.fromJsonMap(Uri base, Map json, String name, String kind) {
    String common = json["common"] ?? "";
    String processes = json["processes"] ?? "-j${Platform.numberOfProcessors}";
    List<String> commandLines = json["command-lines"] ?? <String>[];
    return new TestDart(name, common, processes, commandLines);
  }

  void writeFirstImportOn(StringSink sink) {
    sink.writeln("import 'dart:io' as io;");
    sink.writeln(
        "import 'package:testing/src/stdio_process.dart' show StdioProcess;");
  }

  void writeRunCommandOn(StringSink sink) {
    Uri dartVm;
    if (Platform.isMacOS) {
      dartVm = Uri.base.resolve("tools/sdks/mac/dart-sdk/bin/dart");
    } else if (Platform.isWindows) {
      dartVm = Uri.base.resolve("tools/sdks/win/dart-sdk/bin/dart.exe");
    } else if (Platform.isLinux) {
      dartVm = Uri.base.resolve("tools/sdks/linux/dart-sdk/bin/dart");
    } else {
      throw "Operating system not supported: ${Platform.operatingSystem}";
    }
    List<String> processedArguments = <String>[];
    processedArguments.add(Uri.base
        .resolve("tools/testing/dart/package_testing_support.dart")
        .toFilePath());
    for (String commandLine in commandLines) {
      String arguments = common;
      arguments += " $processes";
      arguments += " $commandLine";
      processedArguments.add(arguments);
    }
    String executable = json.encode(dartVm.toFilePath());
    String arguments = json.encode(processedArguments);
    sink.write("""
  {
    print('Running $arguments');
    StdioProcess process = await StdioProcess.run($executable, $arguments,
        suppressOutput: false, timeout: null);
    if (process.exitCode != 0) {
      print(process.output);
      io.exitCode = 1;
    }
  }
""");
  }

  String toString() {
    return "TestDart($name, ${json.encode(common)}, ${json.encode(processes)},"
        " ${json.encode(commandLines)})";
  }
}

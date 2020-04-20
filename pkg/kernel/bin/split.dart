#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/tool/command_line_util.dart';

void usage() {
  print("Split a dill file into separate dill files (one library per file).");
  print("Dart internal libraries are not included in the output.");
  print("");
  print("Usage: dart <script> dillFile.dill");
  print("The given argument should be an existing file");
  print("that is valid to load as a dill file.");
  exit(1);
}

main(args) async {
  CommandLineHelper.requireExactlyOneArgument(args, usage,
      requireFileExists: true);
  Component binary = CommandLineHelper.tryLoadDill(args[0]);

  int part = 1;
  for (int i = 0; i < binary.libraries.length; ++i) {
    Library lib = binary.libraries[i];
    if (lib.name?.startsWith("dart.") == true ||
        lib.name == "builtin" ||
        lib.name == "nativewrappers") continue;
    String path = args[0] + ".part${part++}.dill";
    await writeComponentToFile(binary, path, lib);
    print("Wrote $path");
  }
}

Future<Null> writeComponentToFile(
    Component component, String path, Library wantedLibrary) async {
  File output = new File(path);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer =
        new BinaryPrinter(sink, libraryFilter: (lib) => lib == wantedLibrary);
    printer.writeComponentFile(component);
  } finally {
    await sink.close();
  }
}

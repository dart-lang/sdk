#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/kernel.dart';

import 'util.dart';

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
  CommandLineHelper.requireExactlyOneArgument(true, args, usage);
  Component binary = CommandLineHelper.tryLoadDill(args[0], usage);

  int part = 1;
  binary.libraries.forEach((lib) => lib.isExternal = true);
  for (int i = 0; i < binary.libraries.length; ++i) {
    Library lib = binary.libraries[i];
    if (lib.name?.startsWith("dart.") == true ||
        lib.name == "builtin" ||
        lib.name == "nativewrappers") continue;
    lib.isExternal = false;
    String path = args[0] + ".part${part++}.dill";
    await writeComponentToFile(binary, path);
    print("Wrote $path");
    lib.isExternal = true;
  }
}

Future<Null> writeComponentToFile(Component component, String path) async {
  File output = new File(path);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer =
        new LimitedBinaryPrinter(sink, (lib) => !lib.isExternal, false);
    printer.writeComponentFile(component);
  } finally {
    await sink.close();
  }
}

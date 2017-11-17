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

main(args) async {
  Program binary = loadProgramFromBinary(args[0]);

  int part = 1;
  binary.libraries.forEach((lib) => lib.isExternal = true);
  for (int i = 0; i < binary.libraries.length; ++i) {
    Library lib = binary.libraries[i];
    if (lib.name?.startsWith("dart.") == true ||
        lib.name == "builtin" ||
        lib.name == "nativewrappers") continue;
    lib.isExternal = false;
    String path = args[0] + ".part${part++}.dill";
    await writeProgramToFile(binary, path);
    print("Wrote $path");
    lib.isExternal = true;
  }
}

Future<Null> writeProgramToFile(Program program, String path) async {
  File output = new File(path);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer =
        new LimitedBinaryPrinter(sink, (lib) => !lib.isExternal, false);
    printer.writeProgramFile(program);
  } finally {
    await sink.close();
  }
}

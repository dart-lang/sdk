// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';

class CommandLineHelper {
  static requireExactlyOneArgument(List<String> args, void Function() usage,
      {bool requireFileExists: false}) {
    if (args.length != 1) {
      print("Expected exactly 1 argument, got ${args.length}.");
      usage();
    }
    if (requireFileExists) CommandLineHelper.requireFileExists(args[0]);
  }

  static requireVariableArgumentCount(
      List<int> ok, List<String> args, void Function() usage) {
    if (!ok.contains(args.length)) {
      print("Expected the argument count to be one of ${ok}, got "
          "${args.length}.");
      usage();
    }
  }

  static requireFileExists(String file) {
    if (!new File(file).existsSync()) {
      print("File $file doesn't exist.");
      exit(1);
    }
  }

  static Component tryLoadDill(String file) {
    try {
      return loadComponentFromBinary(file);
    } catch (e) {
      print("$file can't be loaded.");
      print(e);
      exit(1);
    }
  }
}

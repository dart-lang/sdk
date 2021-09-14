#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/tool/command_line_util.dart';

void usage() {
  print("Enumerates the different node types in the provided dill file");
  print("and counts them.");
  print("");
  print("Usage: dart <script> dillFile.dill");
  print("The given argument should be an existing file");
  print("that is valid to load as a dill file.");
  exit(1);
}

void main(List<String> args) {
  CommandLineHelper.requireExactlyOneArgument(args, usage,
      requireFileExists: true);
  Component component = CommandLineHelper.tryLoadDill(args[0]);
  TypeCounter counter = new TypeCounter();
  component.accept(counter);
  counter.printStats();
}

class TypeCounter extends RecursiveVisitor {
  Map<String, int> _typeCounts = <String, int>{};

  @override
  void defaultNode(Node node) {
    String key = node.runtimeType.toString();
    _typeCounts[key] = (_typeCounts[key] ??= 0) + 1;
    super.defaultNode(node);
  }

  void printStats() {
    List<List<Object>> data = [];
    _typeCounts.forEach((type, count) {
      data.add([type, count]);
    });
    data.sort((a, b) {
      int aCount = a[1] as int;
      int bCount = b[1] as int;
      return bCount - aCount;
    });
    for (var entry in data) {
      print("${entry[0]}: ${entry[1]}");
    }
  }
}

#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:kernel/kernel.dart';
import 'util.dart';

void usage() {
  print("Enumerates the different node types in the provided dill file");
  print("and counts them.");
  print("");
  print("Usage: dart <script> dillFile.dill");
  print("The given argument should be an existing file");
  print("that is valid to load as a dill file.");
  exit(1);
}

main(List<String> args) {
  CommandLineHelper.requireExactlyOneArgument(true, args, usage);
  Component component = CommandLineHelper.tryLoadDill(args[0], usage);
  TypeCounter counter = new TypeCounter();
  component.accept(counter);
  counter.printStats();
}

class TypeCounter extends RecursiveVisitor {
  Map<String, int> _typeCounts = <String, int>{};
  defaultNode(Node node) {
    String key = node.runtimeType.toString();
    _typeCounts[key] ??= 0;
    _typeCounts[key]++;
    super.defaultNode(node);
  }

  printStats() {
    List<List<Object>> data = [];
    _typeCounts.forEach((type, count) {
      data.add([type, count]);
    });
    data.sort((a, b) {
      int aCount = a[1];
      int bCount = b[1];
      return bCount - aCount;
    });
    for (var entry in data) {
      print("${entry[0]}: ${entry[1]}");
    }
  }
}

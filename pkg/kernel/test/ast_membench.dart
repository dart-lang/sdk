#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'dart:io';

/// Builds N copies of the AST for the given component.
/// Pass --print-metrics to the Dart VM to measure the memory use.
main(List<String> args) {
  if (args.length == 0) {
    print('USAGE: ast_membench FILE.dill NUM_COPIES');
    exit(1);
  }
  String filename = args[0];

  const int defaultCopyCount = 10;
  int copyCount = args.length == 2 ? int.parse(args[1]) : defaultCopyCount;
  List<Component> keepAlive = <Component>[];
  for (int i = 0; i < copyCount; ++i) {
    keepAlive.add(loadComponentFromBinary(filename));
  }

  print('$copyCount copies built');

  if (args.contains('-v')) {
    // Use of the list for something to avoid premature GC.
    int size = 0;
    for (var component in keepAlive) {
      size += component.libraries.length;
    }
    print(size);
  }
}

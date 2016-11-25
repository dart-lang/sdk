#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.treeshaker_membench;

import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/treeshaker.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:args/args.dart';
import 'dart:io';

ArgParser argParser = new ArgParser()
  ..addOption('count', abbr: 'c',
      help: 'Build N copies of the tree shaker',
      defaultsTo: '100');

String usage = """
Usage: treeshaker_membench [options] FILE.dart

Options:
${argParser.usage}
""";

/// Builds N copies of the tree shaker data structure for the given program.
/// Pass --print-metrics to the Dart VM to measure the memory use.
main(List<String> args) {
  if (args.length == 0) {
    print(usage);
    exit(1);
  }
  ArgResults options = argParser.parse(args);
  if (options.rest.length != 1) {
    print('Exactly one file should be given');
    exit(1);
  }
  String filename = options.rest.single;

  Program program = loadProgramFromBinary(filename);
  ClassHierarchy hierarchy = new ClassHierarchy(program);
  CoreTypes coreTypes = new CoreTypes(program);

  int copyCount = int.parse(options['count']);

  TreeShaker buildTreeShaker() {
    return new TreeShaker(program, hierarchy: hierarchy, coreTypes: coreTypes);
  }

  List<TreeShaker> keepAlive = <TreeShaker>[];
  for (int i = 0; i < copyCount; ++i) {
    keepAlive.add(buildTreeShaker());
  }

  print('$copyCount copies built');

  if (args.contains('-v')) {
    // Use of the list for something to avoid premature GC.
    for (var treeShaker in keepAlive) {
      treeShaker.getClassRetention(hierarchy.rootClass);
    }
  }
}

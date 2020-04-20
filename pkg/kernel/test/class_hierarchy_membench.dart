#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:args/args.dart';
import 'class_hierarchy_basic.dart';
import 'dart:io';

ArgParser argParser = new ArgParser()
  ..addFlag('basic', help: 'Measure the basic implementation', negatable: false)
  ..addOption('count',
      abbr: 'c',
      help: 'Build N copies of the class hierarchy',
      defaultsTo: '300');

String usage = """
Usage: class_hierarchy_membench [options] FILE.dill

Options:
${argParser.usage}
""";

/// Builds N copies of the class hierarchy for the given component.
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

  Component component = loadComponentFromBinary(filename);
  CoreTypes coreTypes = new CoreTypes(component);

  int copyCount = int.parse(options['count']);

  ClassHierarchy buildHierarchy() {
    return options['basic']
        ? new BasicClassHierarchy(component)
        : new ClassHierarchy(component, coreTypes);
  }

  List<ClosedWorldClassHierarchy> keepAlive = <ClosedWorldClassHierarchy>[];
  for (int i = 0; i < copyCount; ++i) {
    keepAlive.add(buildHierarchy());
  }

  print('$copyCount copies built');

  if (args.contains('-v')) {
    // Use of the list for something to avoid premature GC.
    int size = 0;
    for (var classHierarchy in keepAlive) {
      size += classHierarchy.getSuperTypeHashTableSize();
    }
    print(size);
  }
}

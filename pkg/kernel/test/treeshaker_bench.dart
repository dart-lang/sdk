// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.treeshaker_bench;

import 'dart:io';

import 'package:args/args.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/treeshaker.dart';

import 'class_hierarchy_basic.dart';

ArgParser argParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('basic',
      help: 'Use the basic class hierarchy implementation', negatable: false)
  ..addFlag('from-scratch',
      help: 'Rebuild class hierarchy for each tree shaking', negatable: false)
  ..addFlag('diagnose',
      abbr: 'd', help: 'Print internal diagnostics', negatable: false)
  ..addFlag('strong',
      help: 'Run the tree shaker in strong mode', negatable: false);

String usage = '''
Usage: treeshaker_bench [options] FILE.dill

Benchmark the tree shaker and the class hierarchy it depends on.

Options:
${argParser.usage}
''';

void main(List<String> args) {
  if (args.length == 0) {
    print(usage);
    exit(1);
  }
  ArgResults options = argParser.parse(args);
  if (options.rest.length != 1) {
    print('Exactly one file must be given');
    exit(1);
  }
  String filename = options.rest.single;
  bool strongMode = options['strong'];

  Program program = loadProgramFromBinary(filename);

  ClassHierarchy buildClassHierarchy() {
    return options['basic']
        ? new BasicClassHierarchy(program)
        : new ClosedWorldClassHierarchy(program);
  }

  CoreTypes coreTypes = new CoreTypes(program);

  var watch = new Stopwatch()..start();
  ClassHierarchy sharedClassHierarchy = buildClassHierarchy();
  int coldHierarchyTime = watch.elapsedMicroseconds;
  var shaker = new TreeShaker(coreTypes, sharedClassHierarchy, program,
      strongMode: strongMode);
  if (options['diagnose']) {
    print(shaker.getDiagnosticString());
  }
  shaker = null;
  int coldTreeShakingTime = watch.elapsedMicroseconds;

  ClassHierarchy getClassHierarchy() {
    return options['from-scratch']
        ? buildClassHierarchy()
        : sharedClassHierarchy;
  }

  const int numberOfTrials = 50;
  int hotHierarchyTime = 0;
  int hotTreeShakingTime = 0;
  watch.reset();
  for (int i = 0; i < numberOfTrials; i++) {
    watch.reset();
    var hierarchy = getClassHierarchy();
    hotHierarchyTime += watch.elapsedMicroseconds;
    new TreeShaker(coreTypes, hierarchy, program, strongMode: strongMode);
    hotTreeShakingTime += watch.elapsedMicroseconds;
  }
  hotHierarchyTime ~/= numberOfTrials;
  hotTreeShakingTime ~/= numberOfTrials;

  var coldShakingMs = coldTreeShakingTime ~/ 1000;
  var coldHierarchyMs = coldHierarchyTime ~/ 1000;
  var hotShakingMs = hotTreeShakingTime ~/ 1000;
  var hotHierarchyMs = hotHierarchyTime ~/ 1000;

  print('''
build.cold $coldShakingMs ms ($coldHierarchyMs ms from hierarchy)
build.hot  $hotShakingMs ms ($hotHierarchyMs ms from hierarchy)''');
}

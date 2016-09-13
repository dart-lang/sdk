#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:args/args.dart';
import 'class_hierarchy_basic.dart';
import 'dart:math';
import 'dart:io';

ArgParser argParser = new ArgParser()
  ..addFlag('basic', help: 'Measure the basic implementation', negatable: false)
  ..addOption('cycle',
      abbr: 'c',
      help: 'Build N copies of the class hierarchy and cycle queries '
          'between them',
      defaultsTo: '1');

String usage = '''
Usage: class_hierarchy_bench [options] FILE.dart

Options:
${argParser.usage}
''';

main(List<String> args) {
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

  Program program = loadProgramFromBinary(filename);

  ClassHierarchy buildHierarchy() {
    return options['basic']
        ? new BasicClassHierarchy(program)
        : new ClassHierarchy(program);
  }

  var watch = new Stopwatch()..start();
  buildHierarchy();
  int coldBuildTime = watch.elapsedMilliseconds;
  watch.reset();
  const int numBuildTrials = 100;
  for (int i = 0; i < numBuildTrials; i++) {
    buildHierarchy();
  }
  int hotBuildTime = watch.elapsedMilliseconds ~/ numBuildTrials;

  int hierarchyCount = int.parse(options['cycle']);
  var hierarchies = <ClassHierarchy>[];
  for (int i = 0; i < hierarchyCount; i++) {
    hierarchies.add(buildHierarchy());
  }

  int currentHierarchy = 0;
  ClassHierarchy getClassHierarchy() {
    currentHierarchy = (currentHierarchy + 1) % hierarchies.length;
    return hierarchies[currentHierarchy];
  }

  Random rnd = new Random(12345);
  const int numQueryTrials = 100000;

  // Measure isSubclassOf, isSubmixtureOf, isSubtypeOf, getClassAsInstanceOf.

  // Warm-up run to ensure the JIT compiler does not favor the first query we
  // test.
  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubclassOf(firstClass, secondClass);
    classHierarchy.isSubmixtureOf(firstClass, secondClass);
    classHierarchy.isSubtypeOf(firstClass, secondClass);
    classHierarchy.getClassAsInstanceOf(firstClass, secondClass);
  }

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubclassOf(firstClass, secondClass);
  }
  int subclassQueryTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubmixtureOf(firstClass, secondClass);
  }
  int submixtureQueryTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubtypeOf(firstClass, secondClass);
  }
  int subtypeQueryTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.getClassAsInstanceOf(firstClass, secondClass);
  }
  int asInstanceOfQueryTime = watch.elapsedMicroseconds;

  // Estimate the overhead from test case generation.
  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    classHierarchy.classes[first];
    classHierarchy.classes[second];
  }
  int queryNoise = watch.elapsedMicroseconds;

  subclassQueryTime -= queryNoise;
  submixtureQueryTime -= queryNoise;
  subtypeQueryTime -= queryNoise;
  asInstanceOfQueryTime -= queryNoise;

  String subclassPerSecond = perSecond(subclassQueryTime, numQueryTrials);
  String submixturePerSecond = perSecond(submixtureQueryTime, numQueryTrials);
  String subtypePerSecond = perSecond(subtypeQueryTime, numQueryTrials);
  String asInstanceOfPerSecond =
      perSecond(asInstanceOfQueryTime, numQueryTrials);

  // Measure getDispatchTarget and getDispatchTargets.
  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    Class classNode = classHierarchy.classes[classId];
    classHierarchy.getDispatchTarget(classNode, new Name('toString'));
  }
  int dispatchToStringTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    Class classNode = classHierarchy.classes[classId];
    classHierarchy.getDispatchTarget(classNode, new Name('getFloo'));
  }
  int dispatchGenericGetTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    Class classNode = classHierarchy.classes[classId];
    for (var _ in classHierarchy.getDispatchTargets(classNode)) {}
  }
  int dispatchAllTargetsTime = watch.elapsedMicroseconds;

  // Measure getInterfaceMember and getInterfaceMembers.
  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    Class classNode = classHierarchy.classes[classId];
    classHierarchy.getInterfaceMember(classNode, new Name('toString'));
  }
  int interfaceToStringTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    Class classNode = classHierarchy.classes[classId];
    classHierarchy.getInterfaceMember(classNode, new Name('getFloo'));
  }
  int interfaceGenericGetTime = watch.elapsedMicroseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    Class classNode = classHierarchy.classes[classId];
    for (var _ in classHierarchy.getInterfaceMembers(classNode)) {}
  }
  int interfaceAllTargetsTime = watch.elapsedMicroseconds;

  // Estimate overhead from test case generation.
  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    var classHierarchy = getClassHierarchy();
    int classId = rnd.nextInt(classHierarchy.classes.length);
    classHierarchy.classes[classId];
  }
  int dispatchTargetNoise = watch.elapsedMicroseconds;

  dispatchToStringTime -= dispatchTargetNoise;
  dispatchGenericGetTime -= dispatchTargetNoise;
  dispatchAllTargetsTime -= dispatchTargetNoise;
  interfaceToStringTime -= dispatchTargetNoise;
  interfaceGenericGetTime -= dispatchTargetNoise;
  interfaceAllTargetsTime -= dispatchTargetNoise;

  String dispatchToStringPerSecond =
      perSecond(dispatchToStringTime, numQueryTrials);
  String dispatchGetPerSecond =
      perSecond(dispatchGenericGetTime, numQueryTrials);
  String dispatchAllTargetsPerSecond =
      perSecond(dispatchAllTargetsTime, numQueryTrials);

  String interfaceToStringPerSecond =
      perSecond(interfaceToStringTime, numQueryTrials);
  String interfaceGetPerSecond =
      perSecond(interfaceGenericGetTime, numQueryTrials);
  String interfaceAllTargetsPerSecond =
      perSecond(interfaceAllTargetsTime, numQueryTrials);

  watch.reset();
  var classHierarchy = getClassHierarchy();
  int numberOfOverridePairs = 0;
  for (var class_ in classHierarchy.classes) {
    classHierarchy.forEachOverridePair(class_, (member, supermember, isSetter) {
      ++numberOfOverridePairs;
    });
  }
  int overrideTime = watch.elapsedMicroseconds;

  String overridePairsPerSecond =
      perSecond(overrideTime, numberOfOverridePairs);

  List<int> depth = new List(classHierarchy.classes.length);
  for (int i = 0; i < depth.length; ++i) {
    int parentDepth = 0;
    var classNode = classHierarchy.classes[i];
    for (var supertype in classNode.supers) {
      var superclass = supertype.classNode;
      int index = classHierarchy.getClassIndex(superclass);
      if (!(index < i)) {
        throw '${classNode.name}($i) extends ${superclass.name}($index)';
      }
      assert(index < i);
      parentDepth = max(parentDepth, depth[index]);
    }
    depth[i] = parentDepth + 1;
  }
  List<int> depthHistogram = getHistogramOf(depth);
  double averageDepth = average(depth);
  double medianDepth = median(depth);
  int totalDepth = sum(depth);

  int numberOfClasses = classHierarchy.classes.length;
  String expenseHistogram =
      classHierarchy.getExpenseHistogram().skip(1).join(' ');

  print('''
classes: $numberOfClasses
build.cold: $coldBuildTime ms
build.hot:  $hotBuildTime ms
query.isSubclassOf:                 $subclassPerSecond
query.isSubmixtureOf:               $submixturePerSecond
query.isSubtypeOf:                  $subtypePerSecond
query.getClassAsInstanceOf:         $asInstanceOfPerSecond
query.getDispatchTarget(toString):  $dispatchToStringPerSecond
query.getDispatchTarget(getFloo):   $dispatchGetPerSecond
query.getDispatchTargets.iterate:   $dispatchAllTargetsPerSecond
query.getInterfaceMember(toString): $interfaceToStringPerSecond
query.getInterfaceMember(getFloo):  $interfaceGetPerSecond
query.getInterfaceMembers.iterate:  $interfaceAllTargetsPerSecond
isSubtypeOf.expense-histogram: $expenseHistogram
isSubtypeOf.compression-ratio: ${classHierarchy.getCompressionRatio()}
asInstanceOf.table-size: ${classHierarchy.getSuperTypeHashTableSize()}
depth.histogram: ${depthHistogram.skip(1).join(' ')}
depth.average: $averageDepth
depth.median:  $medianDepth
depth.total:   $totalDepth
overrides.total:   $numberOfOverridePairs
overrides.iterate: ${overrideTime ~/ 1000} ms ($overridePairsPerSecond)
''');
}

String perSecond(int microseconds, int trials) {
  double millionsPerSecond = trials / microseconds;
  return '${millionsPerSecond.toStringAsFixed(1)} M/s';
}

List<int> getHistogramOf(Iterable<int> values) {
  List<int> result = <int>[];
  for (int value in values) {
    while (result.length <= value) {
      result.add(0);
    }
    ++result[value];
  }
  return result;
}

double average(Iterable<num> values) {
  double sum = 0.0;
  int length = 0;
  for (num x in values) {
    sum += x;
    ++length;
  }
  return length == 0 ? 0.0 : sum / length;
}

double median(Iterable<num> values) {
  List<num> list = values.toList(growable: false)..sort();
  if (list.isEmpty) return 0.0;
  int mid = list.length ~/ 2;
  return list.length % 2 == 0
      ? ((list[mid] + list[mid + 1]) / 2)
      : list[mid].toDouble();
}

num sum(Iterable<num> values) {
  num result = 0;
  for (var x in values) {
    result += x;
  }
  return result;
}

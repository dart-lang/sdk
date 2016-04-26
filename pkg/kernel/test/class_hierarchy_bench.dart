#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart';
import 'dart:math';
import 'dart:io';

main(List<String> args) {
  if (args.length == 0) {
    print('USAGE: class_hierarchy_bench FILE.bart');
    exit(1);
  }
  Program program = loadProgramFromBinary(args[0]);

  var watch = new Stopwatch()..start();
  var classHierarchy = new ClassHierarchy(program);
  int coldBuildTime = watch.elapsedMilliseconds;

  watch.reset();
  const int numBuildTrials = 100;
  for (int i = 0; i < numBuildTrials; i++) {
    new ClassHierarchy(program);
  }
  int hotBuildTime = watch.elapsedMilliseconds ~/ numBuildTrials;

  Random rnd = new Random(12345);
  const int numQueryTrials = 100000; // should match 100K in output string.

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubclassOf(firstClass, secondClass);
  }
  int subclassQueryTime = watch.elapsedMilliseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubtypeOf(firstClass, secondClass);
  }
  int subtypeQueryTime = watch.elapsedMilliseconds;

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = first - rnd.nextInt(100);
    if (second < 0) {
      second = 0;
    }
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubclassOf(firstClass, secondClass);
  }
  int subclassDenseQueryTime = watch.elapsedMilliseconds;

  int asInstanceOfQueryTimeSparse = 0;
  for (int i = 0; i < numQueryTrials; i++) {
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    watch.reset();
    classHierarchy.getClassAsInstanceOf(firstClass, secondClass);
    asInstanceOfQueryTimeSparse += watch.elapsedMicroseconds;
  }
  asInstanceOfQueryTimeSparse ~/= 1000; // Convert to milliseconds

  int asInstanceOfQueryTimeDense = 0;
  for (int i = 0; i < numQueryTrials; i++) {
    int first = rnd.nextInt(classHierarchy.classes.length);
    Class firstClass = classHierarchy.classes[first];
    Class candidate = firstClass;
    Class secondClass = firstClass;
    int steps = 0;
    while (candidate != null) {
      ++steps;
      if (rnd.nextInt(steps) == 0) {
        secondClass = candidate;
      }
      candidate = candidate.superType?.classNode;
    }
    watch.reset();
    classHierarchy.getClassAsInstanceOf(firstClass, secondClass);
    asInstanceOfQueryTimeDense += watch.elapsedMicroseconds;
  }
  asInstanceOfQueryTimeDense ~/= 1000; // Convert to milliseconds

  watch.reset();
  for (int i = 0; i < numQueryTrials; i++) {
    int first = rnd.nextInt(classHierarchy.classes.length);
    int second = first - rnd.nextInt(100);
    if (second < 0) {
      second = 0;
    }
    Class firstClass = classHierarchy.classes[first];
    Class secondClass = classHierarchy.classes[second];
    classHierarchy.isSubtypeOf(firstClass, secondClass);
  }
  int subtypeDenseQueryTime = watch.elapsedMilliseconds;

  List<int> depth = new List(classHierarchy.classes.length);
  for (int i = 0; i < depth.length; ++i) {
    int parentDepth = 0;
    var classNode = classHierarchy.classes[i];
    for (var superType in classNode.supers) {
      var superClass = superType.classNode;
      int index = classHierarchy.indexOf(superClass);
      if (!(index < i)) {
        throw '${classNode.name}($i) extends ${superClass.name}($index)';
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

  print('''
classes: $numberOfClasses
build.cold: $coldBuildTime ms
build.hot: $hotBuildTime ms
isSubclassOf.random: $subclassQueryTime ms (per 100K)
isSubclassOf.dense: $subclassDenseQueryTime ms
isSubtypeOf.random: $subtypeQueryTime ms
isSubtypeOf.dense: $subtypeDenseQueryTime ms
asInstanceOf.sparse: $asInstanceOfQueryTimeSparse ms
asInstanceOf.dense: $asInstanceOfQueryTimeDense ms
expense-histogram: ${classHierarchy.getExpenseHistogram().join(' ')}
compression-ratio: ${classHierarchy.getCompressionRatio()}
depth-histogram: ${depthHistogram.join(' ')}
depth-average: $averageDepth
depth-median: $medianDepth
depth-total: $totalDepth
hash-table-size: ${classHierarchy.getSuperTypeHashTableSize()}
''');
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

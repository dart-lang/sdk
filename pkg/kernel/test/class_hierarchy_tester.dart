// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:test/test.dart';
import 'util.dart';
import 'dart:io';

/// Checks class hierarchy correctness by comparing every possible query
/// on a given program against a naive implementation.
main(List<String> args) {
  var options = readOptions(args);
  Program program = options.loadProgram();
  testClassHierarchyOnProgram(program, verbose: true);
}

Iterable<InterfaceType> getSuperClass(Class classNode) {
  return classNode.superType == null ? const [] : [classNode.superType];
}

Iterable<InterfaceType> getSuperClassAndMixin(Class classNode) {
  return [
    classNode.superType == null ? const [] : [classNode.superType],
    classNode.mixedInType == null ? const [] : [classNode.mixedInType]
  ].expand((x) => x);
}

Iterable<InterfaceType> getAllSupers(Class classNode) {
  return classNode.supers;
}

void testClassHierarchyOnProgram(Program program, {bool verbose: false}) {
  var watch = new Stopwatch()..start();
  ClassHierarchy classHierarchy = new ClassHierarchy(program);
  int fastTime = watch.elapsedMicroseconds;
  watch.reset();
  BasicClassHierarchy basicSubclasses =
      new BasicClassHierarchy(program, getSuperClass);
  BasicClassHierarchy basicSubmixtures =
      new BasicClassHierarchy(program, getSuperClassAndMixin);
  BasicClassHierarchy basicSubtypes =
      new BasicClassHierarchy(program, getAllSupers);
  BasicAsInstanceOf basicAsInstanceOf =
      new BasicAsInstanceOf(program);
  int slowTime = watch.elapsedMicroseconds;
  int total = classHierarchy.classes.length;
  int progress = 0;
  for (var class1 in classHierarchy.classes) {
    for (var class2 in classHierarchy.classes) {
      watch.reset();
      bool isSubclass = classHierarchy.isSubclassOf(class1, class2);
      bool isSubmixture = classHierarchy.isSubmixtureOf(class1, class2);
      bool isSubtype = classHierarchy.isSubtypeOf(class1, class2);
      var asInstance = classHierarchy.getClassAsInstanceOf(class1, class2);
      fastTime += watch.elapsedMicroseconds;
      watch.reset();
      if (isSubclass != basicSubclasses.isReachable(class1, class2)) {
        fail('isSubclassOf(${class1.name}, ${class2.name}) returned '
            '$isSubclass but should be ${!isSubclass}');
      }
      if (isSubmixture != basicSubmixtures.isReachable(class1, class2)) {
        fail('isSubmixtureOf(${class1.name}, ${class2.name}) returned '
            '$isSubclass but should be ${!isSubclass}');
      }
      if (isSubtype != basicSubtypes.isReachable(class1, class2)) {
        fail('isSubtypeOf(${class1.name}, ${class2.name}) returned '
            '$isSubtype but should be ${!isSubtype}');
      }
      if (asInstance != basicAsInstanceOf.asInstanceOf(class1, class2)) {
        fail('asInstanceOf(${class1.name}, ${class2.name}) returned '
            '$asInstance but should be ${basicAsInstanceOf.asInstanceOf(class1, class2)}');
      }
      slowTime += watch.elapsedMicroseconds;
    }
    ++progress;
    if (verbose) {
      stdout.write('\rProgress ${100 * progress ~/ total}%');
    }
  }
  if (verbose) {
    print('\rProgress 100%. Done.');
    print('Class hierarchy took ${(fastTime / 1000000).toStringAsFixed(2)} s');
    print('Checks took ${(slowTime / 1000000).toStringAsFixed(2)} s');
  }
}

typedef Iterable<InterfaceType> SuperCallback(Class node);

class BasicClassHierarchy {
  final Map<Class, Set<Class>> supers = <Class, Set<Class>>{};
  SuperCallback callback;

  BasicClassHierarchy(Program program, this.callback) {
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        build(class_);
      }
    }
  }

  void build(Class node) {
    if (supers.containsKey(node)) return;
    supers[node] = new Set<Class>()..add(node);
    for (var superType in callback(node)) {
      var superClass = superType.classNode;
      build(superClass);
      supers[node].addAll(supers[superClass]);
    }
  }

  bool isReachable(Class sub, Class superClass) {
    return supers[sub].contains(superClass);
  }
}

class BasicAsInstanceOf {
  final Map<Class, Map<Class, InterfaceType>> supers =
      <Class, Map<Class, InterfaceType>>{};

  BasicAsInstanceOf(Program program) {
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        build(class_);
      }
    }
  }

  void build(Class node) {
    if (supers.containsKey(node)) return;
    supers[node] = <Class, InterfaceType>{node: node.thisType};
    for (var superType in getAllSupers(node)) {
      var superClass = superType.classNode;
      build(superClass);
      var substitution = new Map<TypeParameter, DartType>.fromIterables(
          superClass.typeParameters, superType.typeArguments);
      supers[superClass].forEach((Class key, InterfaceType type) {
        supers[node][key] = substitute(type, substitution);
      });
    }
  }

  InterfaceType asInstanceOf(Class type, Class superType) {
    return supers[type][superType];
  }
}

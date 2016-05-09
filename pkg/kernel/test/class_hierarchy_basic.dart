// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.class_hierarchy_basic;

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/ast.dart';

/// A simple implementation of the class hierarchy interface using
/// hash tables for everything.
class BasicClassHierarchy implements ClassHierarchy {
  final Map<Class, Set<Class>> superClasses = <Class, Set<Class>>{};
  final Map<Class, Set<Class>> superMixtures = <Class, Set<Class>>{};
  final Map<Class, Set<Class>> superTypes = <Class, Set<Class>>{};
  final Map<Class, Map<Class, InterfaceType>> superTypeInstantiations =
      <Class, Map<Class, InterfaceType>>{};
  final Map<Class, Map<Name, Member>> gettersAndCalls =
      <Class, Map<Name, Member>>{};
  final Map<Class, Map<Name, Member>> setters = <Class, Map<Name, Member>>{};
  final List<Class> classes = <Class>[];
  final Map<Class, int> classIndex = <Class, int>{};

  BasicClassHierarchy(Program program) {
    for (var library in program.libraries) {
      for (var classNode in library.classes) {
        buildSuperTypeSets(classNode);
        buildSuperTypeInstantiations(classNode);
        buildDispatchTable(classNode);
      }
    }
  }

  void buildSuperTypeSets(Class node) {
    if (superClasses.containsKey(node)) return;
    superClasses[node] = new Set<Class>()..add(node);
    superMixtures[node] = new Set<Class>()..add(node);
    superTypes[node] = new Set<Class>()..add(node);
    if (node.superType != null) {
      buildSuperTypeSets(node.superType.classNode);
      superClasses[node].addAll(superClasses[node.superType.classNode]);
      superMixtures[node].addAll(superMixtures[node.superType.classNode]);
      superTypes[node].addAll(superTypes[node.superType.classNode]);
    }
    if (node.mixedInType != null) {
      buildSuperTypeSets(node.mixedInType.classNode);
      superMixtures[node].addAll(superMixtures[node.mixedInType.classNode]);
      superTypes[node].addAll(superTypes[node.mixedInType.classNode]);
    }
    for (var superType in node.implementedTypes) {
      buildSuperTypeSets(superType.classNode);
      superTypes[node].addAll(superTypes[superType.classNode]);
    }
    classes.add(node);
    classIndex[node] = classes.length - 1;
  }

  void buildSuperTypeInstantiations(Class node) {
    if (superTypeInstantiations.containsKey(node)) return;
    superTypeInstantiations[node] = <Class, InterfaceType>{node: node.thisType};
    for (var superType in node.supers) {
      var superClass = superType.classNode;
      buildSuperTypeInstantiations(superClass);
      var substitution = new Map<TypeParameter, DartType>.fromIterables(
          superClass.typeParameters, superType.typeArguments);
      superTypeInstantiations[superClass].forEach((key, type) {
        superTypeInstantiations[node][key] = substitute(type, substitution);
      });
    }
  }

  void buildDispatchTable(Class node) {
    if (gettersAndCalls.containsKey(node)) return;
    gettersAndCalls[node] = <Name, Member>{};
    setters[node] = <Name, Member>{};
    if (node.superType != null) {
      buildDispatchTable(node.superType.classNode);
      gettersAndCalls[node].addAll(gettersAndCalls[node.superType.classNode]);
      setters[node].addAll(setters[node.superType.classNode]);
    }
    // Overwrite map entries with declared members.
    Class mixin = node.mixedInType?.classNode ?? node;
    for (Procedure procedure in mixin.procedures) {
      if (procedure.isStatic || procedure.isAbstract) continue;
      if (procedure.kind == ProcedureKind.Setter) {
        setters[node][procedure.name] = procedure;
      } else {
        gettersAndCalls[node][procedure.name] = procedure;
      }
    }
    for (Field field in mixin.fields) {
      if (field.isStatic) continue;
      gettersAndCalls[node][field.name] = field;
      if (!field.isFinal) {
        setters[node][field.name] = field;
      }
    }
  }

  bool isSubclassOf(Class subtype, Class supertype) {
    return superClasses[subtype].contains(supertype);
  }

  bool isSubmixtureOf(Class subtype, Class supertype) {
    return superMixtures[subtype].contains(supertype);
  }

  bool isSubtypeOf(Class subtype, Class supertype) {
    return superTypes[subtype].contains(supertype);
  }

  InterfaceType getClassAsInstanceOf(Class type, Class superType) {
    return superTypeInstantiations[type][superType];
  }

  Member getDispatchTarget(Class class_, Name name, {bool setter: false}) {
    return setter ? setters[class_][name] : gettersAndCalls[class_][name];
  }

  Iterable<Member> getDispatchTargets(Class class_, {bool setters: false}) {
    return setters
        ? this.setters[class_].values
        : gettersAndCalls[class_].values;
  }

  int getClassIndex(Class node) {
    return classIndex[node];
  }

  List<int> getExpenseHistogram() => <int>[];
  double getCompressionRatio() => 0.0;
  int getSuperTypeHashTableSize() => 0;

  noSuchMethod(inv) => super.noSuchMethod(inv);
}

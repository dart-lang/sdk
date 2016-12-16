// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.class_hierarchy_basic;

import 'package:kernel/type_algebra.dart';
import 'package:kernel/ast.dart';

/// A simple implementation of the class hierarchy interface using
/// hash tables for everything.
class BasicClassHierarchy {
  final Map<Class, Set<Class>> superclasses = <Class, Set<Class>>{};
  final Map<Class, Set<Class>> superMixtures = <Class, Set<Class>>{};
  final Map<Class, Set<Class>> supertypes = <Class, Set<Class>>{};
  final Map<Class, Map<Class, Supertype>> supertypeInstantiations =
      <Class, Map<Class, Supertype>>{};
  final Map<Class, Map<Name, Member>> gettersAndCalls =
      <Class, Map<Name, Member>>{};
  final Map<Class, Map<Name, Member>> setters = <Class, Map<Name, Member>>{};
  final Map<Class, Map<Name, List<Member>>> interfaceGettersAndCalls =
      <Class, Map<Name, List<Member>>>{};
  final Map<Class, Map<Name, List<Member>>> interfaceSetters =
      <Class, Map<Name, List<Member>>>{};
  final List<Class> classes = <Class>[];
  final Map<Class, int> classIndex = <Class, int>{};

  BasicClassHierarchy(Program program) {
    for (var library in program.libraries) {
      for (var classNode in library.classes) {
        buildSuperTypeSets(classNode);
        buildSuperTypeInstantiations(classNode);
        buildDispatchTable(classNode);
        buildInterfaceTable(classNode);
      }
    }
  }

  void forEachOverridePair(
      Class class_, callback(Member member, Member superMember, bool setter)) {
    void report(Member member, Member superMember, bool setter) {
      if (!identical(member, superMember)) {
        callback(member, superMember, setter);
      }
    }

    // Report declared members overriding inheritable members.
    for (var member in class_.mixin.members) {
      for (var supertype in class_.supers) {
        if (member.hasGetter) {
          for (var superMember
              in getInterfaceMembersByName(supertype.classNode, member.name)) {
            report(member, superMember, false);
          }
        }
        if (member.hasSetter) {
          for (var superMember in getInterfaceMembersByName(
              supertype.classNode, member.name,
              setter: true)) {
            report(member, superMember, true);
          }
        }
      }
    }
    // Report inherited non-abstract members overriding inheritable or
    // declared members.
    for (var setter in [true, false]) {
      for (var member in getDispatchTargets(class_, setters: setter)) {
        // Report overriding inheritable members.
        for (var supertype in class_.supers) {
          for (var superMember in getInterfaceMembersByName(
              supertype.classNode, member.name,
              setter: setter)) {
            report(member, superMember, setter);
          }
        }
        // Report overriding declared abstract members.
        if (!class_.isAbstract && member.enclosingClass != class_.mixin) {
          for (var declaredMember in getInterfaceMembersByName(
              class_, member.name,
              setter: setter)) {
            report(member, declaredMember, setter);
          }
        }
      }
    }
  }

  void buildSuperTypeSets(Class node) {
    if (superclasses.containsKey(node)) return;
    superclasses[node] = new Set<Class>()..add(node);
    superMixtures[node] = new Set<Class>()..add(node);
    supertypes[node] = new Set<Class>()..add(node);
    if (node.supertype != null) {
      buildSuperTypeSets(node.supertype.classNode);
      superclasses[node].addAll(superclasses[node.supertype.classNode]);
      superMixtures[node].addAll(superMixtures[node.supertype.classNode]);
      supertypes[node].addAll(supertypes[node.supertype.classNode]);
    }
    if (node.mixedInType != null) {
      buildSuperTypeSets(node.mixedInType.classNode);
      superMixtures[node].addAll(superMixtures[node.mixedInType.classNode]);
      supertypes[node].addAll(supertypes[node.mixedInType.classNode]);
    }
    for (var supertype in node.implementedTypes) {
      buildSuperTypeSets(supertype.classNode);
      supertypes[node].addAll(supertypes[supertype.classNode]);
    }
    classes.add(node);
    classIndex[node] = classes.length - 1;
  }

  void buildSuperTypeInstantiations(Class node) {
    if (supertypeInstantiations.containsKey(node)) return;
    supertypeInstantiations[node] = <Class, Supertype>{
      node: node.asThisSupertype
    };
    for (var supertype in node.supers) {
      var superclass = supertype.classNode;
      buildSuperTypeInstantiations(superclass);
      var substitution = Substitution.fromPairs(
          superclass.typeParameters, supertype.typeArguments);
      supertypeInstantiations[superclass].forEach((key, type) {
        supertypeInstantiations[node][key] =
            substitution.substituteSupertype(type);
      });
    }
  }

  void buildDispatchTable(Class node) {
    if (gettersAndCalls.containsKey(node)) return;
    gettersAndCalls[node] = <Name, Member>{};
    setters[node] = <Name, Member>{};
    if (node.supertype != null) {
      buildDispatchTable(node.supertype.classNode);
      gettersAndCalls[node].addAll(gettersAndCalls[node.supertype.classNode]);
      setters[node].addAll(setters[node.supertype.classNode]);
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

  void mergeMaps(
      Map<Name, List<Member>> source, Map<Name, List<Member>> destination) {
    for (var name in source.keys) {
      destination.putIfAbsent(name, () => <Member>[]).addAll(source[name]);
    }
  }

  void buildInterfaceTable(Class node) {
    if (interfaceGettersAndCalls.containsKey(node)) return;
    interfaceGettersAndCalls[node] = <Name, List<Member>>{};
    interfaceSetters[node] = <Name, List<Member>>{};
    void inheritFrom(Supertype type) {
      if (type == null) return;
      buildInterfaceTable(type.classNode);
      mergeMaps(interfaceGettersAndCalls[type.classNode],
          interfaceGettersAndCalls[node]);
      mergeMaps(interfaceSetters[type.classNode], interfaceSetters[node]);
    }

    inheritFrom(node.supertype);
    inheritFrom(node.mixedInType);
    node.implementedTypes.forEach(inheritFrom);
    // Overwrite map entries with declared members.
    for (Procedure procedure in node.mixin.procedures) {
      if (procedure.isStatic) continue;
      if (procedure.kind == ProcedureKind.Setter) {
        interfaceSetters[node][procedure.name] = <Member>[procedure];
      } else {
        interfaceGettersAndCalls[node][procedure.name] = <Member>[procedure];
      }
    }
    for (Field field in node.mixin.fields) {
      if (field.isStatic) continue;
      interfaceGettersAndCalls[node][field.name] = <Member>[field];
      if (!field.isFinal) {
        interfaceSetters[node][field.name] = <Member>[field];
      }
    }
  }

  bool isSubclassOf(Class subtype, Class supertype) {
    return superclasses[subtype].contains(supertype);
  }

  bool isSubmixtureOf(Class subtype, Class supertype) {
    return superMixtures[subtype].contains(supertype);
  }

  bool isSubtypeOf(Class subtype, Class supertype) {
    return supertypes[subtype].contains(supertype);
  }

  Supertype getClassAsInstanceOf(Class type, Class supertype) {
    return supertypeInstantiations[type][supertype];
  }

  Member getDispatchTarget(Class class_, Name name, {bool setter: false}) {
    return setter ? setters[class_][name] : gettersAndCalls[class_][name];
  }

  Iterable<Member> getDispatchTargets(Class class_, {bool setters: false}) {
    return setters
        ? this.setters[class_].values
        : gettersAndCalls[class_].values;
  }

  Member tryFirst(List<Member> members) {
    return (members == null || members.isEmpty) ? null : members[0];
  }

  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    return tryFirst(getInterfaceMembersByName(class_, name, setter: setter));
  }

  Iterable<Member> getInterfaceMembersByName(Class class_, Name name,
      {bool setter: false}) {
    var iterable = setter
        ? interfaceSetters[class_][name]
        : interfaceGettersAndCalls[class_][name];
    return iterable == null ? const <Member>[] : iterable;
  }

  Iterable<Member> getInterfaceMembers(Class class_, {bool setters: false}) {
    return setters
        ? interfaceSetters[class_].values.expand((x) => x)
        : interfaceGettersAndCalls[class_].values.expand((x) => x);
  }

  int getClassIndex(Class node) {
    return classIndex[node];
  }

  List<int> getExpenseHistogram() => <int>[];
  double getCompressionRatio() => 0.0;
  int getSuperTypeHashTableSize() => 0;

  noSuchMethod(inv) => super.noSuchMethod(inv);
}

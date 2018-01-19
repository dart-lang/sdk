// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.incremental_class_hierarchy;

import 'dart:collection';
import 'dart:math';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/heap.dart';
import 'package:kernel/type_algebra.dart';

/// Use [ClassHierarchy] instead.
@deprecated
class IncrementalClassHierarchy implements ClassHierarchy {
  /// Use [ClassHierarchy] instead.
  @deprecated
  IncrementalClassHierarchy.deprecated();

  /// The next unique identifier for [_ClassInfo]s.
  int _nextId = 0;

  /// The mapping from [Class]es to the corresponding [_ClassInfo]s.
  /// The map is ordered in such a way that classes are after superclasses.
  /// It is filled lazily as the client requests information about classes.
  final Map<Class, _ClassInfo> _info = new LinkedHashMap<Class, _ClassInfo>();

  @override
  ClassHierarchy applyChanges(Iterable<Class> classes) {
    if (classes.isEmpty) return this;
    return new IncrementalClassHierarchy.deprecated();
  }

  @override
  void forEachOverridePair(Class node,
      callback(Member declaredMember, Member interfaceMember, bool isSetter)) {
    _ClassInfo info = _getInfo(node);
    for (var supertype in node.supers) {
      var superNode = supertype.classNode;
      var superInfo = _getInfo(superNode);

      var superGetters = superInfo.interfaceGettersAndCalls;
      var superSetters = superInfo.interfaceSetters;

      _reportOverrides(info.implementedGettersAndCalls, superGetters, callback);
      _reportOverrides(info.declaredGettersAndCalls, superGetters, callback,
          onlyAbstract: true);

      _reportOverrides(info.implementedSetters, superSetters, callback,
          isSetter: true);
      _reportOverrides(info.declaredSetters, superSetters, callback,
          isSetter: true, onlyAbstract: true);
    }
    if (!node.isAbstract) {
      // If a non-abstract class declares an abstract method M whose
      // implementation M' is inherited from the superclass, then the inherited
      // method M' overrides the declared method M.
      // This flies in the face of conventional override logic, but is necessary
      // because an instance of the class will contain the method M' which can
      // be invoked through the interface of M.
      // Note that [_reportOverrides] does not report self-overrides, so in
      // most cases these calls will just scan both lists and report nothing.
      _reportOverrides(info.implementedGettersAndCalls,
          info.declaredGettersAndCalls, callback);
      _reportOverrides(info.implementedSetters, info.declaredSetters, callback,
          isSetter: true);
    }
  }

  @override
  Supertype getClassAsInstanceOf(Class node, Class superclass) {
    if (identical(node, superclass)) return node.asThisSupertype;
    _ClassInfo info = _getInfo(node);
    _ClassInfo superInfo = _getInfo(superclass);
    if (!info.isSubtypeOf(superInfo)) return null;
    if (superclass.typeParameters.isEmpty) return superclass.asRawSupertype;
    return info.genericSuperTypes[superclass];
  }

  @override
  int getClassDepth(Class node) {
    return _getInfo(node).depth;
  }

  @override
  InterfaceType getClassicLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    // The algorithm is: first we compute a list of superclasses for both types,
    // ordered from greatest to least depth, and ordered by topological sort
    // index within each depth.  Due to the sort order, we can find the
    // intersection of these lists by a simple walk.
    //
    // Then, for each class in the intersection, determine the exact type that
    // is implemented by type1 and type2.  If the types match, that type is a
    // candidate (it's a member of S_n).  As soon as we find a candidate which
    // is unique for its depth, we return it.
    //
    // As an optimization, if the class for I is a subtype of the class for J,
    // then we know that the list of superclasses of J is a subset of the list
    // of superclasses for I; therefore it is sufficient to compute just the
    // list of superclasses for J.  To avoid complicating the code below (which
    // intersects the two lists), we set both lists equal to the list of
    // superclasses for J.  And vice versa with the role of I and J swapped.

    // Compute the list of superclasses for both types, with the above
    // optimization.
    _ClassInfo info1 = _getInfo(type1.classNode);
    _ClassInfo info2 = _getInfo(type2.classNode);
    List<_ClassInfo> classes1;
    List<_ClassInfo> classes2;
    if (identical(info1, info2) || info1.isSubtypeOf(info2)) {
      classes1 = classes2 = _getRankedSuperclassList(info2);
    } else if (info2.isSubtypeOf(info1)) {
      classes1 = classes2 = _getRankedSuperclassList(info1);
    } else {
      classes1 = _getRankedSuperclassList(info1);
      classes2 = _getRankedSuperclassList(info2);
    }

    // Walk the lists finding their intersection, looking for a depth that has a
    // single candidate.
    int i1 = 0;
    int i2 = 0;
    InterfaceType candidate = null;
    int currentDepth = -1;
    int numCandidatesAtThisDepth = 0;
    while (true) {
      _ClassInfo next = classes1[i1];
      _ClassInfo next2 = classes2[i2];
      if (!identical(next, next2)) {
        if (_LubHeap.sortsBeforeStatic(next, next2)) {
          ++i1;
        } else {
          ++i2;
        }
        continue;
      }
      ++i2;
      ++i1;
      if (next.depth != currentDepth) {
        if (numCandidatesAtThisDepth == 1) return candidate;
        currentDepth = next.depth;
        numCandidatesAtThisDepth = 0;
        candidate = null;
      } else if (numCandidatesAtThisDepth > 1) {
        continue;
      }

      // For each class in the intersection, find the exact type that is
      // implemented by type1 and type2.  If they match, it's a candidate.
      //
      // Two additional optimizations:
      //
      // - If this class lacks type parameters, we know there is a match without
      //   needing to substitute.
      //
      // - If the depth is 0, we have reached Object, so we can return it
      //   immediately.  Since all interface types are subtypes of Object, this
      //   ensures the loop terminates.
      if (next.node.typeParameters.isEmpty) {
        candidate = next.node.rawType;
        if (currentDepth == 0) return candidate;
        ++numCandidatesAtThisDepth;
      } else {
        var superType1 = identical(info1, next)
            ? type1
            : Substitution.fromInterfaceType(type1).substituteType(
                info1.genericSuperTypes[next.node].asInterfaceType);
        var superType2 = identical(info2, next)
            ? type2
            : Substitution.fromInterfaceType(type2).substituteType(
                info2.genericSuperTypes[next.node].asInterfaceType);
        if (superType1 == superType2) {
          candidate = superType1;
          ++numCandidatesAtThisDepth;
        }
      }
    }
  }

  @override
  int getClassIndex(Class node) {
    return _getInfo(node).id;
  }

  @override
  Member getDispatchTarget(Class node, Name name, {bool setter: false}) {
    _ClassInfo info = _getInfo(node);
    List<Member> targets =
        setter ? info.implementedSetters : info.implementedGettersAndCalls;
    return ClassHierarchy.findMemberByName(targets, name);
  }

  @override
  Member getInterfaceMember(Class node, Name name, {bool setter: false}) {
    _ClassInfo info = _getInfo(node);
    List<Member> members =
        setter ? info.interfaceSetters : info.interfaceGettersAndCalls;
    return ClassHierarchy.findMemberByName(members, name);
  }

  @override
  List<Member> getInterfaceMembers(Class class_, {bool setters: false}) {
    var info = _getInfo(class_);
    return setters ? info.interfaceSetters : info.interfaceGettersAndCalls;
  }

  @override
  List<Member> getDeclaredMembers(Class class_, {bool setters: false}) {
    var info = _getInfo(class_);
    return setters ? info.declaredSetters : info.declaredGettersAndCalls;
  }

  @override
  Iterable<Class> getOrderedClasses(Iterable<Class> unordered) {
    unordered.forEach(_getInfo);
    var unorderedSet = unordered.toSet();
    return _info.keys.where(unorderedSet.contains);
  }

  @override
  List<Class> getRankedSuperclasses(Class node) {
    var info = _getInfo(node);
    return _getRankedSuperclassList(info).map((info) => info.node).toList();
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    Supertype castedType = getClassAsInstanceOf(type.classNode, superclass);
    if (castedType == null) return null;
    return Substitution
        .fromInterfaceType(type)
        .substituteType(castedType.asInterfaceType);
  }

  @override
  bool hasProperSubtypes(Class class_) {
    // TODO(scheglov): implement hasProperSubtypes
    throw new UnimplementedError();
  }

  /// Fill the given [info] with declared instance methods and setters.
  void _buildDeclaredMembers(_ClassInfo info) {
    Class node = info.node;
    if (node.mixedInType != null) {
      _ClassInfo mixedInfo = _getInfo(node.mixedInType.classNode);
      info.declaredGettersAndCalls = mixedInfo.declaredGettersAndCalls;
      info.declaredSetters = mixedInfo.declaredSetters;
    } else {
      var members = info.declaredGettersAndCalls = <Member>[];
      var setters = info.declaredSetters = <Member>[];
      for (Procedure procedure in node.procedures) {
        if (procedure.isStatic) continue;
        if (procedure.kind == ProcedureKind.Setter) {
          setters.add(procedure);
        } else {
          members.add(procedure);
        }
      }
      for (Field field in node.fields) {
        if (field.isStatic) continue;
        if (field.hasImplicitGetter) {
          members.add(field);
        }
        if (field.hasImplicitSetter) {
          setters.add(field);
        }
      }
      members.sort(ClassHierarchy.compareMembers);
      setters.sort(ClassHierarchy.compareMembers);
    }
  }

  /// Fill the given [info] with implemented not abstract members and setters.
  void _buildImplementedMembers(_ClassInfo info) {
    List<Member> inheritedMembers;
    List<Member> inheritedSetters;
    Supertype supertype = info.node.supertype;
    if (supertype == null) {
      inheritedMembers = inheritedSetters = const <Member>[];
    } else {
      _ClassInfo superInfo = _getInfo(supertype.classNode);
      inheritedMembers = superInfo.implementedGettersAndCalls;
      inheritedSetters = superInfo.implementedSetters;
    }
    info.implementedGettersAndCalls = _inheritMembers(
        info.declaredGettersAndCalls, inheritedMembers,
        skipAbstractMembers: true);
    info.implementedSetters = _inheritMembers(
        info.declaredSetters, inheritedSetters,
        skipAbstractMembers: true);
  }

  /// Build interface methods or setters for the class described by [info].
  void _buildInterfaceMembers(_ClassInfo info) {
    List<Member> declaredGetters = info.declaredGettersAndCalls;
    List<Member> declaredSetters = info.declaredSetters;
    List<Member> allInheritedGetters = <Member>[];
    List<Member> allInheritedSetters = <Member>[];

    void inheritFrom(Supertype type) {
      if (type == null) return;
      var info = _getInfo(type.classNode);
      // TODO(scheglov): Can we optimize this with yield?

      var inheritedGetters = _getUnshadowedInheritedMembers(
          declaredGetters, info.interfaceGettersAndCalls);
      allInheritedGetters = _merge(allInheritedGetters, inheritedGetters);

      var inheritedSetters = _getUnshadowedInheritedMembers(
          declaredSetters, info.interfaceSetters);
      allInheritedSetters = _merge(allInheritedSetters, inheritedSetters);
    }

    Class node = info.node;
    inheritFrom(node.supertype);
    inheritFrom(node.mixedInType);
    node.implementedTypes.forEach(inheritFrom);

    info.interfaceGettersAndCalls =
        _inheritMembers(declaredGetters, allInheritedGetters);
    info.interfaceSetters =
        _inheritMembers(declaredSetters, allInheritedSetters);
  }

  /// Return the [_ClassInfo] for the [node].
  _ClassInfo _getInfo(Class node) {
    var info = _info[node];
    if (info == null) {
      info = new _ClassInfo(_nextId++, node);

      void addSupertypeIdentifiers(_ClassInfo superInfo) {
        info.supertypeIdSet.add(superInfo.id);
        info.supertypeIdSet.addAll(superInfo.supertypeIdSet);
      }

      int superDepth = -1;
      if (node.supertype != null) {
        var superInfo = _getInfo(node.supertype.classNode);
        superDepth = max(superDepth, superInfo.depth);
        addSupertypeIdentifiers(superInfo);
        _recordSuperTypes(info, node.supertype, superInfo);
      }
      if (node.mixedInType != null) {
        var mixedInfo = _getInfo(node.mixedInType.classNode);
        superDepth = max(superDepth, mixedInfo.depth);
        addSupertypeIdentifiers(mixedInfo);
        _recordSuperTypes(info, node.mixedInType, mixedInfo);
      }
      for (var implementedType in node.implementedTypes) {
        var implementedInfo = _getInfo(implementedType.classNode);
        superDepth = max(superDepth, implementedInfo.depth);
        addSupertypeIdentifiers(implementedInfo);
        _recordSuperTypes(info, implementedType, implementedInfo);
      }

      info.depth = superDepth + 1;
      _info[node] = info;

      _buildDeclaredMembers(info);
      _buildImplementedMembers(info);
      _buildInterfaceMembers(info);
    }
    return info;
  }

  List<_ClassInfo> _getRankedSuperclassList(_ClassInfo info) {
    if (info.rankedSuperclassList != null) {
      return info.rankedSuperclassList;
    }

    var heap = new _LubHeap()..add(info);
    var chain = <_ClassInfo>[];
    info.rankedSuperclassList = chain;

    _ClassInfo lastInfo = null;
    while (heap.isNotEmpty) {
      var nextInfo = heap.remove();
      if (identical(nextInfo, lastInfo)) continue;
      lastInfo = nextInfo;

      chain.add(nextInfo);

      void addToHeap(Supertype supertype) {
        var superInfo = _getInfo(supertype.classNode);
        heap.add(superInfo);
      }

      var classNode = nextInfo.node;
      if (classNode.supertype != null) addToHeap(classNode.supertype);
      if (classNode.mixedInType != null) addToHeap(classNode.mixedInType);
      classNode.implementedTypes.forEach(addToHeap);
    }
    return chain;
  }

  void _recordSuperTypes(
      _ClassInfo subInfo, Supertype supertype, _ClassInfo superInfo) {
    if (supertype.typeArguments.isEmpty) {
      // The supertype is not generic, and if it does not have generic
      // supertypes itself, then subclass also does not have generic supertypes.
      if (superInfo.genericSuperTypes == null) return;
      // Since the immediate super type is not generic, all entries in its
      // super type map are also valid entries for this class.
      if (subInfo.genericSuperTypes == null &&
          superInfo.ownsGenericSuperTypeMap) {
        // Instead of copying the map, take ownership of the map object.
        // This may result in more entries being added to the map later. Those
        // are not valid for the super type, but it works out because all
        // lookups in the map are guarded by a subtype check, so the super type
        // will not be bothered by the extra entries.
        subInfo.genericSuperTypes = superInfo.genericSuperTypes;
        superInfo.ownsGenericSuperTypeMap = false;
      } else {
        // Copy over the super type entries.
        subInfo.genericSuperTypes ??= <Class, Supertype>{};
        subInfo.genericSuperTypes.addAll(superInfo.genericSuperTypes);
      }
    } else {
      // Copy over all transitive generic super types, and substitute the
      // free variables with those provided in [supertype].
      Class superclass = supertype.classNode;
      var substitution = Substitution.fromPairs(
          superclass.typeParameters, supertype.typeArguments);
      subInfo.genericSuperTypes ??= <Class, Supertype>{};
      superInfo.genericSuperTypes?.forEach((Class key, Supertype type) {
        subInfo.genericSuperTypes[key] = substitution.substituteSupertype(type);
      });
      subInfo.genericSuperTypes[superclass] = supertype;
    }
  }

  /// Returns the subset of members in [inherited] for which a member with the
  /// same name does not occur in [declared].
  ///
  /// The input lists must be sorted, and the returned list is sorted.
  static List<Member> _getUnshadowedInheritedMembers(
      List<Member> declared, List<Member> inherited) {
    List<Member> result =
        new List<Member>.filled(inherited.length, null, growable: true);
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < declared.length && j < inherited.length) {
      Member declaredMember = declared[i];
      Member inheritedMember = inherited[j];
      int comparison =
          ClassHierarchy.compareMembers(declaredMember, inheritedMember);
      if (comparison < 0) {
        ++i;
      } else if (comparison > 0) {
        result[storeIndex++] = inheritedMember;
        ++j;
      } else {
        // Move past the shadowed member, but retain the declared member, as
        // it may shadow multiple members.
        ++j;
      }
    }
    // If the list of declared members is exhausted, copy over the remains of
    // the inherited members.
    while (j < inherited.length) {
      result[storeIndex++] = inherited[j++];
    }
    result.length = storeIndex;
    return result;
  }

  /// Computes the list of implemented members, based on the declared instance
  /// members and inherited instance members.
  ///
  /// Both lists must be sorted by name beforehand.
  static List<Member> _inheritMembers(
      List<Member> declared, List<Member> inherited,
      {bool skipAbstractMembers: false}) {
    List<Member> result = <Member>[]..length =
        declared.length + inherited.length;
    // Since both lists are sorted, we can fuse them like in merge sort.
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < declared.length && j < inherited.length) {
      Member declaredMember = declared[i];
      Member inheritedMember = inherited[j];
      if (skipAbstractMembers && declaredMember.isAbstract) {
        ++i;
        continue;
      }
      if (skipAbstractMembers && inheritedMember.isAbstract) {
        ++j;
        continue;
      }
      int comparison =
          ClassHierarchy.compareMembers(declaredMember, inheritedMember);
      if (comparison < 0) {
        result[storeIndex++] = declaredMember;
        ++i;
      } else if (comparison > 0) {
        result[storeIndex++] = inheritedMember;
        ++j;
      } else {
        result[storeIndex++] = declaredMember;
        ++i;
        ++j; // Move past overridden member.
      }
    }
    // One of the two lists is now exhausted, copy over the remains.
    while (i < declared.length) {
      Member declaredMember = declared[i++];
      if (skipAbstractMembers && declaredMember.isAbstract) continue;
      result[storeIndex++] = declaredMember;
    }
    while (j < inherited.length) {
      Member inheritedMember = inherited[j++];
      if (skipAbstractMembers && inheritedMember.isAbstract) continue;
      result[storeIndex++] = inheritedMember;
    }
    result.length = storeIndex;
    return result;
  }

  /// Merges two sorted lists.
  ///
  /// If a given member occurs in both lists, the merge will attempt to exclude
  /// the duplicate member, but is not strictly guaranteed to do so.
  static List<Member> _merge(List<Member> first, List<Member> second) {
    if (first.isEmpty) return second;
    if (second.isEmpty) return first;
    List<Member> result = new List<Member>.filled(
        first.length + second.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < first.length && j < second.length) {
      Member firstMember = first[i];
      Member secondMember = second[j];
      int compare = ClassHierarchy.compareMembers(firstMember, secondMember);
      if (compare <= 0) {
        result[storeIndex++] = firstMember;
        ++i;
        // If the same member occurs in both lists, skip the duplicate.
        if (identical(firstMember, secondMember)) {
          ++j;
        }
      } else {
        result[storeIndex++] = secondMember;
        ++j;
      }
    }
    while (i < first.length) {
      result[storeIndex++] = first[i++];
    }
    while (j < second.length) {
      result[storeIndex++] = second[j++];
    }
    result.length = storeIndex;
    return result;
  }

  static void _reportOverrides(
      List<Member> declaredList,
      List<Member> inheritedList,
      callback(Member declaredMember, Member interfaceMember, bool isSetter),
      {bool isSetter: false,
      bool onlyAbstract: false}) {
    int i = 0, j = 0;
    while (i < declaredList.length && j < inheritedList.length) {
      Member declared = declaredList[i];
      if (onlyAbstract && !declared.isAbstract) {
        ++i;
        continue;
      }
      Member inherited = inheritedList[j];
      int comparison = ClassHierarchy.compareMembers(declared, inherited);
      if (comparison < 0) {
        ++i;
      } else if (comparison > 0) {
        ++j;
      } else {
        if (!identical(declared, inherited)) {
          callback(declared, inherited, isSetter);
        }
        // A given declared member may override multiple interface members,
        // so only move past the interface member.
        ++j;
      }
    }
  }

  @override
  List<Member> getDispatchTargets(Class class_, {bool setters: false}) {
    throw new UnimplementedError();
  }

  @override
  bool isUsedAsSuperInterface(Class class_) {
    throw new UnimplementedError();
  }

  @override
  bool isUsedAsSuperClass(Class class_) {
    throw new UnimplementedError();
  }

  @override
  bool isUsedAsMixin(Class class_) {
    throw new UnimplementedError();
  }

  @override
  bool isSubtypeOf(Class subtype, Class superclass) {
    throw new UnimplementedError();
  }

  @override
  bool isSubmixtureOf(Class submixture, Class superclass) {
    throw new UnimplementedError();
  }

  @override
  bool isSubclassOf(Class subclass, Class superclass) {
    throw new UnimplementedError();
  }

  @override
  ClassSet getSubtypesOf(Class class_) {
    throw new UnimplementedError();
  }

  @override
  ClassSet getSubclassesOf(Class class_) {
    throw new UnimplementedError();
  }

  @override
  Member getSingleTargetForInterfaceInvocation(Member interfaceTarget,
      {bool setter: false}) {
    throw new UnimplementedError();
  }
}

/// Information about a [Class].
class _ClassInfo {
  /// The unique identifier of the [_ClassInfo].
  final int id;

  /// The [Class] node described by this [_ClassInfo].
  final Class node;

  /// The number of steps in the longest inheritance path from the class
  /// to [Object], or `-1` if the depth has not been computed yet.
  int depth = -1;

  /// The list of superclasses sorted by depth (descending order) and
  /// unique identifiers (ascending order), or `null` if the list has not
  /// been computed yet.
  List<_ClassInfo> rankedSuperclassList;

  /// The set of [id]s for supertypes.
  /// TODO(scheglov): Maybe optimize.
  final Set<int> supertypeIdSet = new HashSet<int>();

  /// Maps generic supertype classes to the instantiation implemented by this
  /// class, or `null` if the class does not have generic supertypes.
  ///
  /// E.g. `List` maps to `List<String>` for a class that directly of indirectly
  /// implements `List<String>`.
  ///
  /// However, the map may contain additional entries for classes that are not
  /// supertypes of this class, so that a single map object can be shared
  /// between different classes.  Lookups into the map should therefore be
  /// guarded by a subtype check.
  ///
  /// For example:
  ///
  ///     class Q<T>
  ///     class A<T>
  ///
  ///     class B extends A<String>
  ///     class C extends B implements Q<int>
  ///
  /// In this case, a single map object `{A: A<String>, Q: Q<int>}` may be
  /// shared by the classes `B` and `C`.
  Map<Class, Supertype> genericSuperTypes;

  /// If true, this is the current "owner" of [genericSuperTypes], meaning
  /// we may add additional entries to the map or transfer ownership to another
  /// class.
  bool ownsGenericSuperTypeMap = true;

  /// Instance fields, getters, methods, and operators declared in this class
  /// or its mixed-in class, sorted according to [_compareMembers].
  List<Member> declaredGettersAndCalls;

  /// Non-final instance fields and setters declared in this class or its
  /// mixed-in class, sorted according to [_compareMembers].
  List<Member> declaredSetters;

  /// Instance fields, getters, methods, and operators implemented by this class
  /// (declared or inherited).
  List<Member> implementedGettersAndCalls;

  /// Non-final instance fields and setters implemented by this class
  /// (declared or inherited).
  List<Member> implementedSetters;

  /// Instance fields, getters, methods, and operators declared in this class,
  /// or its supertype, or interfaces, sorted according to [_compareMembers],
  /// or `null` if it has not been computed yet.
  List<Member> interfaceGettersAndCalls;

  /// Non-final instance fields and setters declared in this class, or its
  /// supertype, or interfaces, sorted according to [_compareMembers], or
  /// `null` if it has not been computed yet.
  List<Member> interfaceSetters;

  _ClassInfo(this.id, this.node);

  /// Return `true` if the [superInfo] corresponds to a supertype of this class.
  bool isSubtypeOf(_ClassInfo superInfo) {
    return supertypeIdSet.contains(superInfo.id);
  }

  @override
  String toString() => node.toString();
}

/// Heap for use in computing least upper bounds.
///
/// The heap is sorted such that classes that are deepest in the hierarchy
/// are removed first; in the case of ties, classes with lower unique
/// identifiers removed first.
class _LubHeap extends Heap<_ClassInfo> {
  @override
  bool sortsBefore(_ClassInfo a, _ClassInfo b) => sortsBeforeStatic(a, b);

  static bool sortsBeforeStatic(_ClassInfo a, _ClassInfo b) {
    if (a.depth > b.depth) return true;
    if (a.depth < b.depth) return false;
    return a.id < b.id;
  }
}

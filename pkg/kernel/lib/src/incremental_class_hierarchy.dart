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

/// Lazy and incremental implementation of [ClassHierarchy].
class IncrementalClassHierarchy implements ClassHierarchy {
  /// The next unique identifier for [_ClassInfo]s.
  int _nextId = 0;

  /// The mapping from [Class]es to the corresponding [_ClassInfo]s.
  /// It is filled lazily as the client requests information about classes.
  final Map<Class, _ClassInfo> _info = {};

  @override
  Iterable<Class> get classes {
    // TODO(scheglov): implement classes
    throw new UnimplementedError();
  }

  @override
  void forEachOverridePair(Class class_,
      callback(Member declaredMember, Member interfaceMember, bool isSetter)) {
    // TODO(scheglov): implement forEachOverridePair
    throw new UnimplementedError();
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
  Member getDispatchTarget(Class class_, Name name, {bool setter: false}) {
    // TODO(scheglov): implement getDispatchTarget
    throw new UnimplementedError();
  }

  @override
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    // TODO(scheglov): implement getInterfaceMember
    throw new UnimplementedError();
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

  /// Return the [_ClassInfo] for the [node].
  _ClassInfo _getInfo(Class node) {
    var info = _info[node];
    if (info == null) {
      info = new _ClassInfo(_nextId++, node);
      _info[node] = info;

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
  /// unique identifiers (ascending order), or `null` if the lit has not
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

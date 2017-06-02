// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.incremental_class_hierarchy;

import 'dart:math';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/heap.dart';

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
  Supertype getClassAsInstanceOf(Class class_, Class superclass) {
    // TODO(scheglov): implement getClassAsInstanceOf
    throw new UnimplementedError();
  }

  @override
  int getClassDepth(Class node) {
    return _getInfo(node).depth;
  }

  @override
  InterfaceType getClassicLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    // TODO(scheglov): implement getClassicLeastUpperBound
    throw new UnimplementedError();
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
    // TODO(scheglov): implement getTypeAsInstanceOf
    throw new UnimplementedError();
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

      int superDepth = -1;
      if (node.supertype != null) {
        var superInfo = _getInfo(node.supertype.classNode);
        superDepth = max(superDepth, superInfo.depth);
      }
      if (node.mixedInType != null) {
        var mixedInfo = _getInfo(node.mixedInType.classNode);
        superDepth = max(superDepth, mixedInfo.depth);
      }
      for (var supertype in node.implementedTypes) {
        var implementedInfo = _getInfo(supertype.classNode);
        superDepth = max(superDepth, implementedInfo.depth);
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

  _ClassInfo(this.id, this.node);

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

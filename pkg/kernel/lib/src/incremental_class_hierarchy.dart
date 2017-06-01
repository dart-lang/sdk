// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.incremental_class_hierarchy;

import 'dart:math';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

/// Lazy and incremental implementation of [ClassHierarchy].
class IncrementalClassHierarchy implements ClassHierarchy {
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
    var info = _getInfo(node);
    if (info.depth < 0) {
      int superDepth = -1;
      if (node.supertype != null) {
        superDepth = max(superDepth, getClassDepth(node.supertype.classNode));
      }
      if (node.mixedInType != null) {
        superDepth = max(superDepth, getClassDepth(node.mixedInType.classNode));
      }
      for (var supertype in node.implementedTypes) {
        superDepth = max(superDepth, getClassDepth(supertype.classNode));
      }
      info.depth = superDepth + 1;
    }

    return info.depth;
  }

  @override
  InterfaceType getClassicLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    // TODO(scheglov): implement getClassicLeastUpperBound
    throw new UnimplementedError();
  }

  @override
  int getClassIndex(Class class_) {
    // TODO(scheglov): implement getClassIndex
    throw new UnimplementedError();
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
  List<Class> getRankedSuperclasses(Class class_) {
    // TODO(scheglov): implement getRankedSuperclasses
    throw new UnimplementedError();
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
    return _info.putIfAbsent(node, () => new _ClassInfo(node));
  }
}

/// Information about a [Class].
class _ClassInfo {
  final Class node;

  /// The number of steps in the longest inheritance path from the class
  /// to [Object], or -1 if the depth has not been computed yet.
  int depth = -1;

  _ClassInfo(this.node);
}

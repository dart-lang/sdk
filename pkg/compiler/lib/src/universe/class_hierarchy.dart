// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart' show InterfaceType;
import 'class_set.dart';

// TODO(johnniwinther): Move more methods from `JClosedWorld` to
// `ClassHierarchy`.
abstract class ClassHierarchy {
  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [JClosedWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassEntity cls);

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [JClosedWorld].
  ClassSet getClassSet(ClassEntity cls);

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassEntity x, ClassEntity y);

  /// Returns a [SubclassResult] for the subclasses that are contained in
  /// the subclass/subtype sets of both [cls1] and [cls2].
  ///
  /// Classes that are implied by included superclasses/supertypes are not
  /// returned.
  ///
  /// For instance for this hierarchy
  ///
  ///     class A {}
  ///     class B {}
  ///     class C implements A, B {}
  ///     class D extends C {}
  ///
  /// the query
  ///
  ///     commonSubclasses(A, ClassQuery.SUBTYPE, B, ClassQuery.SUBTYPE)
  ///
  /// return the set {C} because [D] is implied by [C].
  SubclassResult commonSubclasses(
      ClassEntity cls1, ClassQuery query1, ClassEntity cls2, ClassQuery query2);

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subtypesOf(ClassEntity cls);

  /// Returns an iterable over the live classes that extend [cls] including
  /// [cls] itself.
  Iterable<ClassEntity> subclassesOf(ClassEntity cls);

  /// Applies [f] to each live class that implements [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubtypeOf(
      ClassEntity cls, IterationStep f(ClassEntity cls));
}

class ClassHierarchyImpl implements ClassHierarchy {
  final CommonElements _commonElements;
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes;
  final Map<ClassEntity, ClassSet> _classSets;

  ClassHierarchyImpl(
      this._commonElements, this._classHierarchyNodes, this._classSets);

  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [JClosedWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassEntity cls) {
    return _classHierarchyNodes[cls];
  }

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [JClosedWorld].
  ClassSet getClassSet(ClassEntity cls) {
    return _classSets[cls];
  }

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassEntity x, ClassEntity y) {
    ClassSet classSet = _classSets[y];
    assert(classSet != null,
        failedAt(y, "No ClassSet for $y (${y.runtimeType}): ${_classSets}"));
    ClassHierarchyNode classHierarchyNode = _classHierarchyNodes[x];
    assert(classHierarchyNode != null,
        failedAt(x, "No ClassHierarchyNode for $x"));
    return classSet.hasSubtype(classHierarchyNode);
  }

  /// Return `true` if [x] is a (non-strict) subclass of [y].
  bool isSubclassOf(ClassEntity x, ClassEntity y) {
    return _classHierarchyNodes[y].hasSubclass(_classHierarchyNodes[x]);
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subtypesOf(ClassEntity cls) {
    ClassSet classSet = _classSets[cls];
    if (classSet == null) {
      return const <ClassEntity>[];
    } else {
      return classSet
          .subtypesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
    }
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subclassesOf(ClassEntity cls) {
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls];
    if (hierarchy == null) return const <ClassEntity>[];
    return hierarchy
        .subclassesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// _not_ including [cls].
  Iterable<ClassEntity> strictSubtypesOf(ClassEntity cls) {
    ClassSet classSet = _classSets[cls];
    if (classSet == null) {
      return const <ClassEntity>[];
    } else {
      return classSet.subtypesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
          strict: true);
    }
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] _not_ including [cls] itself.
  Iterable<ClassEntity> strictSubclassesOf(ClassEntity cls) {
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return const <ClassEntity>[];
    return subclasses.subclassesByMask(
        ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Applies [f] to each live class that extend [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubclassOf(
      ClassEntity cls, IterationStep f(ClassEntity cls)) {
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return;
    subclasses.forEachSubclass(f, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Applies [f] to each live class that implements [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubtypeOf(
      ClassEntity cls, IterationStep f(ClassEntity cls)) {
    ClassSet classSet = _classSets[cls];
    if (classSet == null) return;
    classSet.forEachSubtype(f, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  SubclassResult commonSubclasses(ClassEntity cls1, ClassQuery query1,
      ClassEntity cls2, ClassQuery query2) {
    if (query1 == ClassQuery.EXACT && query2 == ClassQuery.EXACT) {
      // Exact classes [cls1] and [cls2] must be identical to have any classes
      // in common.
      if (cls1 != cls2) {
        return SubclassResult.EMPTY;
      }
      return SubclassResult.EXACT1;
    } else if (query1 == ClassQuery.EXACT) {
      if (query2 == ClassQuery.SUBCLASS) {
        // Exact [cls1] must be a subclass of [cls2] to have any classes in
        // common.
        if (isSubclassOf(cls1, cls2)) {
          return SubclassResult.EXACT1;
        }
      } else if (query2 == ClassQuery.SUBTYPE) {
        // Exact [cls1] must be a subtype of [cls2] to have any classes in
        // common.
        if (isSubtypeOf(cls1, cls2)) {
          return SubclassResult.EXACT1;
        }
      }
      return SubclassResult.EMPTY;
    } else if (query2 == ClassQuery.EXACT) {
      if (query1 == ClassQuery.SUBCLASS) {
        // Exact [cls2] must be a subclass of [cls1] to have any classes in
        // common.
        if (isSubclassOf(cls2, cls1)) {
          return SubclassResult.EXACT2;
        }
      } else if (query1 == ClassQuery.SUBTYPE) {
        // Exact [cls2] must be a subtype of [cls1] to have any classes in
        // common.
        if (isSubtypeOf(cls2, cls1)) {
          return SubclassResult.EXACT2;
        }
      }
      return SubclassResult.EMPTY;
    } else if (query1 == ClassQuery.SUBCLASS && query2 == ClassQuery.SUBCLASS) {
      // [cls1] must be a subclass of [cls2] or vice versa to have any classes
      // in common.
      if (cls1 == cls2 || isSubclassOf(cls1, cls2)) {
        // The subclasses of [cls1] are contained within the subclasses of
        // [cls2].
        return SubclassResult.SUBCLASS1;
      } else if (isSubclassOf(cls2, cls1)) {
        // The subclasses of [cls2] are contained within the subclasses of
        // [cls1].
        return SubclassResult.SUBCLASS2;
      }
      return SubclassResult.EMPTY;
    } else if (query1 == ClassQuery.SUBCLASS) {
      if (isSubtypeOf(cls1, cls2)) {
        // The subclasses of [cls1] are all subtypes of [cls2].
        return SubclassResult.SUBCLASS1;
      }
      if (cls1 == _commonElements.objectClass) {
        // Since [cls1] is `Object` all subtypes of [cls2] are contained within
        // the subclasses of [cls1].
        return SubclassResult.SUBTYPE2;
      }
      // Find all the root subclasses of [cls1] of that implement [cls2].
      //
      // For this hierarchy:
      //
      //     class I {}
      //     class A {}
      //     class B extends A implements I {}
      //     class C extends B {}
      //     class D extends A implements I {}
      //
      // the common subclasses of "subclass of A" and "subtype of I" returns
      // "subclasses of {B, D}". The inclusion of class `C` is implied because
      // it is a subclass of `B`.
      List<ClassEntity> classes = <ClassEntity>[];
      forEachStrictSubclassOf(cls1, (ClassEntity subclass) {
        if (isSubtypeOf(subclass, cls2)) {
          classes.add(subclass);
          // Skip subclasses of [subclass]; they all implement [cls2] by
          // inheritance and are included in the subclasses of [subclass].
          return IterationStep.SKIP_SUBCLASSES;
        }
        return IterationStep.CONTINUE;
      });
      return new SubclassResult(classes);
    } else if (query2 == ClassQuery.SUBCLASS) {
      if (isSubtypeOf(cls2, cls1)) {
        // The subclasses of [cls2] are all subtypes of [cls1].
        return SubclassResult.SUBCLASS2;
      }
      if (cls2 == _commonElements.objectClass) {
        // Since [cls2] is `Object` all subtypes of [cls1] are contained within
        // the subclasses of [cls2].
        return SubclassResult.SUBTYPE1;
      }
      // Find all the root subclasses of [cls2] of that implement [cls1].
      List<ClassEntity> classes = <ClassEntity>[];
      forEachStrictSubclassOf(cls2, (ClassEntity subclass) {
        if (isSubtypeOf(subclass, cls1)) {
          classes.add(subclass);
          // Skip subclasses of [subclass]; they all implement [cls1] by
          // inheritance and are included in the subclasses of [subclass].
          return IterationStep.SKIP_SUBCLASSES;
        }
        return IterationStep.CONTINUE;
      });
      return new SubclassResult(classes);
    } else {
      if (cls1 == cls2 || isSubtypeOf(cls1, cls2)) {
        // The subtypes of [cls1] are contained within the subtypes of [cls2].
        return SubclassResult.SUBTYPE1;
      } else if (isSubtypeOf(cls2, cls1)) {
        // The subtypes of [cls2] are contained within the subtypes of [cls1].
        return SubclassResult.SUBTYPE2;
      }
      // Find all the root subclasses of [cls1] of that implement [cls2].
      //
      // For this hierarchy:
      //
      //     class I {}
      //     class A {}
      //     class B extends A implements I {}
      //     class C extends B {}
      //     class D extends A implements I {}
      //     class E implements B {}
      //     class F extends E {}
      //
      // the common subclasses of "subtype of A" and "subtype of I" returns
      // "subclasses of {B, D, E}". The inclusion of classes `C` and `F` is
      // implied because they are subclasses of `B` and `E`, respectively.
      List<ClassEntity> classes = <ClassEntity>[];
      forEachStrictSubtypeOf(cls1, (ClassEntity subclass) {
        if (isSubtypeOf(subclass, cls2)) {
          classes.add(subclass);
          // Skip subclasses of [subclass]; they all implement [cls2] by
          // inheritance and are included in the subclasses of [subclass].
          return IterationStep.SKIP_SUBCLASSES;
        }
        return IterationStep.CONTINUE;
      });
      return new SubclassResult(classes);
    }
  }
}

class ClassHierarchyBuilder {
  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes =
      <ClassEntity, ClassHierarchyNode>{};
  final Map<ClassEntity, ClassSet> classSets = <ClassEntity, ClassSet>{};
  final Map<ClassEntity, Set<ClassEntity>> mixinUses =
      new Map<ClassEntity, Set<ClassEntity>>();

  final CommonElements _commonElements;
  final ClassQueries _classQueries;

  ClassHierarchyBuilder(this._commonElements, this._classQueries);

  void registerClass(ClassEntity cls) {
    _ensureClassSet(_classQueries.getDeclaration(cls));
  }

  ClassHierarchyNode _ensureClassHierarchyNode(ClassEntity cls) {
    assert(_classQueries.checkClass(cls));
    return classHierarchyNodes.putIfAbsent(cls, () {
      ClassHierarchyNode parentNode;
      ClassEntity superclass = _classQueries.getSuperClass(cls);
      if (superclass != null) {
        parentNode = _ensureClassHierarchyNode(superclass);
      }
      return new ClassHierarchyNode(
          parentNode, cls, _classQueries.getHierarchyDepth(cls));
    });
  }

  ClassSet _ensureClassSet(ClassEntity cls) {
    assert(_classQueries.checkClass(cls));
    return classSets.putIfAbsent(cls, () {
      ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
      ClassSet classSet = new ClassSet(node);

      for (InterfaceType type in _classQueries.getSupertypes(cls)) {
        // TODO(johnniwinther): Optimization: Avoid adding [cls] to
        // superclasses.
        ClassSet subtypeSet = _ensureClassSet(type.element);
        subtypeSet.addSubtype(node);
      }

      ClassEntity appliedMixin = _classQueries.getAppliedMixin(cls);
      while (appliedMixin != null) {
        // TODO(johnniwinther): Use the data stored in [ClassSet].
        registerMixinUse(cls, appliedMixin);
        ClassSet mixinSet = _ensureClassSet(appliedMixin);
        mixinSet.addMixinApplication(node);

        // In case of
        //
        //    class A {}
        //    class B = Object with A;
        //    class C = Object with B;
        //
        // we need to register that C not only mixes in B but also A.
        appliedMixin = _classQueries.getAppliedMixin(appliedMixin);
      }
      return classSet;
    });
  }

  void _updateSuperClassHierarchyNodeForClass(ClassHierarchyNode node) {
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    ClassEntity cls = node.cls;
    if (cls != _commonElements.functionClass &&
        _classQueries.implementsFunction(cls)) {
      ClassSet subtypeSet = _ensureClassSet(_commonElements.functionClass);
      subtypeSet.addSubtype(node);
    }
    if (!node.isInstantiated && node.parentNode != null) {
      _updateSuperClassHierarchyNodeForClass(node.parentNode);
    }
  }

  void updateClassHierarchyNodeForClass(ClassEntity cls,
      {bool directlyInstantiated: false, bool abstractlyInstantiated: false}) {
    ClassHierarchyNode node = _ensureClassSet(cls).node;
    _updateSuperClassHierarchyNodeForClass(node);
    if (directlyInstantiated) {
      node.isDirectlyInstantiated = true;
    }
    if (abstractlyInstantiated) {
      node.isAbstractlyInstantiated = true;
    }
  }

  void registerMixinUse(ClassEntity mixinApplication, ClassEntity mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    Set<ClassEntity> users =
        mixinUses.putIfAbsent(mixin, () => new Set<ClassEntity>());
    users.add(mixinApplication);
  }

  bool _isSubtypeOf(ClassEntity x, ClassEntity y) {
    assert(
        classSets.containsKey(x), "ClassSet for $x has not been computed yet.");
    ClassSet classSet = classSets[y];
    assert(classSet != null,
        failedAt(y, "No ClassSet for $y (${y.runtimeType}): ${classSets}"));
    ClassHierarchyNode classHierarchyNode = classHierarchyNodes[x];
    assert(classHierarchyNode != null,
        failedAt(x, "No ClassHierarchyNode for $x"));
    return classSet.hasSubtype(classHierarchyNode);
  }

  bool isInheritedInSubtypeOf(ClassEntity x, ClassEntity y) {
    ClassSet classSet = classSets[x];
    assert(classSet != null,
        failedAt(x, "No ClassSet for $x (${x.runtimeType}): ${classSets}"));

    if (_isSubtypeOf(x, y)) {
      // [x] implements [y] itself, possible through supertypes.
      return true;
    }

    /// Returns `true` if any live subclass of [node] implements [y].
    bool subclassImplements(ClassHierarchyNode node, {bool strict}) {
      return node.anySubclass((ClassEntity z) => _isSubtypeOf(z, y),
          ClassHierarchyNode.INSTANTIATED,
          strict: strict);
    }

    if (subclassImplements(classSet.node, strict: true)) {
      // A subclass of [x] implements [y].
      return true;
    }

    for (ClassHierarchyNode mixinApplication
        in classSet.mixinApplicationNodes) {
      if (subclassImplements(mixinApplication, strict: false)) {
        // A subclass of [mixinApplication] implements [y].
        return true;
      }
    }
    return false;
  }
}

abstract class ClassQueries {
  bool checkClass(covariant ClassEntity cls);
  bool validateClass(covariant ClassEntity cls);

  /// Returns the declaration of [cls].
  ClassEntity getDeclaration(covariant ClassEntity cls);

  /// Returns the class mixed into [cls] if any.
  // TODO(johnniwinther): Replace this by a `getAppliedMixins` function that
  // return transitively mixed in classes like in:
  //     class A {}
  //     class B = Object with A;
  //     class C = Object with B;
  ClassEntity getAppliedMixin(covariant ClassEntity cls);

  /// Returns the hierarchy depth of [cls].
  int getHierarchyDepth(covariant ClassEntity cls);

  /// Returns `true` if [cls] implements `Function` either explicitly or through
  /// a `call` method.
  bool implementsFunction(covariant ClassEntity cls);

  /// Returns the superclass of [cls] if any.
  ClassEntity getSuperClass(covariant ClassEntity cls);

  /// Returns all supertypes of [cls].
  Iterable<InterfaceType> getSupertypes(covariant ClassEntity cls);
}

/// Enum values defining subset of classes included in queries.
enum ClassQuery {
  /// Only the class itself is included.
  EXACT,

  /// The class and all subclasses (transitively) are included.
  SUBCLASS,

  /// The class and all classes that implement or subclass it (transitively)
  /// are included.
  SUBTYPE,
}

/// Result kind for [ClassHierarchy.commonSubclasses].
enum SubclassResultKind {
  /// No common subclasses.
  EMPTY,

  /// Exactly the first class in common.
  EXACT1,

  /// Exactly the second class in common.
  EXACT2,

  /// Subclasses of the first class in common.
  SUBCLASS1,

  /// Subclasses of the second class in common.
  SUBCLASS2,

  /// Subtypes of the first class in common.
  SUBTYPE1,

  /// Subtypes of the second class in common.
  SUBTYPE2,

  /// Subclasses of a set of classes in common.
  SET
}

/// Result computed in [ClassHierarchy.commonSubclasses].
class SubclassResult {
  final SubclassResultKind kind;
  final List<ClassEntity> classes;

  SubclassResult(this.classes) : kind = SubclassResultKind.SET;

  const SubclassResult.internal(this.kind) : classes = null;

  static const SubclassResult EMPTY =
      const SubclassResult.internal(SubclassResultKind.EMPTY);
  static const SubclassResult EXACT1 =
      const SubclassResult.internal(SubclassResultKind.EXACT1);
  static const SubclassResult EXACT2 =
      const SubclassResult.internal(SubclassResultKind.EXACT2);
  static const SubclassResult SUBCLASS1 =
      const SubclassResult.internal(SubclassResultKind.SUBCLASS1);
  static const SubclassResult SUBCLASS2 =
      const SubclassResult.internal(SubclassResultKind.SUBCLASS2);
  static const SubclassResult SUBTYPE1 =
      const SubclassResult.internal(SubclassResultKind.SUBTYPE1);
  static const SubclassResult SUBTYPE2 =
      const SubclassResult.internal(SubclassResultKind.SUBTYPE2);

  String toString() => 'SubclassResult($kind,classes=$classes)';
}

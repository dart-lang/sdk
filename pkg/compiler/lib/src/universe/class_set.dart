// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.world.class_set;

import 'dart:collection' show IterableBase;

import '../elements/elements.dart' show ClassElement;
import '../elements/entities.dart' show ClassEntity;
import '../util/enumset.dart' show EnumSet;
import '../util/util.dart' show Link;

/// Enum for the different kinds of instantiation of a class.
enum Instantiation {
  UNINSTANTIATED,
  DIRECTLY_INSTANTIATED,
  INDIRECTLY_INSTANTIATED,
  ABSTRACTLY_INSTANTIATED,
}

/// Node for [cls] in a tree forming the subclass relation of [ClassEntity]s.
///
/// This is used by the [ClosedWorld] to perform queries on subclass and subtype
/// relations.
///
/// For this class hierarchy:
///
///     class A {}
///     class B extends A {}
///     class C extends A {}
///     class D extends B {}
///     class E extends D {}
///
/// the [ClassHierarchyNode]s form this subclass tree:
///
///       Object
///         |
///         A
///        / \
///       B   C
///       |
///       D
///       |
///       E
///
class ClassHierarchyNode {
  /// Enum set for selecting instantiated classes in
  /// [ClassHierarchyNode.subclassesByMask],
  /// [ClassHierarchyNode.subclassesByMask] and [ClassSet.subtypesByMask].
  static final EnumSet<Instantiation> INSTANTIATED =
      new EnumSet<Instantiation>.fromValues(const <Instantiation>[
    Instantiation.DIRECTLY_INSTANTIATED,
    Instantiation.INDIRECTLY_INSTANTIATED,
    Instantiation.ABSTRACTLY_INSTANTIATED,
  ], fixed: true);

  /// Enum set for selecting directly and abstractly instantiated classes in
  /// [ClassHierarchyNode.subclassesByMask],
  /// [ClassHierarchyNode.subclassesByMask] and [ClassSet.subtypesByMask].
  static final EnumSet<Instantiation> EXPLICITLY_INSTANTIATED =
      new EnumSet<Instantiation>.fromValues(const <Instantiation>[
    Instantiation.DIRECTLY_INSTANTIATED,
    Instantiation.ABSTRACTLY_INSTANTIATED
  ], fixed: true);

  /// Enum set for selecting all classes in
  /// [ClassHierarchyNode.subclassesByMask],
  /// [ClassHierarchyNode.subclassesByMask] and [ClassSet.subtypesByMask].
  static final EnumSet<Instantiation> ALL =
      new EnumSet<Instantiation>.fromValues(Instantiation.values, fixed: true);

  /// Creates an enum set for selecting the returned classes in
  /// [ClassHierarchyNode.subclassesByMask],
  /// [ClassHierarchyNode.subclassesByMask] and [ClassSet.subtypesByMask].
  static EnumSet<Instantiation> createMask(
      {bool includeDirectlyInstantiated: true,
      bool includeIndirectlyInstantiated: true,
      bool includeUninstantiated: true,
      bool includeAbstractlyInstantiated: true}) {
    EnumSet<Instantiation> mask = new EnumSet<Instantiation>();
    if (includeDirectlyInstantiated) {
      mask.add(Instantiation.DIRECTLY_INSTANTIATED);
    }
    if (includeIndirectlyInstantiated) {
      mask.add(Instantiation.INDIRECTLY_INSTANTIATED);
    }
    if (includeUninstantiated) {
      mask.add(Instantiation.UNINSTANTIATED);
    }
    if (includeAbstractlyInstantiated) {
      mask.add(Instantiation.ABSTRACTLY_INSTANTIATED);
    }
    return mask;
  }

  final ClassHierarchyNode parentNode;
  final ClassEntity cls;
  final EnumSet<Instantiation> _mask = new EnumSet<Instantiation>.fromValues(
      const <Instantiation>[Instantiation.UNINSTANTIATED]);

  final int hierarchyDepth;

  ClassEntity _leastUpperInstantiatedSubclass;
  int _instantiatedSubclassCount = 0;

  /// `true` if [cls] has been directly instantiated.
  ///
  /// For instance `C` but _not_ `B` in:
  ///   class B {}
  ///   class C extends B {}
  ///   main() => new C();
  ///
  bool get isDirectlyInstantiated =>
      _mask.contains(Instantiation.DIRECTLY_INSTANTIATED);

  void set isDirectlyInstantiated(bool value) {
    if (value != isDirectlyInstantiated) {
      _updateParentInstantiatedSubclassCount(
          Instantiation.DIRECTLY_INSTANTIATED,
          add: value);
    }
  }

  /// `true` if [cls] has been abstractly instantiated. This means that at
  /// runtime instances of [cls] or unknown subclasses of [cls] are assumed to
  /// exist.
  ///
  /// This is used to mark native and/or reflectable classes as instantiated.
  /// For native classes we do not know the exact class that instantiates [cls]
  /// so [cls] here represents the root of the subclasses. For reflectable
  /// classes we need event abstract classes to be 'live' even though they
  /// cannot themselves be instantiated.
  bool get isAbstractlyInstantiated =>
      _mask.contains(Instantiation.ABSTRACTLY_INSTANTIATED);

  void set isAbstractlyInstantiated(bool value) {
    if (value != isAbstractlyInstantiated) {
      _updateParentInstantiatedSubclassCount(
          Instantiation.ABSTRACTLY_INSTANTIATED,
          add: value);
    }
  }

  /// `true` if [cls] is either directly or abstractly instantiated.
  bool get isExplicitlyInstantiated =>
      isDirectlyInstantiated || isAbstractlyInstantiated;

  void _updateParentInstantiatedSubclassCount(Instantiation instantiation,
      {bool add}) {
    ClassHierarchyNode parent = parentNode;
    if (add) {
      _mask.remove(Instantiation.UNINSTANTIATED);
      _mask.add(instantiation);
      while (parent != null) {
        parent._updateInstantiatedSubclassCount(1);
        parent = parent.parentNode;
      }
    } else {
      _mask.remove(instantiation);
      if (_mask.isEmpty) {
        _mask.add(Instantiation.UNINSTANTIATED);
      }
      while (parent != null) {
        parent._updateInstantiatedSubclassCount(-1);
        parent = parent.parentNode;
      }
    }
  }

  /// `true` if [cls] has been instantiated through subclasses.
  ///
  /// For instance `A` and `B` but _not_ `C` in:
  ///   class A {}
  ///   class B extends A {}
  ///   class C extends B {}
  ///   main() => [new B(), new C()];
  ///
  bool get isIndirectlyInstantiated => _instantiatedSubclassCount > 0;

  /// The number of strict subclasses that are directly or indirectly
  /// instantiated.
  int get instantiatedSubclassCount => _instantiatedSubclassCount;

  void _updateInstantiatedSubclassCount(int change) {
    bool before = isIndirectlyInstantiated;
    _instantiatedSubclassCount += change;
    bool after = isIndirectlyInstantiated;
    if (before != after) {
      if (after) {
        _mask.remove(Instantiation.UNINSTANTIATED);
        _mask.add(Instantiation.INDIRECTLY_INSTANTIATED);
      } else {
        _mask.remove(Instantiation.INDIRECTLY_INSTANTIATED);
        if (_mask.isEmpty) {
          _mask.add(Instantiation.UNINSTANTIATED);
        }
      }
    }
  }

  /// The nodes for the direct subclasses of [cls].
  Link<ClassHierarchyNode> _directSubclasses = const Link<ClassHierarchyNode>();

  ClassHierarchyNode(this.parentNode, this.cls, this.hierarchyDepth) {
    if (parentNode != null) {
      parentNode.addDirectSubclass(this);
    }
  }

  /// Adds [subclass] as a direct subclass of [cls].
  void addDirectSubclass(ClassHierarchyNode subclass) {
    assert(!_directSubclasses.contains(subclass));
    _directSubclasses = _directSubclasses.prepend(subclass);
  }

  Iterable<ClassHierarchyNode> get directSubclasses => _directSubclasses;

  /// Returns `true` if [other] is contained in the subtree of this node.
  ///
  /// This means that [other] is a subclass of [cls].
  bool contains(ClassHierarchyNode other) {
    while (other != null) {
      if (cls == other.cls) return true;
      if (hierarchyDepth >= other.hierarchyDepth) return false;
      other = other.parentNode;
    }
    return false;
  }

  /// Returns `true` if `other.cls` is a subclass of [cls].
  bool hasSubclass(ClassHierarchyNode other) {
    return contains(other);
  }

  /// `true` if [cls] has been directly, indirectly, or abstractly instantiated.
  bool get isInstantiated =>
      isExplicitlyInstantiated || isIndirectlyInstantiated;

  /// Returns an [Iterable] of the subclasses of [cls] possibly including [cls].
  ///
  /// Subclasses are included if their instantiation properties intersect with
  /// their corresponding [Instantiation] values in [mask]. If [strict] is
  /// `true`, [cls] itself is _not_ returned.
  Iterable<ClassEntity> subclassesByMask(EnumSet<Instantiation> mask,
      {bool strict: false}) {
    return new ClassHierarchyNodeIterable(this, mask, includeRoot: !strict);
  }

  /// Applies [predicate] to each subclass of [cls] matching the criteria
  /// specified by [mask] and [strict]. If [predicate] returns `true` on a
  /// class, visitation is stopped immediately and the function returns `true`.
  ///
  /// [predicate] is applied to subclasses if their instantiation properties
  /// intersect with their corresponding [Instantiation] values in [mask]. If
  /// [strict] is `true`, [predicate] is _not_ called on [cls] itself.
  bool anySubclass(bool predicate(ClassEntity cls), EnumSet<Instantiation> mask,
      {bool strict: false}) {
    IterationStep wrapper(ClassEntity cls) {
      return predicate(cls) ? IterationStep.STOP : IterationStep.CONTINUE;
    }

    return forEachSubclass(wrapper, mask, strict: strict) == IterationStep.STOP;
  }

  /// Applies [f] to each subclass of [cls] matching the criteria specified by
  /// [mask] and [strict].
  ///
  /// [f] is a applied to subclasses if their instantiation properties intersect
  /// with their corresponding [Instantiation] values in [mask]. If [strict] is
  /// `true`, [f] is _not_ called on [cls] itself.
  ///
  /// The visitation of subclasses can be cut short by the return value of [f].
  /// If [ForEach.STOP] is returned, no further classes are visited and the
  /// function stops immediately. If [ForEach.SKIP_SUBCLASSES] is returned, the
  /// subclasses of the last visited class are skipped, but visitation
  /// continues. The return value of the function is either [ForEach.STOP], if
  /// visitation was stopped, or [ForEach.CONTINUE] if visitation continued to
  /// the end.
  IterationStep forEachSubclass(ForEachFunction f, EnumSet<Instantiation> mask,
      {bool strict: false}) {
    IterationStep nextStep;
    if (!strict && mask.intersects(_mask)) {
      nextStep = f(cls);
    }
    // Interpret `forEach == null` as `forEach == ForEach.CONTINUE`.
    nextStep ??= IterationStep.CONTINUE;

    if (nextStep == IterationStep.CONTINUE) {
      if (mask.contains(Instantiation.UNINSTANTIATED) || isInstantiated) {
        for (ClassHierarchyNode subclass in _directSubclasses) {
          IterationStep subForEach = subclass.forEachSubclass(f, mask);
          if (subForEach == IterationStep.STOP) {
            return subForEach;
          }
        }
      }
    }
    if (nextStep == IterationStep.STOP) {
      return nextStep;
    }
    return IterationStep.CONTINUE;
  }

  /// Returns the most specific subclass of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subclasses. If [cls] is not instantiated, `null` is returned.
  ClassEntity getLubOfInstantiatedSubclasses() {
    if (!isInstantiated) return null;
    if (_leastUpperInstantiatedSubclass == null) {
      _leastUpperInstantiatedSubclass =
          _computeLeastUpperInstantiatedSubclass();
    }
    return _leastUpperInstantiatedSubclass;
  }

  ClassEntity _computeLeastUpperInstantiatedSubclass() {
    if (isExplicitlyInstantiated) {
      return cls;
    }
    if (!isInstantiated) {
      return null;
    }
    ClassHierarchyNode subclass;
    for (Link<ClassHierarchyNode> link = _directSubclasses;
        !link.isEmpty;
        link = link.tail) {
      if (link.head.isInstantiated) {
        if (subclass == null) {
          subclass = link.head;
        } else {
          return cls;
        }
      }
    }
    if (subclass != null) {
      return subclass.getLubOfInstantiatedSubclasses();
    }
    return cls;
  }

  void printOn(StringBuffer sb, String indentation,
      {bool instantiatedOnly: false,
      bool sorted: true,
      ClassElement withRespectTo}) {
    bool isRelatedTo(ClassElement subclass) {
      return subclass == withRespectTo ||
          subclass.implementsInterface(withRespectTo);
    }

    sb.write(indentation);
    if (cls.isAbstract) {
      sb.write('abstract ');
    }
    sb.write('class ${cls.name}:');
    if (isDirectlyInstantiated) {
      sb.write(' directly');
    }
    if (isIndirectlyInstantiated) {
      sb.write(' indirectly');
    }
    if (isAbstractlyInstantiated) {
      sb.write(' abstractly');
    }
    sb.write(' [');
    if (_directSubclasses.isEmpty) {
      sb.write(']');
    } else {
      dynamic subclasses = _directSubclasses;
      if (sorted) {
        subclasses = _directSubclasses.toList()
          ..sort((a, b) {
            return a.cls.name.compareTo(b.cls.name);
          });
      }
      bool needsComma = false;
      for (ClassHierarchyNode child in subclasses) {
        if (instantiatedOnly && !child.isInstantiated) {
          continue;
        }
        if (withRespectTo != null &&
            !child.anySubclass(isRelatedTo, ClassHierarchyNode.ALL)) {
          continue;
        }
        if (needsComma) {
          sb.write(',\n');
        } else {
          sb.write('\n');
        }
        child.printOn(sb, '$indentation  ',
            instantiatedOnly: instantiatedOnly,
            sorted: sorted,
            withRespectTo: withRespectTo);
        needsComma = true;
      }
      if (needsComma) {
        sb.write('\n');
        sb.write('$indentation]');
      } else {
        sb.write(']');
      }
    }
  }

  String dump(
      {String indentation: '',
      bool instantiatedOnly: false,
      ClassElement withRespectTo}) {
    StringBuffer sb = new StringBuffer();
    printOn(sb, indentation,
        instantiatedOnly: instantiatedOnly, withRespectTo: withRespectTo);
    return sb.toString();
  }

  String toString() => cls.toString();
}

/// Object holding the subclass and subtype relation for a single
/// [ClassEntity].
///
/// The subclass relation for a class `C` is modelled through a reference to
/// the [ClassHierarchyNode] for `C` in the global [ClassHierarchyNode] tree
/// computed in [World].
///
/// The subtype relation for a class `C` is modelled through a collection of
/// disjoint [ClassHierarchyNode] subtrees. The subclasses of `C`, modelled
/// through the aforementioned [ClassHierarchyNode] pointer, are extended with
/// the subtypes that do not extend `C` through a list of additional
/// [ClassHierarchyNode] nodes. This list is normalized to contain only the
/// nodes for the topmost subtypes and is furthermore ordered in increasing
/// hierarchy depth order.
///
/// For this class hierarchy:
///
///     class A {}
///     class B extends A {}
///     class C implements B {}
///     class D implements A {}
///     class E extends D {}
///     class F implements D {}
///
/// the [ClassHierarchyNode] tree is
///
///       Object
///      / |  | \
///     A  C  D  F
///     |     |
///     B     E
///
/// and the [ClassSet] for `A` holds these [ClassHierarchyNode] nodes:
///
///      A  ->  [C, D, F]
///
/// The subtypes `B` and `E` are not directly modeled because they are implied
/// by their subclass relation to `A` and `D`, repectively. This can be seen
/// if we expand the subclass subtrees:
///
///      A  ->  [C, D, F]
///      |          |
///      B          E
///
class ClassSet {
  final ClassHierarchyNode node;
  ClassEntity _leastUpperInstantiatedSubtype;

  /// A list of the class hierarchy nodes for the subtypes that declare a
  /// subtype relationship to [cls] either directly or indirectly.
  ///
  /// For instance
  ///
  ///     class A {}
  ///     class B extends A {}
  ///     class C implements B {}
  ///     class D implements A {}
  ///     class E extends D {}
  ///
  /// The class hierarchy nodes for classes `C` and `D` are in [_subtypes]. `C`
  /// because it implements `A` through `B` and `D` because it implements `A`
  /// directly. `E` also implements `A` through its extension of `D` and it is
  /// therefore included through the class hierarchy node for `D`.
  ///
  List<ClassHierarchyNode> _subtypes;

  ClassSet(this.node);

  ClassEntity get cls => node.cls;

  /// Returns `true` if `other.cls` is a subclass of [cls].
  bool hasSubclass(ClassHierarchyNode other) => node.hasSubclass(other);

  /// Returns `true` if `other.cls` is a subtype of [cls].
  bool hasSubtype(ClassHierarchyNode other) {
    if (hasSubclass(other)) return true;
    if (_subtypes != null) {
      for (ClassHierarchyNode subtypeNode in _subtypes) {
        if (subtypeNode.hasSubclass(other)) return true;
      }
    }
    return false;
  }

  /// Returns the number of directly instantiated subtypes of [cls].
  int get instantiatedSubtypeCount {
    int count = node.instantiatedSubclassCount;
    if (_subtypes != null) {
      for (ClassHierarchyNode subtypeNode in _subtypes) {
        if (subtypeNode.isExplicitlyInstantiated) {
          count++;
        }
        count += subtypeNode.instantiatedSubclassCount;
      }
    }
    return count;
  }

  /// Returns `true` if all instantiated subtypes of [cls] are subclasses of
  /// [cls].
  bool get hasOnlyInstantiatedSubclasses {
    if (_subtypes != null) {
      for (ClassHierarchyNode subtypeNode in _subtypes) {
        if (subtypeNode.isInstantiated) {
          return false;
        }
      }
    }
    return true;
  }

  Iterable<ClassHierarchyNode> get subtypeNodes {
    return _subtypes ?? const <ClassHierarchyNode>[];
  }

  /// Returns an [Iterable] of the subclasses of [cls] possibly including [cls].
  ///
  /// Subclasses are included if their instantiation properties intersect with
  /// their corresponding [Instantiation] values in [mask]. If [strict] is
  /// `true`, [cls] itself is _not_ returned.
  Iterable<ClassEntity> subclassesByMask(EnumSet<Instantiation> mask,
      {bool strict: false}) {
    return node.subclassesByMask(mask, strict: strict);
  }

  /// Returns an [Iterable] of the subtypes of [cls] possibly including [cls].
  ///
  /// The directly instantiated, indirectly instantiated and uninstantiated
  /// subtypes of [cls] are returned if [includeDirectlyInstantiated],
  /// [includeIndirectlyInstantiated], and [includeUninstantiated] are `true`,
  /// respectively. If [strict] is `true`, [cls] itself is _not_ returned.
  Iterable<ClassEntity> subtypes(
      {bool includeDirectlyInstantiated: true,
      bool includeIndirectlyInstantiated: true,
      bool includeUninstantiated: true,
      bool strict: false}) {
    EnumSet<Instantiation> mask = ClassHierarchyNode.createMask(
        includeDirectlyInstantiated: includeDirectlyInstantiated,
        includeIndirectlyInstantiated: includeIndirectlyInstantiated,
        includeUninstantiated: includeUninstantiated);
    return subtypesByMask(mask, strict: strict);
  }

  /// Returns an [Iterable] of the subtypes of [cls] possibly including [cls].
  ///
  /// Subtypes are included if their instantiation properties intersect with
  /// their corresponding [Instantiation] values in [mask]. If [strict] is
  /// `true`, [cls] itself is _not_ returned.
  Iterable<ClassEntity> subtypesByMask(EnumSet<Instantiation> mask,
      {bool strict: false}) {
    if (_subtypes == null) {
      return node.subclassesByMask(mask, strict: strict);
    }

    return new SubtypesIterable.SubtypesIterator(this, mask,
        includeRoot: !strict);
  }

  /// Applies [predicate] to each subclass of [cls] matching the criteria
  /// specified by [mask] and [strict]. If [predicate] returns `true` on a
  /// class, visitation is stopped immediately and the function returns `true`.
  ///
  /// [predicate] is applied to subclasses if their instantiation properties
  /// intersect with their corresponding [Instantiation] values in [mask]. If
  /// [strict] is `true`, [predicate] is _not_ called on [cls] itself.
  bool anySubclass(bool predicate(ClassEntity cls), EnumSet<Instantiation> mask,
      {bool strict: false}) {
    return node.anySubclass(predicate, mask, strict: strict);
  }

  /// Applies [f] to each subclass of [cls] matching the criteria specified by
  /// [mask] and [strict].
  ///
  /// [f] is a applied to subclasses if their instantiation properties intersect
  /// with their corresponding [Instantiation] values in [mask]. If [strict] is
  /// `true`, [f] is _not_ called on [cls] itself.
  ///
  /// The visitation of subclasses can be cut short by the return value of [f].
  /// If [ForEach.STOP] is returned, no further classes are visited and the
  /// function stops immediately. If [ForEach.SKIP_SUBCLASSES] is returned, the
  /// subclasses of the last visited class are skipped, but visitation
  /// continues. The return value of the function is either [ForEach.STOP], if
  /// visitation was stopped, or [ForEach.CONTINUE] if visitation continued to
  /// the end.
  IterationStep forEachSubclass(ForEachFunction f, EnumSet<Instantiation> mask,
      {bool strict: false}) {
    return node.forEachSubclass(f, mask, strict: strict);
  }

  /// Applies [predicate] to each subtype of [cls] matching the criteria
  /// specified by [mask] and [strict]. If [predicate] returns `true` on a
  /// class, visitation is stopped immediately and the function returns `true`.
  ///
  /// [predicate] is applied to subtypes if their instantiation properties
  /// intersect with their corresponding [Instantiation] values in [mask]. If
  /// [strict] is `true`, [predicate] is _not_ called on [cls] itself.
  bool anySubtype(bool predicate(ClassEntity cls), EnumSet<Instantiation> mask,
      {bool strict: false}) {
    IterationStep wrapper(ClassEntity cls) {
      return predicate(cls) ? IterationStep.STOP : IterationStep.CONTINUE;
    }

    return forEachSubtype(wrapper, mask, strict: strict) == IterationStep.STOP;
  }

  /// Applies [f] to each subtype of [cls] matching the criteria specified by
  /// [mask] and [strict].
  ///
  /// [f] is a applied to subtypes if their instantiation properties intersect
  /// with their corresponding [Instantiation] values in [mask]. If [strict] is
  /// `true`, [f] is _not_ called on [cls] itself.
  ///
  /// The visitation of subtypes can be cut short by the return value of [f].
  /// If [ForEach.STOP] is returned, no further classes are visited and the
  /// function stops immediately. If [ForEach.SKIP_SUBCLASSES] is returned, the
  /// subclasses of the last visited class are skipped, but visitation
  /// continues. The return value of the function is either [ForEach.STOP], if
  /// visitation was stopped, or [ForEach.CONTINUE] if visitation continued to
  /// the end.
  IterationStep forEachSubtype(ForEachFunction f, EnumSet<Instantiation> mask,
      {bool strict: false}) {
    IterationStep nextStep =
        node.forEachSubclass(f, mask, strict: strict) ?? IterationStep.CONTINUE;
    if (nextStep == IterationStep.CONTINUE && _subtypes != null) {
      for (ClassHierarchyNode subclass in _subtypes) {
        IterationStep subForEach = subclass.forEachSubclass(f, mask);
        if (subForEach == IterationStep.STOP) {
          return subForEach;
        }
      }
    }
    assert(nextStep != IterationStep.SKIP_SUBCLASSES);
    return nextStep;
  }

  /// Adds [subtype] as a subtype of [cls].
  void addSubtype(ClassHierarchyNode subtype) {
    if (node.contains(subtype)) {
      return;
    }
    if (_subtypes == null) {
      _subtypes = <ClassHierarchyNode>[subtype];
    } else {
      int hierarchyDepth = subtype.hierarchyDepth;
      List<ClassHierarchyNode> newSubtypes = <ClassHierarchyNode>[];
      bool added = false;
      for (ClassHierarchyNode otherSubtype in _subtypes) {
        int otherHierarchyDepth = otherSubtype.hierarchyDepth;
        if (hierarchyDepth == otherHierarchyDepth) {
          if (subtype == otherSubtype) {
            return;
          } else {
            // [otherSubtype] is unrelated to [subtype].
            newSubtypes.add(otherSubtype);
          }
        } else if (hierarchyDepth > otherSubtype.hierarchyDepth) {
          // [otherSubtype] could be a superclass of [subtype].
          if (otherSubtype.contains(subtype)) {
            // [subtype] is already in this set.
            return;
          } else {
            // [otherSubtype] is unrelated to [subtype].
            newSubtypes.add(otherSubtype);
          }
        } else {
          if (!added) {
            // Insert [subtype] before other subtypes of higher hierarchy depth.
            newSubtypes.add(subtype);
            added = true;
          }
          // [subtype] could be a superclass of [otherSubtype].
          if (subtype.contains(otherSubtype)) {
            // Replace [otherSubtype].
          } else {
            newSubtypes.add(otherSubtype);
          }
        }
      }
      if (!added) {
        newSubtypes.add(subtype);
      }
      _subtypes = newSubtypes;
    }
  }

  /// Returns the most specific subtype of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subtypes. If no subtypes of [cls] are instantiated, `null` is returned.
  ClassEntity getLubOfInstantiatedSubtypes() {
    if (_leastUpperInstantiatedSubtype == null) {
      _leastUpperInstantiatedSubtype = _computeLeastUpperInstantiatedSubtype();
    }
    return _leastUpperInstantiatedSubtype;
  }

  ClassEntity _computeLeastUpperInstantiatedSubtype() {
    if (node.isExplicitlyInstantiated) {
      return cls;
    }
    if (_subtypes == null) {
      return node.getLubOfInstantiatedSubclasses();
    }
    ClassHierarchyNode subtype;
    if (node.isInstantiated) {
      subtype = node;
    }
    for (ClassHierarchyNode subnode in _subtypes) {
      if (subnode.isInstantiated) {
        if (subtype == null) {
          subtype = subnode;
        } else {
          return cls;
        }
      }
    }
    if (subtype != null) {
      return subtype.getLubOfInstantiatedSubclasses();
    }
    return null;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('[\n');
    node.printOn(sb, '  ');
    sb.write('\n');
    if (_subtypes != null) {
      for (ClassHierarchyNode node in _subtypes) {
        node.printOn(sb, '  ');
        sb.write('\n');
      }
    }
    sb.write(']');
    return sb.toString();
  }
}

/// Iterable for subclasses of a [ClassHierarchyNode].
class ClassHierarchyNodeIterable extends IterableBase<ClassEntity> {
  final ClassHierarchyNode root;
  final EnumSet<Instantiation> mask;
  final bool includeRoot;

  ClassHierarchyNodeIterable(this.root, this.mask, {this.includeRoot: true}) {
    if (root == null) throw new StateError("No root for iterable.");
  }

  @override
  Iterator<ClassEntity> get iterator {
    return new ClassHierarchyNodeIterator(this);
  }
}

/// Iterator for subclasses of a [ClassHierarchyNode].
///
/// Classes are returned in pre-order DFS fashion.
class ClassHierarchyNodeIterator implements Iterator<ClassEntity> {
  final ClassHierarchyNodeIterable iterable;

  /// The class node holding the [current] class.
  ///
  /// This is `null` before the first call to [moveNext] and at the end of
  /// iteration, i.e. after [moveNext] has returned `false`.
  ClassHierarchyNode currentNode;

  /// Stack of pending class nodes.
  ///
  /// This is `null` before the first call to [moveNext].
  Link<ClassHierarchyNode> stack;

  ClassHierarchyNodeIterator(this.iterable);

  ClassHierarchyNode get root => iterable.root;

  bool get includeRoot => iterable.includeRoot;

  EnumSet<Instantiation> get mask => iterable.mask;

  bool get includeUninstantiated {
    return mask.contains(Instantiation.UNINSTANTIATED);
  }

  @override
  ClassEntity get current {
    return currentNode != null ? currentNode.cls : null;
  }

  @override
  bool moveNext() {
    if (stack == null) {
      // First call to moveNext
      stack = const Link<ClassHierarchyNode>().prepend(root);
      return _findNext();
    } else {
      // Initialized state.
      if (currentNode == null) return false;
      return _findNext();
    }
  }

  /// Find the next class using the [stack].
  bool _findNext() {
    while (true) {
      if (stack.isEmpty) {
        // No more classes. Set [currentNode] to `null` to signal the end of
        // iteration.
        currentNode = null;
        return false;
      }
      currentNode = stack.head;
      stack = stack.tail;
      if (!includeUninstantiated && !currentNode.isInstantiated) {
        // We're only iterating instantiated classes so there is no use in
        // visiting the current node and its subtree.
        continue;
      }
      for (Link<ClassHierarchyNode> link = currentNode._directSubclasses;
          !link.isEmpty;
          link = link.tail) {
        stack = stack.prepend(link.head);
      }
      if (_isValid(currentNode)) {
        return true;
      }
    }
  }

  /// Returns `true` if the class of [node] is a valid result for this iterator.
  bool _isValid(ClassHierarchyNode node) {
    if (!includeRoot && node == root) return false;
    return mask.intersects(node._mask);
  }
}

/// Iterable for the subtypes in a [ClassSet].
class SubtypesIterable extends IterableBase<ClassEntity> {
  final ClassSet subtypeSet;
  final EnumSet<Instantiation> mask;
  final bool includeRoot;

  SubtypesIterable.SubtypesIterator(this.subtypeSet, this.mask,
      {this.includeRoot: true});

  @override
  Iterator<ClassEntity> get iterator => new SubtypesIterator(this);
}

/// Iterator for the subtypes in a [ClassSet].
class SubtypesIterator extends Iterator<ClassEntity> {
  final SubtypesIterable iterable;
  Iterator<ClassEntity> elements;
  Iterator<ClassHierarchyNode> hierarchyNodes;

  SubtypesIterator(this.iterable);

  bool get includeRoot => iterable.includeRoot;

  EnumSet<Instantiation> get mask => iterable.mask;

  @override
  ClassEntity get current {
    if (elements != null) {
      return elements.current;
    }
    return null;
  }

  @override
  bool moveNext() {
    if (elements == null && hierarchyNodes == null) {
      // Initial state. Iterate through subclasses.
      elements = iterable.subtypeSet.node
          .subclassesByMask(mask, strict: !includeRoot)
          .iterator;
    }
    if (elements != null && elements.moveNext()) {
      return true;
    }
    if (hierarchyNodes == null) {
      // Start iterating through subtypes.
      hierarchyNodes = iterable.subtypeSet._subtypes.iterator;
    }
    while (hierarchyNodes.moveNext()) {
      elements = hierarchyNodes.current.subclassesByMask(mask).iterator;
      if (elements.moveNext()) {
        return true;
      }
    }
    return false;
  }
}

/// Enum values returned from the [ForEachFunction] provided to the `forEachX`
/// functions of [ClassHierarchyNode] and [ClassSet]. The value is used to
/// control the continued iteration.
enum IterationStep {
  /// Iteration continues.
  CONTINUE,

  /// Iteration stops immediately.
  STOP,

  /// Iteration skips the subclasses of the current class.
  SKIP_SUBCLASSES,
}

/// Visiting function used for the `forEachX` functions of [ClassHierarchyNode]
/// and [ClassSet]. The return value controls the continued iteration. If `null`
/// is returned, iteration continues to the end.
typedef IterationStep ForEachFunction(ClassEntity cls);

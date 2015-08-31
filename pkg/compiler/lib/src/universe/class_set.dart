// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.world.class_set;

import 'dart:collection' show IterableBase;
import '../elements/elements.dart' show ClassElement;
import '../util/util.dart' show Link;

/// Node for [cls] in a tree forming the subclass relation of [ClassElement]s.
///
/// This is used by the [ClassWorld] to perform queries on subclass and subtype
/// relations.
// TODO(johnniwinther): Use this for `ClassWorld.subtypesOf`.
class ClassHierarchyNode {
  final ClassElement cls;

  /// `true` if [cls] has been directly instantiated.
  ///
  /// For instance `C` but _not_ `B` in:
  ///   class B {}
  ///   class C extends B {}
  ///   main() => new C();
  ///
  bool isDirectlyInstantiated = false;

  /// `true` if [cls] has been instantiated through subclasses.
  ///
  /// For instance `A` and `B` but _not_ `C` in:
  ///   class A {}
  ///   class B extends A {}
  ///   class C extends B {}
  ///   main() => [new B(), new C()];
  ///
  bool isIndirectlyInstantiated = false;

  /// The nodes for the direct subclasses of [cls].
  Link<ClassHierarchyNode> _directSubclasses = const Link<ClassHierarchyNode>();

  ClassHierarchyNode(this.cls);

  /// Adds [subclass] as a direct subclass of [cls].
  void addDirectSubclass(ClassHierarchyNode subclass) {
    assert(subclass.cls.superclass == cls);
    assert(!_directSubclasses.contains(subclass));
    _directSubclasses = _directSubclasses.prepend(subclass);
  }

  /// `true` if [cls] has been directly or indirectly instantiated.
  bool get isInstantiated => isDirectlyInstantiated || isIndirectlyInstantiated;

  /// Returns an [Iterable] of the subclasses of [cls] possibly including [cls].
  /// If [directlyInstantiated] is `true`, the iterable only returns the
  /// directly instantiated subclasses of [cls].
  Iterable<ClassElement> subclasses({bool directlyInstantiated: true}) {
    return new ClassHierarchyNodeIterable(
        this, directlyInstantiatedOnly: directlyInstantiated);
  }

  /// Returns an [Iterable] of the strict subclasses of [cls] _not_ including
  /// [cls] itself. If [directlyInstantiated] is `true`, the iterable only
  /// returns the directly instantiated subclasses of [cls].
  Iterable<ClassElement> strictSubclasses(
      {bool directlyInstantiated: true}) {
    return new ClassHierarchyNodeIterable(this,
        includeRoot: false, directlyInstantiatedOnly: directlyInstantiated);
  }

  String toString() => cls.toString();
}

/// Iterable for subclasses of a [ClassHierarchyNode].
class ClassHierarchyNodeIterable extends IterableBase<ClassElement> {
  final ClassHierarchyNode root;
  final bool includeRoot;
  final bool directlyInstantiatedOnly;

  ClassHierarchyNodeIterable(
      this.root,
      {this.includeRoot: true,
       this.directlyInstantiatedOnly: false}) {
    if (root == null) throw new StateError("No root for iterable.");
  }

  @override
  Iterator<ClassElement> get iterator {
    return new ClassHierarchyNodeIterator(this);
  }
}

/// Iterator for subclasses of a [ClassHierarchyNode].
///
/// Classes are returned in pre-order DFS fashion.
class ClassHierarchyNodeIterator implements Iterator<ClassElement> {
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

  bool get directlyInstantiatedOnly => iterable.directlyInstantiatedOnly;

  @override
  ClassElement get current {
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
    if (directlyInstantiatedOnly && !node.isDirectlyInstantiated) return false;
    return true;
  }
}



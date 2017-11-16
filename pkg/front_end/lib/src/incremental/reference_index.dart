// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:kernel/kernel.dart';

/// Information about libraries and nodes that use references.
///
/// This allows us quickly replace one library with another, that has the
/// same API, but provided by different nodes, so different references.
class ReferenceIndex {
  /// The nodes in a library pointing to each reference.
  ///
  /// A key is an indexed library.
  /// Its value is a map.
  ///   A key is a target reference used in the library.
  ///   Its value is the list of nodes in the library that use the reference.
  final Map<Library, Map<Reference, List<Node>>> _libraryReferences = {};

  /// The nodes in the program pointing to each reference.
  ///
  /// A key in the map is a used reference.
  /// Its value is a set of nodes that use this reference.
  final Map<Reference, Set<Node>> _referenceToNodes = {};

  /// Index any libraries of the [program] that are not indexed yet.
  void indexNewLibraries(Program program) {
    for (var library in program.libraries) {
      if (!_libraryReferences.containsKey(library)) {
        _indexLibrary(library);
      }
    }
  }

  /// Remove information about references used in given [library].
  void removeLibrary(Library library) {
    var referencedFromNodes = _libraryReferences.remove(library);
    if (referencedFromNodes != null) {
      referencedFromNodes.forEach((reference, nodes) {
        _referenceToNodes[reference]?.removeAll(nodes);
      });
    }
  }

  /// Remove the [oldLibrary] from the index, index the [newLibrary].  Replace
  /// references to [oldLibrary] node with references to the corresponding
  /// nodes in the [newLibrary].
  ///
  /// Canonical name trees of the [oldLibrary] and [newLibrary] are expected to
  /// be isomorphic.
  void replaceLibrary(Library oldLibrary, Library newLibrary) {
    removeLibrary(oldLibrary);
    _indexLibrary(newLibrary);

    /// Visit in parallel two isomorphic name trees, and replace references.
    void visitNames(CanonicalName oldName, CanonicalName newName) {
      var oldReference = oldName.reference;
      var newReference = newName.reference;
      if (oldReference != null && newReference != null) {
        var nodes = _referenceToNodes.remove(oldReference);
        if (nodes != null) {
          _referenceToNodes[newReference] = nodes;
          var visitor = new _ReplaceVisitor(oldReference, newReference);
          for (var node in nodes) {
            node.accept(visitor);
          }
        }
      }

      // Replace references to children.
      var oldChildren = oldName.children.iterator;
      var newChildren = newName.children.iterator;
      while (oldChildren.moveNext() && newChildren.moveNext()) {
        visitNames(oldChildren.current, newChildren.current);
      }
    }

    visitNames(oldLibrary.canonicalName, newLibrary.canonicalName);
  }

  /// Index the given [library], which is not yet indexed.
  void _indexLibrary(Library library) {
    var referenceToNodes = <Reference, List<Node>>{};
    _libraryReferences[library] = referenceToNodes;
    var visitor = new _IndexVisitor(this, library, referenceToNodes);
    library.accept(visitor);
  }
}

/// Visitor visits a library and records nodes and references they use.
class _IndexVisitor extends RecursiveVisitor {
  final ReferenceIndex index;
  final Library libraryBeingIndexed;
  final Map<Reference, List<Node>> referenceToNodes;

  _IndexVisitor(this.index, this.libraryBeingIndexed, this.referenceToNodes);

  /// Add the given [node] that uses the [reference].
  void addNode(Node node, Reference reference) {
    if (reference == null) return;
    (index._referenceToNodes[reference] ??= new HashSet<Node>()).add(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    addNode(node, node.className);
    super.visitInterfaceType(node);
  }

  @override
  void visitLibrary(Library node) {
    for (var i = 0; i < node.additionalExports.length; i++) {
      addNode(node, node.additionalExports[i]);
    }
    super.visitLibrary(node);
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    addNode(node, node.importedLibraryReference);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    addNode(node, node.interfaceTargetReference);
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    addNode(node, node.interfaceTargetReference);
  }

  @override
  void visitPropertySet(PropertySet node) {
    addNode(node, node.interfaceTargetReference);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitStaticGet(StaticGet node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitStaticSet(StaticSet node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    addNode(node, node.targetReference);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    addNode(node, node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    addNode(node, node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    addNode(node, node.interfaceTargetReference);
  }

  @override
  void visitSupertype(Supertype node) {
    addNode(node, node.className);
  }
}

/// [Visitor] that replaces the [oldReference] with the [newReference] in
/// a single [Node].
class _ReplaceVisitor extends Visitor {
  final Reference oldReference;
  final Reference newReference;

  _ReplaceVisitor(this.oldReference, this.newReference);

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    node.targetReference = newReference;
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    node.targetReference = newReference;
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    node.targetReference = newReference;
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    node.targetReference = newReference;
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    node.className = newReference;
  }

  @override
  void visitLibrary(Library node) {
    for (var i = 0; i < node.additionalExports.length; i++) {
      if (node.additionalExports[i] == oldReference) {
        node.additionalExports[i] = newReference;
        return;
      }
    }
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    node.importedLibraryReference = newReference;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.interfaceTargetReference = newReference;
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    node.interfaceTargetReference = newReference;
  }

  @override
  void visitPropertySet(PropertySet node) {
    node.interfaceTargetReference = newReference;
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    node.targetReference = newReference;
  }

  @override
  void visitStaticGet(StaticGet node) {
    node.targetReference = newReference;
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    node.targetReference = newReference;
  }

  @override
  void visitStaticSet(StaticSet node) {
    node.targetReference = newReference;
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    node.targetReference = newReference;
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.interfaceTargetReference = newReference;
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    node.interfaceTargetReference = newReference;
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    node.interfaceTargetReference = newReference;
  }

  @override
  void visitSupertype(Supertype node) {
    node.className = newReference;
  }
}

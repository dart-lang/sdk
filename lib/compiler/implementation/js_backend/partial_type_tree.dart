// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PartialTypeTree {

  final Compiler compiler;
  PartialTypeTreeNode root;

  PartialTypeTree(this.compiler);

  abstract PartialTypeTreeNode newNode(ClassElement type);

  // TODO(kasperl): Move this to the Selector class?
  ClassElement selectorType(Selector selector) {
    Type type = selector.receiverType;
    return (type !== null) ? type.element : compiler.objectClass;
  }

  /**
   * Finds the tree node corresponding to the given [type]. If [insert]
   * is true, we always return a node that matches the type by
   * inserting a new node if necessary. If [insert] is false, we
   * return null if we cannot find a node that matches the [type].
   */
  PartialTypeTreeNode findNode(ClassElement type, bool insert) {
    if (root === null) {
      if (!insert) return null;
      root = newNode(compiler.objectClass);
    }

    PartialTypeTreeNode current = root;
    L: while (current.type !== type) {
      assert(type.isSubclassOf(current.type));

      // Run through the children. If we find a subtype of the type
      // we are looking for we go that way. If not, we keep track of
      // the subtypes so we can move them from being children of the
      // current node to being children of a new node if we need
      // to insert that.
      Link<PartialTypeTreeNode> subtypes = const EmptyLink();
      for (Link link = current.children; !link.isEmpty(); link = link.tail) {
        PartialTypeTreeNode child = link.head;
        ClassElement childType = child.type;
        if (type.isSubclassOf(childType)) {
          assert(subtypes.isEmpty());
          current = child;
          continue L;
        } else if (childType.isSubclassOf(type)) {
          if (insert) subtypes = subtypes.prepend(child);
        }
      }

      // If we are not inserting any nodes, we are done.
      if (!insert) return null;

      // Create a new node and move the children of the current node
      // that are subtypes of the type of the new node below the new
      // node in the hierarchy.
      PartialTypeTreeNode newNode = newNode(type);
      if (!subtypes.isEmpty()) {
        newNode.children = subtypes;
        Link<PartialTypeTreeNode> remaining = const EmptyLink();
        for (Link link = current.children; !link.isEmpty(); link = link.tail) {
          PartialTypeTreeNode child = link.head;
          if (!child.type.isSubclassOf(type)) {
            remaining = remaining.prepend(child);
          }
        }
        current.children = remaining;
      }

      // Add the new node as a child node of the current node and return it.
      current.children = current.children.prepend(newNode);
      return newNode;
    }

    // We found an exact match. No need to insert new nodes.
    assert(current.type === type);
    return current;
  }

  /**
   * Visits all superclass and subclass nodes for the given [type]. If
   * the [visit] function ever returns false, we abort the traversal.
   */
  void visitHierarchy(ClassElement type, bool visit(PartialTypeTreeNode node)) {
    PartialTypeTreeNode current = root;
    L: while (current.type !== type) {
      assert(type.isSubclassOf(current.type));
      if (!visit(current)) return;
      for (Link link = current.children; !link.isEmpty(); link = link.tail) {
        PartialTypeTreeNode child = link.head;
        ClassElement childType = child.type;
        if (type.isSubclassOf(childType)) {
          current = child;
          continue L;
        } else if (childType.isSubclassOf(type)) {
          if (!child.visitRecursively(visit)) return;
        }
      }
      return;
    }
    current.visitRecursively(visit);
  }

}

class PartialTypeTreeNode {

  final ClassElement type;
  Link<PartialTypeTreeNode> children;

  PartialTypeTreeNode(this.type) : children = const EmptyLink();

  /**
   * Visits this node and its children recursively. If the visit
   * callback ever returns false, the visiting stops early.
   */
  bool visitRecursively(bool visit(PartialTypeTreeNode node)) {
    if (!visit(this)) return false;
    for (Link link = children; !link.isEmpty(); link = link.tail) {
      PartialTypeTreeNode child = link.head;
      if (!child.visitRecursively(visit)) return false;
    }
    return true;
  }

}
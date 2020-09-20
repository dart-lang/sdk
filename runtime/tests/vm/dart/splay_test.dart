// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This benchmark is based on a JavaScript log processing module used
// by the V8 profiler to generate execution time profiles for runs of
// JavaScript applications, and it effectively measures how fast the
// JavaScript engine is at allocating nodes and reclaiming the memory
// used for old nodes. Because of the way splay trees work, the engine
// also has to deal with a lot of changes to the large tree object
// graph.

// VMOptions=
// VMOptions=--no_concurrent_mark --no_concurrent_sweep
// VMOptions=--no_concurrent_mark --concurrent_sweep
// VMOptions=--no_concurrent_mark --use_compactor
// VMOptions=--no_concurrent_mark --use_compactor --force_evacuation
// VMOptions=--concurrent_mark --no_concurrent_sweep
// VMOptions=--concurrent_mark --concurrent_sweep
// VMOptions=--concurrent_mark --use_compactor
// VMOptions=--concurrent_mark --use_compactor --force_evacuation
// VMOptions=--scavenger_tasks=0
// VMOptions=--scavenger_tasks=1
// VMOptions=--scavenger_tasks=2
// VMOptions=--scavenger_tasks=3
// VMOptions=--verify_before_gc
// VMOptions=--verify_after_gc
// VMOptions=--verify_before_gc --verify_after_gc
// VMOptions=--verify_store_buffer
// VMOptions=--stress_write_barrier_elimination
// VMOptions=--old_gen_heap_size=100

import "dart:math";
import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
  Splay.main();
}

class Splay extends BenchmarkBase {
  const Splay() : super("Splay");

  // Configuration.
  static final int kTreeSize = 8000;
  static final int kTreeModifications = 80;
  static final int kTreePayloadDepth = 5;

  static SplayTree? tree;

  static Random rnd = new Random(12345);

  // Insert new node with a unique key.
  static num insertNewNode() {
    num key;
    final localTree = tree!;
    do {
      key = rnd.nextDouble();
    } while (localTree.find(key) != null);
    Payload payload = Payload.generate(kTreePayloadDepth, key.toString());
    localTree.insert(key, payload);
    return key;
  }

  static void mysetup() {
    tree = new SplayTree();
    for (int i = 0; i < kTreeSize; i++) insertNewNode();
  }

  static void tearDown() {
    // Allow the garbage collector to reclaim the memory
    // used by the splay tree no matter how we exit the
    // tear down function.
    List<num> keys = tree!.exportKeys();
    tree = null;

    // Verify that the splay tree has the right size.
    int length = keys.length;
    if (length != kTreeSize) throw new Error("Splay tree has wrong size");

    // Verify that the splay tree has sorted, unique keys.
    for (int i = 0; i < length - 1; i++) {
      if (keys[i] >= keys[i + 1]) throw new Error("Splay tree not sorted");
    }
  }

  void warmup() {
    exercise();
  }

  void exercise() {
    // Replace a few nodes in the splay tree.
    final localTree = tree!;
    for (int i = 0; i < kTreeModifications; i++) {
      num key = insertNewNode();
      Node? greatest = localTree.findGreatestLessThan(key);
      if (greatest == null) {
        localTree.remove(key);
      } else {
        localTree.remove(greatest.key);
      }
    }
  }

  static void main() {
    mysetup();
    new Splay().report();
    tearDown();
  }
}


class Leaf {
  Leaf(String tag) :
    string = "String for key $tag in leaf node",
    array = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
  {}
  String string;
  List<num> array;
}


class Payload {
  Payload(this.left, this.right);
  var left, right;

  static generate(depth, tag) {
    if (depth == 0) return new Leaf(tag);
    return new Payload(generate(depth - 1, tag),
                       generate(depth - 1, tag));
  }
}

class Error implements Exception {
  const Error(this.message);
  final String message;
}


/**
 * A splay tree is a self-balancing binary search tree with the additional
 * property that recently accessed elements are quick to access again.
 * It performs basic operations such as insertion, look-up and removal
 * in O(log(n)) amortized time.
 */
class SplayTree {
  SplayTree();

  /**
   * Inserts a node into the tree with the specified [key] and value if
   * the tree does not already contain a node with the specified key. If
   * the value is inserted, it becomes the root of the tree.
   */
  void insert(num key, value) {
    if (isEmpty) {
      root = new Node(key, value);
      return;
    }
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    splay(key);
    if (root!.key == key) return;
    Node node = new Node(key, value);
    if (key > root!.key) {
      node.left = root;
      node.right = root!.right;
      root!.right = null;
    } else {
      node.right = root;
      node.left = root!.left;
      root!.left = null;
    }
    root = node;
  }

  /**
   * Removes a node with the specified key from the tree if the tree
   * contains a node with this key. The removed node is returned. If
   * [key] is not found, an exception is thrown.
   */
  Node remove(num key) {
    if (isEmpty) throw new Error('Key not found: $key');
    splay(key);
    if (root!.key != key) throw new Error('Key not found: $key');
    Node removed = root!;
    if (root!.left == null) {
      root = root!.right;
    } else {
      Node? right = root!.right;
      root = root!.left;
      // Splay to make sure that the new root has an empty right child.
      splay(key);
      // Insert the original right child as the right child of the new
      // root.
      root!.right = right;
    }
    return removed;
  }

  /**
   * Returns the node having the specified [key] or null if the tree doesn't
   * contain a node with the specified [key].
   */
  Node? find(num key) {
    if (isEmpty) return null;
    splay(key);
    return root!.key == key ? root : null;
  }

  /**
   * Returns the Node having the maximum key value.
   */
  Node? findMax([Node? start]) {
    if (isEmpty) return null;
    Node current = null == start ? root! : start;
    while (current.right != null) current = current.right!;
    return current;
  }

  /**
   * Returns the Node having the maximum key value that
   * is less than the specified [key].
   */
  Node? findGreatestLessThan(num key) {
    if (isEmpty) return null;
    // Splay on the key to move the node with the given key or the last
    // node on the search path to the top of the tree.
    splay(key);
    // Now the result is either the root node or the greatest node in
    // the left subtree.
    if (root!.key < key) return root;
    if (root!.left != null) return findMax(root!.left);
    return null;
  }

  /**
   * Perform the splay operation for the given key. Moves the node with
   * the given key to the top of the tree.  If no node has the given
   * key, the last node on the search path is moved to the top of the
   * tree. This is the simplified top-down splaying algorithm from:
   * "Self-adjusting Binary Search Trees" by Sleator and Tarjan
   */
  void splay(num key) {
    if (isEmpty) return;
    // Create a dummy node.  The use of the dummy node is a bit
    // counter-intuitive: The right child of the dummy node will hold
    // the L tree of the algorithm.  The left child of the dummy node
    // will hold the R tree of the algorithm.  Using a dummy node, left
    // and right will always be nodes and we avoid special cases.
    final Node dummy = new Node(0, null);
    Node left = dummy;
    Node right = dummy;
    Node current = root!;
    while (true) {
      if (key < current.key) {
        if (current.left == null) break;
        if (key < current.left!.key) {
          // Rotate right.
          Node tmp = current.left!;
          current.left = tmp.right;
          tmp.right = current;
          current = tmp;
          if (current.left == null) break;
        }
        // Link right.
        right.left = current;
        right = current;
        current = current.left!;
      } else if (key > current.key) {
        if (current.right == null) break;
        if (key > current.right!.key) {
          // Rotate left.
          Node tmp = current.right!;
          current.right = tmp.left;
          tmp.left = current;
          current = tmp;
          if (current.right == null) break;
        }
        // Link left.
        left.right = current;
        left = current;
        current = current.right!;
      } else {
        break;
      }
    }
    // Assemble.
    left.right = current.left;
    right.left = current.right;
    current.left = dummy.right;
    current.right = dummy.left;
    root = current;
  }

  /**
   * Returns a list with all the keys of the tree.
   */
  List<num> exportKeys() {
    List<num> result = [];
    if (!isEmpty) root!.traverse((Node node) => result.add(node.key));
    return result;
  }

  // Tells whether the tree is empty.
  bool get isEmpty => null == root;

  // Pointer to the root node of the tree.
  Node? root;
}


class Node {
  Node(this.key, this.value);
  final num key;
  final Object? value;

  Node? left, right;

  /**
   * Performs an ordered traversal of the subtree starting here.
   */
  void traverse(void f(Node n)) {
    Node? current = this;
    while (current != null) {
      Node? left = current.left;
      if (left != null) left.traverse(f);
      f(current);
      current = current.right;
    }
  }
}

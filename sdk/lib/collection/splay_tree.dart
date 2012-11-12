// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A node in a splay tree. It holds the key, the value and the left
 * and right children in the tree.
 */
class SplayTreeNode<K, V> {
  SplayTreeNode(K this.key, V this.value);

  K key;
  V value;
  SplayTreeNode<K, V> left;
  SplayTreeNode<K, V> right;
}

/**
 * A splay tree is a self-balancing binary
 * search tree with the additional property that recently accessed
 * elements are quick to access again. It performs basic operations
 * such as insertion, look-up and removal in O(log(n)) amortized time.
 *
 * This implementation is a Dart version of the JavaScript
 * implementation in the V8 project.
 */
class SplayTreeMap<K extends Comparable, V> implements Map<K, V> {

  // The root node of the splay tree. It will contain either the last
  // element inserted, or the last element looked up.
  SplayTreeNode<K, V> _root;

  // The dummy node used when performing a splay on the tree. It is a
  // local field of the class to avoid allocating a node each time a
  // splay is performed.
  SplayTreeNode<K, V> _dummy;

  // Number of elements in the splay tree.
  int _count;

  SplayTreeMap() {
    _dummy = new SplayTreeNode<K, V>(null, null);
    _count = 0;
  }

  /**
   * Perform the splay operation for the given key. Moves the node with
   * the given key to the top of the tree.  If no node has the given
   * key, the last node on the search path is moved to the top of the
   * tree. This is the simplified top-down splaying algorithm from:
   * "Self-adjusting Binary Search Trees" by Sleator and Tarjan.
   */
  void splay_(K key) {
    if (isEmpty) return;

    // The right child of the dummy node will hold
    // the L tree of the algorithm.  The left child of the dummy node
    // will hold the R tree of the algorithm.  Using a dummy node, left
    // and right will always be nodes and we avoid special cases.
    SplayTreeNode<K, V> left = _dummy;
    SplayTreeNode<K, V> right = _dummy;
    SplayTreeNode<K, V> current = _root;
    while (true) {
      int comp = key.compareTo(current.key);
      if (comp < 0) {
        if (current.left == null) break;
        if (key.compareTo(current.left.key) < 0) {
          // Rotate right.
          SplayTreeNode<K, V> tmp = current.left;
          current.left = tmp.right;
          tmp.right = current;
          current = tmp;
          if (current.left == null) break;
        }
        // Link right.
        right.left = current;
        right = current;
        current = current.left;
      } else if (comp > 0) {
        if (current.right == null) break;
        if (key.compareTo(current.right.key) > 0) {
          // Rotate left.
          SplayTreeNode<K, V> tmp = current.right;
          current.right = tmp.left;
          tmp.left = current;
          current = tmp;
          if (current.right == null) break;
        }
        // Link left.
        left.right = current;
        left = current;
        current = current.right;
      } else {
        break;
      }
    }
    // Assemble.
    left.right = current.left;
    right.left = current.right;
    current.left = _dummy.right;
    current.right = _dummy.left;
    _root = current;

    _dummy.right = null;
    _dummy.left = null;
  }

  V operator [](K key) {
    if (!isEmpty) {
      splay_(key);
      if (_root.key.compareTo(key) == 0) return _root.value;
    }
    return null;
  }

  V remove(K key) {
    if (isEmpty) return null;
    splay_(key);
    if (_root.key.compareTo(key) != 0) return null;
    V value = _root.value;

    _count--;
    // assert(_count >= 0);
    if (_root.left == null) {
      _root = _root.right;
    } else {
      SplayTreeNode<K, V> right = _root.right;
      _root = _root.left;
      // Splay to make sure that the new root has an empty right child.
      splay_(key);
      // Insert the original right child as the right child of the new
      // root.
      _root.right = right;
    }
    return value;
  }

  void operator []=(K key, V value) {
    if (isEmpty) {
      _count++;
      _root = new SplayTreeNode(key, value);
      return;
    }
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    splay_(key);
    if (_root.key.compareTo(key) == 0) {
      _root.value = value;
      return;
    }
    SplayTreeNode<K, V> node = new SplayTreeNode(key, value);
    // assert(_count >= 0);
    _count++;
    if (key.compareTo(_root.key) > 0) {
      node.left = _root;
      node.right = _root.right;
      _root.right = null;
    } else {
      node.right = _root;
      node.left = _root.left;
      _root.left = null;
    }
    _root = node;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key];
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  bool get isEmpty {
    // assert(!((_root == null) && (_count != 0)));
    // assert(!((_count == 0) && (_root != null)));
    return (_root == null);
  }

  void forEach(void f(K key, V value)) {
    List<SplayTreeNode<K, V>> list = new List<SplayTreeNode<K, V>>();
    SplayTreeNode<K, V> current = _root;
    while (current != null) {
      if (current.left != null) {
        list.add(current);
        current = current.left;
      } else {
        f(current.key, current.value);
        while (current.right == null) {
          if (list.isEmpty) return;
          current = list.removeLast();
          f(current.key, current.value);
        }
        current = current.right;
      }
    }
  }

  int get length {
    return _count;
  }

  void clear() {
    _root = null;
    _count = 0;
  }

  bool containsKey(K key) {
    if (!isEmpty) {
      splay_(key);
      if (_root.key.compareTo(key) == 0) return true;
    }
    return false;
  }

  bool containsValue(V value) {
    bool found = false;
    bool visit(SplayTreeNode node) {
      if (node == null) return false;
      if (node.value == value) return true;
      return visit(node.left) || visit(node.right);
    }
    return visit(_root);
  }

  Collection<K> get keys {
    List<K> list = new List<K>();
    forEach((K k, V v) { list.add(k); });
    return list;
  }

  Collection<V> get values {
    List<V> list = new List<V>();
    forEach((K k, V v) { list.add(v); });
    return list;
  }

  String toString() {
    return Maps.mapToString(this);
  }

  /**
   * Get the first key in the map. Returns [null] if the map is empty.
   */
  K firstKey() {
    if (_root == null) return null;
    SplayTreeNode<K, V> node = _root;
    while (node.left != null) {
      node = node.left;
    }
    // Maybe implement a splay-method that can splay the minimum without
    // performing comparisons.
    splay_(node.key);
    return node.key;
  }

  /**
   * Get the last key in the map. Returns [null] if the map is empty.
   */
  K lastKey() {
    if (_root == null) return null;
    SplayTreeNode<K, V> node = _root;
    while (node.right != null) {
      node = node.right;
    }
    // Maybe implement a splay-method that can splay the maximum without
    // performing comparisons.
    splay_(node.key);
    return node.key;
  }

  /**
   * Get the last key in the map that is strictly smaller than [key]. Returns
   * [null] if no key was not found.
   */
  K lastKeyBefore(K key) {
    splay_(key);
    K visit(SplayTreeNode node, K ifEmpty) {
      if (node == null) return ifEmpty;
      if (node.key.compareTo(key) >= 0) {
        return visit(node.left, ifEmpty);
      }
      if (node.key.compareTo(key) < 0) {
        return visit(node.right, node.key);
      }
    }
    return visit(_root, null);
  }

  /**
   * Get the first key in the map that is strictly larger than [key]. Returns
   * [null] if no key was not found.
   */
  K firstKeyAfter(K key) {
    splay_(key);
    K visit(SplayTreeNode node, K ifEmpty) {
      if (node == null) return ifEmpty;
      if (node.key.compareTo(key) > 0) {
        return visit(node.left, node.key);
      }
      if (node.key.compareTo(key) <= 0) {
        return visit(node.right, ifEmpty);
      }
    }
    return visit(_root, null);
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * A node in a splay tree. It holds the key, the value and the left
 * and right children in the tree.
 */
class SplayTreeNode<K, V> {
  final K key;
  V value;
  SplayTreeNode<K, V> left;
  SplayTreeNode<K, V> right;

  SplayTreeNode(K this.key, V this.value);
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

  /**
   * Counter incremented whenever the keys in the map changes.
   *
   * Used to detect concurrent modifications.
   */
  int _modificationCount = 0;
  /**
   * Counter incremented whenever the tree structure changes.
   *
   * Used to detect that an in-place traversal cannot use
   * cached information that relies on the tree structure.
   */
  int _splayCount = 0;

  SplayTreeMap() :
    _dummy = new SplayTreeNode<K, V>(null, null),
    _count = 0;

  /**
   * Perform the splay operation for the given key. Moves the node with
   * the given key to the top of the tree.  If no node has the given
   * key, the last node on the search path is moved to the top of the
   * tree. This is the simplified top-down splaying algorithm from:
   * "Self-adjusting Binary Search Trees" by Sleator and Tarjan.
   *
   * Returns the result of comparing the new root of the tree to [key].
   * Returns -1 if the table is empty.
   */
  int _splay(K key) {
    if (_root == null) return -1;

    // The right child of the dummy node will hold
    // the L tree of the algorithm.  The left child of the dummy node
    // will hold the R tree of the algorithm.  Using a dummy node, left
    // and right will always be nodes and we avoid special cases.
    SplayTreeNode<K, V> left = _dummy;
    SplayTreeNode<K, V> right = _dummy;
    SplayTreeNode<K, V> current = _root;
    int comp;
    while (true) {
      comp = current.key.compareTo(key);
      if (comp > 0) {
        if (current.left == null) break;
        comp = current.left.key.compareTo(key);
        if (comp > 0) {
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
      } else if (comp < 0) {
        if (current.right == null) break;
        comp = current.right.key.compareTo(key);
        if (comp < 0) {
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
    _splayCount++;
    return comp;
  }

  V operator [](K key) {
    if (_root != null) {
      int comp = _splay(key);
      if (comp == 0) return _root.value;
    }
    return null;
  }

  V remove(K key) {
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp != 0) return null;
    V value = _root.value;

    _count--;
    // assert(_count >= 0);
    if (_root.left == null) {
      _root = _root.right;
    } else {
      SplayTreeNode<K, V> right = _root.right;
      _root = _root.left;
      // Splay to make sure that the new root has an empty right child.
      _splay(key);
      // Insert the original right child as the right child of the new
      // root.
      _root.right = right;
    }
    _modificationCount++;
    return value;
  }

  void operator []=(K key, V value) {
    if (_root == null) {
      _count++;
      _root = new SplayTreeNode(key, value);
      _modificationCount++;
      return;
    }
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    int comp = _splay(key);
    if (comp == 0) {
      _root.value = value;
      return;
    }
    _addNewRoot(key, value, comp);
  }

  /**
   * Adds a new root node with the given [key] or [value].
   *
   * The [comp] value is the result of comparing the existing root's key
   * with key.
   */
  void _addNewRoot(K key, V value, int comp) {
    SplayTreeNode<K, V> node = new SplayTreeNode(key, value);
    // assert(_count >= 0);
    _count++;
    if (comp < 0) {
      node.left = _root;
      node.right = _root.right;
      _root.right = null;
    } else {
      node.right = _root;
      node.left = _root.left;
      _root.left = null;
    }
    _root = node;
    _modificationCount++;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (_root == null) {
      V value = ifAbsent();
      if (_root != null) {
        throw new ConcurrentModificationError(this);
      }
      _root = new SplayTreeNode(key, value);
      _count++;
      _modificationCount++;
      return value;
    }
    int comp = _splay(key);
    if (comp == 0) return _root.value;
    int modificationCount = _modificationCount;
    int splayCount = _splayCount;
    V value = ifAbsent();
    if (modificationCount != _modificationCount) {
      throw new ConcurrentModificationError(this);
    }
    if (splayCount != _splayCount) {
      comp = _splay(key);
      // Key is still not there, otherwise _modificationCount would be changed.
      assert(comp != 0);
    }
    _addNewRoot(key, value, comp);
    return value;
  }

  bool get isEmpty {
    // assert(!((_root == null) && (_count != 0)));
    // assert(!((_count == 0) && (_root != null)));
    return (_root == null);
  }

  void forEach(void f(K key, V value)) {
    Iterator<SplayTreeNode<K, V>> nodes =
        new _SplayTreeNodeIterator<K, V>(this);
    while (nodes.moveNext()) {
      SplayTreeNode<K, V> node = nodes.current;
      f(node.key, node.value);
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
    return _splay(key) == 0;
  }

  bool containsValue(V value) {
    bool found = false;
    bool visit(SplayTreeNode node) {
      if (node == null) return false;
      if (node.value == value) return true;
      // TODO(lrn): Do we want to handle the case where node.value.operator==
      // modifies the map?
      return visit(node.left) || visit(node.right);
    }
    return visit(_root);
  }

  Iterable<K> get keys => new _SplayTreeKeyIterable(this);

  Iterable<V> get values => new _SplayTreeValueIterable(this);

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
    _splay(node.key);
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
    _splay(node.key);
    return node.key;
  }

  /**
   * Get the last key in the map that is strictly smaller than [key]. Returns
   * [null] if no key was not found.
   */
  K lastKeyBefore(K key) {
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp < 0) return _root.key;
    SplayTreeNode<K, V> node = _root.left;
    if (node == null) return null;
    while (node.right != null) {
      node = node.right;
    }
    return node.key;
  }

  /**
   * Get the first key in the map that is strictly larger than [key]. Returns
   * [null] if no key was not found.
   */
  K firstKeyAfter(K key) {
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp > 0) return _root.key;
    SplayTreeNode<K, V> node = _root.right;
    if (node == null) return null;
    while (node.left != null) {
      node = node.left;
    }
    return node.key;
  }
}

abstract class _SplayTreeIterator<T> implements Iterator<T> {
  final SplayTreeMap _map;
  /**
   * Worklist of nodes to visit.
   *
   * These nodes have been passed over on the way down in a
   * depth-first left-to-right traversal. Visiting each node,
   * and their right subtrees will visit the remainder of
   * the nodes of a full traversal.
   *
   * Only valid as long as the original tree map isn't reordered.
   */
  final List<SplayTreeNode> _workList = <SplayTreeNode>[];

  /**
   * Original modification counter of [_map].
   *
   * Incremented on [_map] when a key is added or removed.
   * If it changes, iteration is aborted.
   */
  final int _modificationCount;

  /**
   * Count of splay operations on [_map] when [_workList] was built.
   *
   * If the splay count on [_map] increases, [_workList] becomes invalid.
   */
  int _splayCount;

  /** Current node. */
  SplayTreeNode _currentNode;

  _SplayTreeIterator(SplayTreeMap map)
      : _map = map,
        _modificationCount = map._modificationCount,
        _splayCount = map._splayCount {
    _findLeftMostDescendent(map._root);
  }

  T get current {
    if (_currentNode == null) return null;
    return _getValue(_currentNode);
  }

  void _findLeftMostDescendent(SplayTreeNode node) {
    while (node != null) {
      _workList.add(node);
      node = node.left;
    }
  }

  /**
   * Called when the tree structure of the map has changed.
   *
   * This can be caused by a splay operation.
   * If the key-set changes, iteration is aborted before getting
   * here, so we know that the keys are the same as before, it's
   * only the tree that has been reordered.
   */
  void _rebuildWorkList(SplayTreeNode currentNode) {
    assert(!_workList.isEmpty);
    _workList.clear();
    if (currentNode == null) {
      _findLeftMostDescendent(_map._root);
    } else {
      _map._splay(currentNode.key);
      _findLeftMostDescendent(_map._root.right);
      assert(!_workList.isEmpty);
    }
  }

  bool moveNext() {
    if (_modificationCount != _map._modificationCount) {
      throw new ConcurrentModificationError(_map);
    }
    // Picks the next element in the worklist as current.
    // Updates the worklist with the left-most path of the current node's
    // right-hand child.
    // If the worklist is no longer valid (after a splay), it is rebuild
    // from scratch.
    if (_workList.isEmpty) {
      _currentNode = null;
      return false;
    }
    if (_map._splayCount != _splayCount) {
      _rebuildWorkList(_currentNode);
    }
    _currentNode = _workList.removeLast();
    _findLeftMostDescendent(_currentNode.right);
    return true;
  }

  T _getValue(SplayTreeNode node);
}


class _SplayTreeKeyIterable<K, V> extends Iterable<K> {
  SplayTreeMap<K, V> _map;
  _SplayTreeKeyIterable(this._map);
  Iterator<K> get iterator => new _SplayTreeKeyIterator<K, V>(_map);
}

class _SplayTreeValueIterable<K, V> extends Iterable<V> {
  SplayTreeMap<K, V> _map;
  _SplayTreeValueIterable(this._map) ;
  Iterator<V> get iterator => new _SplayTreeValueIterator<K, V>(_map);
}

class _SplayTreeKeyIterator<K, V> extends _SplayTreeIterator<K> {
  _SplayTreeKeyIterator(SplayTreeMap<K, V> map): super(map);
  K _getValue(SplayTreeNode node) => node.key;
}

class _SplayTreeValueIterator<K, V> extends _SplayTreeIterator<V> {
  _SplayTreeValueIterator(SplayTreeMap<K, V> map): super(map);
  V _getValue(SplayTreeNode node) => node.value;
}

class _SplayTreeNodeIterator<K, V>
    extends _SplayTreeIterator<SplayTreeNode<K, V>> {
  _SplayTreeNodeIterator(SplayTreeMap<K, V> map): super(map);
  SplayTreeNode<K, V> _getValue(SplayTreeNode node) => node;
}

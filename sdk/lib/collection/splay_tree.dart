// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

typedef bool _Predicate<T>(T value);

/**
 * A node in a splay tree. It holds the sorting key and the left
 * and right children in the tree.
 */
class _SplayTreeNode<K> {
  final K key;
  _SplayTreeNode<K> left;
  _SplayTreeNode<K> right;

  _SplayTreeNode(K this.key);
}

/**
 * A node in a splay tree based map.
 *
 * A [_SplayTreeNode] that also contains a value
 */
class _SplayTreeMapNode<K, V> extends _SplayTreeNode<K> {
  V value;
  _SplayTreeMapNode(K key, V this.value) : super(key);
}

/**
 * A splay tree is a self-balancing binary search tree.
 *
 * It has the additional property that recently accessed elements
 * are quick to access again.
 * It performs basic operations such as insertion, look-up and
 * removal, in O(log(n)) amortized time.
 */
abstract class _SplayTree<K> {
  // The root node of the splay tree. It will contain either the last
  // element inserted or the last element looked up.
  _SplayTreeNode<K> _root;

  // The dummy node used when performing a splay on the tree. Reusing it
  // avoids allocating a node each time a splay is performed.
  _SplayTreeNode<K> _dummy = new _SplayTreeNode<K>(null);

  // Number of elements in the splay tree.
  int _count = 0;

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

  /** Comparison used to compare keys. */
  int _compare(K key1, K key2);

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
    _SplayTreeNode<K> left = _dummy;
    _SplayTreeNode<K> right = _dummy;
    _SplayTreeNode<K> current = _root;
    int comp;
    while (true) {
      comp = _compare(current.key, key);
      if (comp > 0) {
        if (current.left == null) break;
        comp = _compare(current.left.key, key);
        if (comp > 0) {
          // Rotate right.
          _SplayTreeNode<K> tmp = current.left;
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
        comp = _compare(current.right.key, key);
        if (comp < 0) {
          // Rotate left.
          _SplayTreeNode<K> tmp = current.right;
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

  // Emulates splaying with a key that is smaller than any in the tree.
  // After this, the smallest element in the tree is the root.
  void _splayMin() {
    assert(_root != null);
    _SplayTreeNode current = _root;
    while (current.left != null) {
      _SplayTreeNode left = current.left;
      current.left = left.right;
      left.right = current;
      current = left;
    }
    _root = current;
  }

  // Emulates splaying with a key that is greater than any in the tree.
  // After this, the largest element in the tree is the root.
  void _splayMax() {
    assert(_root != null);
    _SplayTreeNode current = _root;
    while (current.right != null) {
      _SplayTreeNode right = current.right;
      current.right = right.left;
      right.left = current;
      current = right;
    }
    _root = current;
  }

  _SplayTreeNode _remove(K key) {
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp != 0) return null;
    _SplayTreeNode result = _root;
    _count--;
    // assert(_count >= 0);
    if (_root.left == null) {
      _root = _root.right;
    } else {
      _SplayTreeNode<K> right = _root.right;
      _root = _root.left;
      // Splay to make sure that the new root has an empty right child.
      _splay(key);
      // Insert the original right child as the right child of the new
      // root.
      _root.right = right;
    }
    _modificationCount++;
    return result;
  }

  /**
   * Adds a new root node with the given [key] or [value].
   *
   * The [comp] value is the result of comparing the existing root's key
   * with key.
   */
  void _addNewRoot(_SplayTreeNode<K> node, int comp) {
    _count++;
    _modificationCount++;
    if (_root == null) {
      _root = node;
      return;
    }
    // assert(_count >= 0);
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
  }

  _SplayTreeNode get _first {
    if (_root == null) return null;
    _splayMin();
    return _root;
  }

  _SplayTreeNode get _last {
    if (_root == null) return null;
    _splayMax();
    return _root;
  }

  void _clear() {
    _root = null;
    _count = 0;
    _modificationCount++;
  }
}

class _TypeTest<T> {
  bool test(v) => v is T;
}

/*
 * A [Map] of objects that can be ordered relative to each other.
 *
 * The map is based on a self-balancing binary tree. It allows most operations
 * in amortized logarithmic time.
 *
 * Keys of the map are compared using the `compare` function passed in
 * the constructor. If that is omitted, the objects are assumed to be
 * [Comparable], and are compared using their [Comparable.compareTo]
 * method. Non-comparable objects (including `null`) will not work as keys
 * in that case.
 *
 * To allow calling [operator[]], [remove] or [containsKey] with objects
 * that are not supported by the `compare` function, an extra `isValidKey`
 * predicate function can be supplied. This function is tested before
 * using the `compare` function on an argument value that may not be a [K]
 * value. If omitted, the `isValidKey` function defaults to testing if the
 * value is a [K].
 */
class SplayTreeMap<K, V> extends _SplayTree<K> implements Map<K, V> {
  Comparator<K> _comparator;
  _Predicate _validKey;

  SplayTreeMap([int compare(K key1, K key2), bool isValidKey(potentialKey)])
      : _comparator = (compare == null) ? Comparable.compare : compare,
        _validKey = (isValidKey != null) ? isValidKey : ((v) => v is K);

  /**
   * Creates a [SplayTreeMap] that contains all key value pairs of [other].
   */
  factory SplayTreeMap.from(Map<K, V> other,
                            [ int compare(K key1, K key2),
                              bool isValidKey(potentialKey)]) =>
      new SplayTreeMap(compare, isValidKey)..addAll(other);

  /**
   * Creates a [SplayTreeMap] where the keys and values are computed from the
   * [iterable].
   *
   * For each element of the [iterable] this constructor computes a key/value
   * pair, by applying [key] and [value] respectively.
   *
   * The keys of the key/value pairs do not need to be unique. The last
   * occurrence of a key will simply overwrite any previous value.
   *
   * If no values are specified for [key] and [value] the default is the
   * identity function.
   */
  factory SplayTreeMap.fromIterable(Iterable<K> iterable,
      {K key(element), V value(element), int compare(K key1, K key2),
       bool isValidKey(potentialKey) }) {
    SplayTreeMap<K, V> map = new SplayTreeMap<K, V>(compare, isValidKey);
    Maps._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /**
   * Creates a [SplayTreeMap] associating the given [keys] to [values].
   *
   * This constructor iterates over [keys] and [values] and maps each element of
   * [keys] to the corresponding element of [values].
   *
   * If [keys] contains the same object multiple times, the last occurrence
   * overwrites the previous value.
   *
   * It is an error if the two [Iterable]s don't have the same length.
   */
  factory SplayTreeMap.fromIterables(Iterable<K> keys, Iterable<V> values,
      [int compare(K key1, K key2), bool isValidKey(potentialKey)]) {
    SplayTreeMap<K, V> map = new SplayTreeMap<K, V>(compare, isValidKey);
    Maps._fillMapWithIterables(map, keys, values);
    return map;
  }

  int _compare(K key1, K key2) => _comparator(key1, key2);

  SplayTreeMap._internal();

  V operator [](Object key) {
    if (key == null) throw new ArgumentError(key);
    if (!_validKey(key)) return null;
    if (_root != null) {
      int comp = _splay(key);
      if (comp == 0) {
        _SplayTreeMapNode mapRoot = _root;
        return mapRoot.value;
      }
    }
    return null;
  }

  V remove(Object key) {
    if (!_validKey(key)) return null;
    _SplayTreeMapNode mapRoot = _remove(key);
    if (mapRoot != null) return mapRoot.value;
    return null;
  }

  void operator []=(K key, V value) {
    if (key == null) throw new ArgumentError(key);
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    int comp = _splay(key);
    if (comp == 0) {
      _SplayTreeMapNode mapRoot = _root;
      mapRoot.value = value;
      return;
    }
    _addNewRoot(new _SplayTreeMapNode(key, value), comp);
  }


  V putIfAbsent(K key, V ifAbsent()) {
    if (key == null) throw new ArgumentError(key);
    int comp = _splay(key);
    if (comp == 0) {
      _SplayTreeMapNode mapRoot = _root;
      return mapRoot.value;
    }
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
    _addNewRoot(new _SplayTreeMapNode(key, value), comp);
    return value;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) { this[key] = value; });
  }

  bool get isEmpty {
    return (_root == null);
  }

  bool get isNotEmpty => !isEmpty;

  void forEach(void f(K key, V value)) {
    Iterator<_SplayTreeNode<K>> nodes =
        new _SplayTreeNodeIterator<K>(this);
    while (nodes.moveNext()) {
      _SplayTreeMapNode<K, V> node = nodes.current;
      f(node.key, node.value);
    }
  }

  int get length {
    return _count;
  }

  void clear() {
    _clear();
  }

  bool containsKey(Object key) {
    return _validKey(key) && _splay(key) == 0;
  }

  bool containsValue(Object value) {
    bool found = false;
    int initialSplayCount = _splayCount;
    bool visit(_SplayTreeMapNode node) {
      while (node != null) {
        if (node.value == value) return true;
        if (initialSplayCount != _splayCount) {
          throw new ConcurrentModificationError(this);
        }
        if (node.right != null && visit(node.right)) return true;
        node = node.left;
      }
      return false;
    }
    return visit(_root);
  }

  Iterable<K> get keys => new _SplayTreeKeyIterable<K>(this);

  Iterable<V> get values => new _SplayTreeValueIterable<K, V>(this);

  String toString() {
    return Maps.mapToString(this);
  }

  /**
   * Get the first key in the map. Returns [null] if the map is empty.
   */
  K firstKey() {
    if (_root == null) return null;
    return _first.key;
  }

  /**
   * Get the last key in the map. Returns [null] if the map is empty.
   */
  K lastKey() {
    if (_root == null) return null;
    return _last.key;
  }

  /**
   * Get the last key in the map that is strictly smaller than [key]. Returns
   * [null] if no key was not found.
   */
  K lastKeyBefore(K key) {
    if (key == null) throw new ArgumentError(key);
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp < 0) return _root.key;
    _SplayTreeNode<K> node = _root.left;
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
    if (key == null) throw new ArgumentError(key);
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp > 0) return _root.key;
    _SplayTreeNode<K> node = _root.right;
    if (node == null) return null;
    while (node.left != null) {
      node = node.left;
    }
    return node.key;
  }
}

abstract class _SplayTreeIterator<T> implements Iterator<T> {
  final _SplayTree _tree;
  /**
   * Worklist of nodes to visit.
   *
   * These nodes have been passed over on the way down in a
   * depth-first left-to-right traversal. Visiting each node,
   * and their right subtrees will visit the remainder of
   * the nodes of a full traversal.
   *
   * Only valid as long as the original tree isn't reordered.
   */
  final List<_SplayTreeNode> _workList = <_SplayTreeNode>[];

  /**
   * Original modification counter of [_tree].
   *
   * Incremented on [_tree] when a key is added or removed.
   * If it changes, iteration is aborted.
   */
  final int _modificationCount;

  /**
   * Count of splay operations on [_tree] when [_workList] was built.
   *
   * If the splay count on [_tree] increases, [_workList] becomes invalid.
   */
  int _splayCount;

  /** Current node. */
  _SplayTreeNode _currentNode;

  _SplayTreeIterator(_SplayTree tree)
      : _tree = tree,
        _modificationCount = tree._modificationCount,
        _splayCount = tree._splayCount {
    _findLeftMostDescendent(tree._root);
  }

  T get current {
    if (_currentNode == null) return null;
    return _getValue(_currentNode);
  }

  void _findLeftMostDescendent(_SplayTreeNode node) {
    while (node != null) {
      _workList.add(node);
      node = node.left;
    }
  }

  /**
   * Called when the tree structure of the tree has changed.
   *
   * This can be caused by a splay operation.
   * If the key-set changes, iteration is aborted before getting
   * here, so we know that the keys are the same as before, it's
   * only the tree that has been reordered.
   */
  void _rebuildWorkList(_SplayTreeNode currentNode) {
    assert(!_workList.isEmpty);
    _workList.clear();
    if (currentNode == null) {
      _findLeftMostDescendent(_tree._root);
    } else {
      _tree._splay(currentNode.key);
      _findLeftMostDescendent(_tree._root.right);
      assert(!_workList.isEmpty);
    }
  }

  bool moveNext() {
    if (_modificationCount != _tree._modificationCount) {
      throw new ConcurrentModificationError(_tree);
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
    if (_tree._splayCount != _splayCount) {
      _rebuildWorkList(_currentNode);
    }
    _currentNode = _workList.removeLast();
    _findLeftMostDescendent(_currentNode.right);
    return true;
  }

  T _getValue(_SplayTreeNode node);
}

class _SplayTreeKeyIterable<K> extends IterableBase<K> {
  _SplayTree<K> _tree;
  _SplayTreeKeyIterable(this._tree);
  int get length => _tree._count;
  bool get isEmpty => _tree._count == 0;
  Iterator<K> get iterator => new _SplayTreeKeyIterator<K>(_tree);
}

class _SplayTreeValueIterable<K, V> extends IterableBase<V> {
  SplayTreeMap<K, V> _map;
  _SplayTreeValueIterable(this._map);
  int get length => _map._count;
  bool get isEmpty => _map._count == 0;
  Iterator<V> get iterator => new _SplayTreeValueIterator<K, V>(_map);
}

class _SplayTreeKeyIterator<K> extends _SplayTreeIterator<K> {
  _SplayTreeKeyIterator(_SplayTree<K> map): super(map);
  K _getValue(_SplayTreeNode node) => node.key;
}

class _SplayTreeValueIterator<K, V> extends _SplayTreeIterator<V> {
  _SplayTreeValueIterator(SplayTreeMap<K, V> map): super(map);
  V _getValue(_SplayTreeMapNode node) => node.value;
}

class _SplayTreeNodeIterator<K>
    extends _SplayTreeIterator<_SplayTreeNode<K>> {
  _SplayTreeNodeIterator(_SplayTree<K> map): super(map);
  _SplayTreeNode<K> _getValue(_SplayTreeNode node) => node;
}

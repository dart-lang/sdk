// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'iterable.dart';

typedef _Predicate<T> = bool Function(T value);

/// A node in a splay tree. It holds the sorting key and the left
/// and right children in the tree.
class _SoundSplayTreeNode<inout K> {
  final K key;
  _SoundSplayTreeNode<K> left;
  _SoundSplayTreeNode<K> right;

  _SoundSplayTreeNode(this.key);
}

/// A node in a splay tree based map.
///
/// A [_SoundSplayTreeNode] that also contains a value
class _SoundSplayTreeMapNode<inout K, inout V> extends _SoundSplayTreeNode<K> {
  V value;
  _SoundSplayTreeMapNode(K key, this.value) : super(key);
}

/// A splay tree is a self-balancing binary search tree.
///
/// It has the additional property that recently accessed elements
/// are quick to access again.
/// It performs basic operations such as insertion, look-up and
/// removal, in O(log(n)) amortized time.
/// TODO(kallentu): Add a variance modifier to the Node type parameter.
abstract class _SoundSplayTree<inout K, Node extends _SoundSplayTreeNode<K>> {
  // The root node of the splay tree. It will contain either the last
  // element inserted or the last element looked up.
  Node get _root;
  set _root(Node newValue);

  // The dummy node used when performing a splay on the tree. Reusing it
  // avoids allocating a node each time a splay is performed.
  Node get _dummy;

  // Number of elements in the splay tree.
  int _count = 0;

  /// Counter incremented whenever the keys in the map changes.
  ///
  /// Used to detect concurrent modifications.
  int _modificationCount = 0;

  /// Counter incremented whenever the tree structure changes.
  ///
  /// Used to detect that an in-place traversal cannot use
  /// cached information that relies on the tree structure.
  int _splayCount = 0;

  /// The comparator that is used for this splay tree.
  Comparator<K> get _comparator;

  /// The predicate to determine that a given object is a valid key.
  _Predicate get _validKey;

  /// Comparison used to compare keys.
  int _compare(K key1, K key2);

  /// Perform the splay operation for the given key. Moves the node with
  /// the given key to the top of the tree.  If no node has the given
  /// key, the last node on the search path is moved to the top of the
  /// tree. This is the simplified top-down splaying algorithm from:
  /// "Self-adjusting Binary Search Trees" by Sleator and Tarjan.
  ///
  /// Returns the result of comparing the new root of the tree to [key].
  /// Returns -1 if the table is empty.
  int _splay(K key) {
    if (_root == null) return -1;

    // The right child of the dummy node will hold
    // the L tree of the algorithm.  The left child of the dummy node
    // will hold the R tree of the algorithm.  Using a dummy node, left
    // and right will always be nodes and we avoid special cases.
    Node left = _dummy;
    Node right = _dummy;
    Node current = _root;
    int comp;
    while (true) {
      comp = _compare(current.key, key);
      if (comp > 0) {
        if (current.left == null) break;
        comp = _compare(current.left.key, key);
        if (comp > 0) {
          // Rotate right.
          _SoundSplayTreeNode<K> tmp = current.left;
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
          Node tmp = current.right;
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

  // Emulates splaying with a key that is smaller than any in the subtree
  // anchored at [node].
  // and that node is returned. It should replace the reference to [node]
  // in any parent tree or root pointer.
  Node _splayMin(Node node) {
    Node current = node;
    while (current.left != null) {
      Node left = current.left;
      current.left = left.right;
      left.right = current;
      current = left;
    }
    return current;
  }

  // Emulates splaying with a key that is greater than any in the subtree
  // anchored at [node].
  // After this, the largest element in the tree is the root of the subtree,
  // and that node is returned. It should replace the reference to [node]
  // in any parent tree or root pointer.
  Node _splayMax(Node node) {
    Node current = node;
    while (current.right != null) {
      Node right = current.right;
      current.right = right.left;
      right.left = current;
      current = right;
    }
    return current;
  }

  Node _remove(K key) {
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp != 0) return null;
    Node result = _root;
    _count--;
    // assert(_count >= 0);
    if (_root.left == null) {
      _root = _root.right;
    } else {
      Node right = _root.right;
      // Splay to make sure that the new root has an empty right child.
      _root = _splayMax(_root.left);
      // Insert the original right child as the right child of the new
      // root.
      _root.right = right;
    }
    _modificationCount++;
    return result;
  }

  /// Adds a new root node with the given [key] or [value].
  ///
  /// The [comp] value is the result of comparing the existing root's key
  /// with key.
  void _addNewRoot(Node node, int comp) {
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

  Node get _first {
    if (_root == null) return null;
    _root = _splayMin(_root);
    return _root;
  }

  Node get _last {
    if (_root == null) return null;
    _root = _splayMax(_root);
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

int _dynamicCompare(dynamic a, dynamic b) => Comparable.compare(a, b);

Comparator<K> _defaultCompare<K>() {
  // If K <: Comparable, then we can just use Comparable.compare
  // with no casts.
  Object compare = Comparable.compare;
  if (compare is Comparator<K>) {
    return compare;
  }
  // Otherwise wrap and cast the arguments on each call.
  return _dynamicCompare;
}

/// A [Map] of objects that can be ordered relative to each other.
///
/// The map is based on a self-balancing binary tree. It allows most operations
/// in amortized logarithmic time.
///
/// Keys of the map are compared using the `compare` function passed in
/// the constructor, both for ordering and for equality.
/// If the map contains only the key `a`, then `map.containsKey(b)`
/// will return `true` if and only if `compare(a, b) == 0`,
/// and the value of `a == b` is not even checked.
/// If the compare function is omitted, the objects are assumed to be
/// [Comparable], and are compared using their [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as keys
/// in that case.
///
/// To allow calling [operator []], [remove] or [containsKey] with objects
/// that are not supported by the `compare` function, an extra `isValidKey`
/// predicate function can be supplied. This function is tested before
/// using the `compare` function on an argument value that may not be a [K]
/// value. If omitted, the `isValidKey` function defaults to testing if the
/// value is a [K].
class SoundSplayTreeMap<inout K, inout V> extends _SoundSplayTree<K, _SoundSplayTreeMapNode<K, V>>
    with MapMixin<K, V> {
  _SoundSplayTreeMapNode<K, V> _root;
  final _SoundSplayTreeMapNode<K, V> _dummy = _SoundSplayTreeMapNode<K, V>(null, null);

  Comparator<K> _comparator;
  _Predicate _validKey;

  SoundSplayTreeMap([int compare(K key1, K key2), bool isValidKey(potentialKey)])
      : _comparator = compare ?? _defaultCompare<K>(),
        _validKey = isValidKey ?? ((v) => v is K);

  /// Creates a [SoundSplayTreeMap] that contains all key/value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  factory SoundSplayTreeMap.from(Map other,
      [int compare(K key1, K key2), bool isValidKey(potentialKey)]) {
    SoundSplayTreeMap<K, V> result = SoundSplayTreeMap<K, V>(compare, isValidKey);
    other.forEach((k, v) {
      result[k] = v;
    });
    return result;
  }

  /// Creates a [SoundSplayTreeMap] that contains all key/value pairs of [other].
  factory SoundSplayTreeMap.of(Map<K, V> other,
          [int compare(K key1, K key2), bool isValidKey(potentialKey)]) =>
      SoundSplayTreeMap<K, V>(compare, isValidKey)..addAll(other);

  /// Creates a [SoundSplayTreeMap] where the keys and values are computed from the
  /// [iterable].
  ///
  /// For each element of the [iterable] this constructor computes a key/value
  /// pair, by applying [key] and [value] respectively.
  ///
  /// The keys of the key/value pairs do not need to be unique. The last
  /// occurrence of a key will simply overwrite any previous value.
  ///
  /// If no functions are specified for [key] and [value] the default is to
  /// use the iterable value itself.
  factory SoundSplayTreeMap.fromIterable(Iterable iterable,
      {K key(element),
      V value(element),
      int compare(K key1, K key2),
      bool isValidKey(potentialKey)}) {
    SoundSplayTreeMap<K, V> map = SoundSplayTreeMap<K, V>(compare, isValidKey);
    fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  static _id(x) => x;

  static void fillMapWithMappedIterable(
      Map map, Iterable iterable, key(element), value(element)) {
    key ??= _id;
    value ??= _id;

    for (var element in iterable) {
      map[key(element)] = value(element);
    }
  }

  static void fillMapWithIterables(Map map, Iterable keys, Iterable values) {
    Iterator keyIterator = keys.iterator;
    Iterator valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw ArgumentError("Iterables do not have same length.");
    }
  }

  /// Creates a [SoundSplayTreeMap] associating the given [keys] to [values].
  ///
  /// This constructor iterates over [keys] and [values] and maps each element
  /// of [keys] to the corresponding element of [values].
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// It is an error if the two [Iterable]s don't have the same length.
  factory SoundSplayTreeMap.fromIterables(Iterable<K> keys, Iterable<V> values,
      [int compare(K key1, K key2), bool isValidKey(potentialKey)]) {
    SoundSplayTreeMap<K, V> map = SoundSplayTreeMap<K, V>(compare, isValidKey);
    fillMapWithIterables(map, keys, values);
    return map;
  }

  int _compare(K key1, K key2) => _comparator(key1, key2);

  SoundSplayTreeMap._internal();

  V operator [](Object key) {
    if (!_validKey(key)) return null;
    if (_root != null) {
      int comp = _splay(key);
      if (comp == 0) {
        return _root.value;
      }
    }
    return null;
  }

  V remove(Object key) {
    if (!_validKey(key)) return null;
    _SoundSplayTreeMapNode<K, V> mapRoot = _remove(key);
    if (mapRoot != null) return mapRoot.value;
    return null;
  }

  void operator []=(K key, V value) {
    if (key == null) throw ArgumentError(key);
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    int comp = _splay(key);
    if (comp == 0) {
      _root.value = value;
      return;
    }
    _addNewRoot(_SoundSplayTreeMapNode(key, value), comp);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (key == null) throw ArgumentError(key);
    int comp = _splay(key);
    if (comp == 0) {
      return _root.value;
    }
    int modificationCount = _modificationCount;
    int splayCount = _splayCount;
    V value = ifAbsent();
    if (modificationCount != _modificationCount) {
      throw ConcurrentModificationError(this);
    }
    if (splayCount != _splayCount) {
      comp = _splay(key);
      // Key is still not there, otherwise _modificationCount would be changed.
      assert(comp != 0);
    }
    _addNewRoot(_SoundSplayTreeMapNode(key, value), comp);
    return value;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  bool get isEmpty {
    return (_root == null);
  }

  bool get isNotEmpty => !isEmpty;

  void forEach(void f(K key, V value)) {
    Iterator<_SoundSplayTreeNode<K>> nodes = _SoundSplayTreeNodeIterator<K>(this);
    while (nodes.moveNext()) {
      _SoundSplayTreeMapNode<K, V> node = nodes.current;
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
    int initialSplayCount = _splayCount;
    bool visit(_SoundSplayTreeMapNode<K, V> node) {
      while (node != null) {
        if (node.value == value) return true;
        if (initialSplayCount != _splayCount) {
          throw ConcurrentModificationError(this);
        }
        if (node.right != null && visit(node.right)) return true;
        node = node.left;
      }
      return false;
    }

    return visit(_root);
  }

  Iterable<K> get keys => _SoundSplayTreeKeyIterable<K>(this);

  Iterable<V> get values => _SoundSplayTreeValueIterable<K, V>(this);

  /// Get the first key in the map. Returns [:null:] if the map is empty.
  K firstKey() {
    if (_root == null) return null;
    return _first.key;
  }

  /// Get the last key in the map. Returns [:null:] if the map is empty.
  K lastKey() {
    if (_root == null) return null;
    return _last.key;
  }

  /// Get the last key in the map that is strictly smaller than [key]. Returns
  /// [:null:] if no key was not found.
  K lastKeyBefore(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp < 0) return _root.key;
    _SoundSplayTreeNode<K> node = _root.left;
    if (node == null) return null;
    while (node.right != null) {
      node = node.right;
    }
    return node.key;
  }

  /// Get the first key in the map that is strictly larger than [key]. Returns
  /// [:null:] if no key was not found.
  K firstKeyAfter(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp > 0) return _root.key;
    _SoundSplayTreeNode<K> node = _root.right;
    if (node == null) return null;
    while (node.left != null) {
      node = node.left;
    }
    return node.key;
  }
}


abstract class _SoundSplayTreeIterator<inout K, inout T> implements Iterator<T> {
  final _SoundSplayTree<K, _SoundSplayTreeNode<K>> _tree;

  /// Worklist of nodes to visit.
  ///
  /// These nodes have been passed over on the way down in a
  /// depth-first left-to-right traversal. Visiting each node,
  /// and their right subtrees will visit the remainder of
  /// the nodes of a full traversal.
  ///
  /// Only valid as long as the original tree isn't reordered.
  final List<_SoundSplayTreeNode<K>> _workList = <_SoundSplayTreeNode<K>>[];

  /// Original modification counter of [_tree].
  ///
  /// Incremented on [_tree] when a key is added or removed.
  /// If it changes, iteration is aborted.
  ///
  /// Not final because some iterators may modify the tree knowingly,
  /// and they update the modification count in that case.
  int _modificationCount;

  /// Count of splay operations on [_tree] when [_workList] was built.
  ///
  /// If the splay count on [_tree] increases, [_workList] becomes invalid.
  int _splayCount;

  /// Current node.
  _SoundSplayTreeNode<K> _currentNode;

  _SoundSplayTreeIterator(_SoundSplayTree<K, _SoundSplayTreeNode<K>> tree)
      : _tree = tree,
        _modificationCount = tree._modificationCount,
        _splayCount = tree._splayCount {
    _findLeftMostDescendent(tree._root);
  }

  _SoundSplayTreeIterator.startAt(_SoundSplayTree<K, _SoundSplayTreeNode<K>> tree, K startKey)
      : _tree = tree,
        _modificationCount = tree._modificationCount {
    if (tree._root == null) return;
    int compare = tree._splay(startKey);
    _splayCount = tree._splayCount;
    if (compare < 0) {
      // Don't include the root, start at the next element after the root.
      _findLeftMostDescendent(tree._root.right);
    } else {
      _workList.add(tree._root);
    }
  }

  T get current {
    if (_currentNode == null) return null;
    return _getValue(_currentNode);
  }

  void _findLeftMostDescendent(_SoundSplayTreeNode<K> node) {
    while (node != null) {
      _workList.add(node);
      node = node.left;
    }
  }

  /// Called when the tree structure of the tree has changed.
  ///
  /// This can be caused by a splay operation.
  /// If the key-set changes, iteration is aborted before getting
  /// here, so we know that the keys are the same as before, it's
  /// only the tree that has been reordered.
  void _rebuildWorkList(_SoundSplayTreeNode<K> currentNode) {
    assert(_workList.isNotEmpty);
    _workList.clear();
    if (currentNode == null) {
      _findLeftMostDescendent(_tree._root);
    } else {
      _tree._splay(currentNode.key);
      _findLeftMostDescendent(_tree._root.right);
      assert(_workList.isNotEmpty);
    }
  }

  bool moveNext() {
    if (_modificationCount != _tree._modificationCount) {
      throw ConcurrentModificationError(_tree);
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
    if (_tree._splayCount != _splayCount && _currentNode != null) {
      _rebuildWorkList(_currentNode);
    }
    _currentNode = _workList.removeLast();
    _findLeftMostDescendent(_currentNode.right);
    return true;
  }

  T _getValue(_SoundSplayTreeNode<K> node);
}

class _SoundSplayTreeKeyIterable<inout K> extends EfficientLengthIterable<K> {
  _SoundSplayTree<K, _SoundSplayTreeNode<K>> _tree;
  _SoundSplayTreeKeyIterable(this._tree);
  int get length => _tree._count;
  bool get isEmpty => _tree._count == 0;
  Iterator<K> get iterator => _SoundSplayTreeKeyIterator<K>(_tree);

  Set<K> toSet() {
    SoundSplayTreeSet<K> set = SoundSplayTreeSet<K>(_tree._comparator, _tree._validKey);
    set._count = _tree._count;
    set._root = set._copyNode(_tree._root);
    return set;
  }
}

class _SoundSplayTreeValueIterable<inout K, inout V> extends EfficientLengthIterable<V> {
  SoundSplayTreeMap<K, V> _map;
  _SoundSplayTreeValueIterable(this._map);
  int get length => _map._count;
  bool get isEmpty => _map._count == 0;
  Iterator<V> get iterator => _SoundSplayTreeValueIterator<K, V>(_map);
}

class _SoundSplayTreeKeyIterator<inout K> extends _SoundSplayTreeIterator<K, K> {
  _SoundSplayTreeKeyIterator(_SoundSplayTree<K, _SoundSplayTreeNode<K>> map) : super(map);
  K _getValue(_SoundSplayTreeNode<K> node) => node.key;
}

class _SoundSplayTreeValueIterator<inout K, inout V> extends _SoundSplayTreeIterator<K, V> {
  _SoundSplayTreeValueIterator(SoundSplayTreeMap<K, V> map) : super(map);
  V _getValue(_SoundSplayTreeNode<K> node) {
    _SoundSplayTreeMapNode<K, V> mapNode = node;
    return mapNode.value;
  }
}

class _SoundSplayTreeNodeIterator<inout K>
    extends _SoundSplayTreeIterator<K, _SoundSplayTreeNode<K>> {
  _SoundSplayTreeNodeIterator(_SoundSplayTree<K, _SoundSplayTreeNode<K>> tree) : super(tree);
  _SoundSplayTreeNodeIterator.startAt(
      _SoundSplayTree<K, _SoundSplayTreeNode<K>> tree, K startKey)
      : super.startAt(tree, startKey);
  _SoundSplayTreeNode<K> _getValue(_SoundSplayTreeNode<K> node) => node;
}

/// A [Set] of objects that can be ordered relative to each other.
///
/// The set is based on a self-balancing binary tree. It allows most operations
/// in amortized logarithmic time.
///
/// Elements of the set are compared using the `compare` function passed in
/// the constructor, both for ordering and for equality.
/// If the set contains only an object `a`, then `set.contains(b)`
/// will return `true` if and only if `compare(a, b) == 0`,
/// and the value of `a == b` is not even checked.
/// If the compare function is omitted, the objects are assumed to be
/// [Comparable], and are compared using their [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as an element
/// in that case.
class SoundSplayTreeSet<inout E> extends _SoundSplayTree<E, _SoundSplayTreeNode<E>>
    with IterableMixin<E>, SetMixin<E> {
  _SoundSplayTreeNode<E> _root;
  final _SoundSplayTreeNode<E> _dummy = _SoundSplayTreeNode<E>(null);

  Comparator<E> _comparator;
  _Predicate _validKey;

  /// Create a new [SoundSplayTreeSet] with the given compare function.
  ///
  /// If the [compare] function is omitted, it defaults to [Comparable.compare],
  /// and the elements must be comparable.
  ///
  /// A provided `compare` function may not work on all objects. It may not even
  /// work on all `E` instances.
  ///
  /// For operations that add elements to the set, the user is supposed to not
  /// pass in objects that doesn't work with the compare function.
  ///
  /// The methods [contains], [remove], [lookup], [removeAll] or [retainAll]
  /// are typed to accept any object(s), and the [isValidKey] test can used to
  /// filter those objects before handing them to the `compare` function.
  ///
  /// If [isValidKey] is provided, only values satisfying `isValidKey(other)`
  /// are compared using the `compare` method in the methods mentioned above.
  /// If the `isValidKey` function returns false for an object, it is assumed to
  /// not be in the set.
  ///
  /// If omitted, the `isValidKey` function defaults to checking against the
  /// type parameter: `other is E`.
  SoundSplayTreeSet([int compare(E key1, E key2), bool isValidKey(potentialKey)])
      : _comparator = compare ?? _defaultCompare<E>(),
        _validKey = isValidKey ?? ((v) => v is E);

  /// Creates a [SoundSplayTreeSet] that contains all [elements].
  ///
  /// The set works as if created by `new SplayTreeSet<E>(compare, isValidKey)`.
  ///
  /// All the [elements] should be instances of [E] and valid arguments to
  /// [compare].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     new SplayTreeSet<SubType>.from(superSet.whereType<SubType>());
  /// ```
  factory SoundSplayTreeSet.from(Iterable elements,
      [int compare(E key1, E key2), bool isValidKey(potentialKey)]) {
    SoundSplayTreeSet<E> result = SoundSplayTreeSet<E>(compare, isValidKey);
    for (final element in elements) {
      E e = element;
      result.add(e);
    }
    return result;
  }

  /// Creates a [SoundSplayTreeSet] from [elements].
  ///
  /// The set works as if created by `new SplayTreeSet<E>(compare, isValidKey)`.
  ///
  /// All the [elements] should be valid as arguments to the [compare] function.
  factory SoundSplayTreeSet.of(Iterable<E> elements,
          [int compare(E key1, E key2), bool isValidKey(potentialKey)]) =>
      SoundSplayTreeSet(compare, isValidKey)..addAll(elements);

  Set<T> _newSet<T>() =>
      SoundSplayTreeSet<T>((T a, T b) => _comparator(a as E, b as E), _validKey);

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newSet);
  int _compare(E e1, E e2) => _comparator(e1, e2);

  // From Iterable.

  Iterator<E> get iterator => _SoundSplayTreeKeyIterator<E>(this);

  int get length => _count;
  bool get isEmpty => _root == null;
  bool get isNotEmpty => _root != null;

  E get first {
    if (_count == 0) throw IterableElementError.noElement();
    return _first.key;
  }

  E get last {
    if (_count == 0) throw IterableElementError.noElement();
    return _last.key;
  }

  E get single {
    if (_count == 0) throw IterableElementError.noElement();
    if (_count > 1) throw IterableElementError.tooMany();
    return _root.key;
  }

  // From Set.
  bool contains(Object element) {
    return _validKey(element) && _splay(element) == 0;
  }

  bool add(E element) {
    int compare = _splay(element);
    if (compare == 0) return false;
    _addNewRoot(_SoundSplayTreeNode(element), compare);
    return true;
  }

  bool remove(Object object) {
    if (!_validKey(object)) return false;
    return _remove(object) != null;
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      int compare = _splay(element);
      if (compare != 0) {
        _addNewRoot(_SoundSplayTreeNode(element), compare);
      }
    }
  }

  void removeAll(Iterable<Object> elements) {
    for (Object element in elements) {
      if (_validKey(element)) _remove(element);
    }
  }

  void retainAll(Iterable<Object> elements) {
    // Build a set with the same sense of equality as this set.
    SoundSplayTreeSet<E> retainSet = SoundSplayTreeSet<E>(_comparator, _validKey);
    int modificationCount = _modificationCount;
    for (Object object in elements) {
      if (modificationCount != _modificationCount) {
        // The iterator should not have side effects.
        throw ConcurrentModificationError(this);
      }
      // Equivalent to this.contains(object).
      if (_validKey(object) && _splay(object) == 0) {
        retainSet.add(_root.key);
      }
    }
    // Take over the elements from the retained set, if it differs.
    if (retainSet._count != _count) {
      _root = retainSet._root;
      _count = retainSet._count;
      _modificationCount++;
    }
  }

  E lookup(Object object) {
    if (!_validKey(object)) return null;
    int comp = _splay(object);
    if (comp != 0) return null;
    return _root.key;
  }

  Set<E> intersection(Set<Object> other) {
    Set<E> result = SoundSplayTreeSet<E>(_comparator, _validKey);
    for (E element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> difference(Set<Object> other) {
    Set<E> result = SoundSplayTreeSet<E>(_comparator, _validKey);
    for (E element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> union(Set<E> other) {
    return _clone()..addAll(other);
  }

  SoundSplayTreeSet<E> _clone() {
    var set = SoundSplayTreeSet<E>(_comparator, _validKey);
    set._count = _count;
    set._root = _copyNode(_root);
    return set;
  }

  // Copies the structure of a SplayTree into a new similar structure.
  // Works on _SplayTreeMapNode as well, but only copies the keys,
  _SoundSplayTreeNode<E> _copyNode(_SoundSplayTreeNode<E> node) {
    if (node == null) return null;
    return _SoundSplayTreeNode<E>(node.key)
      ..left = _copyNode(node.left)
      ..right = _copyNode(node.right);
  }

  void clear() {
    _clear();
  }

  Set<E> toSet() => _clone();

  String toString() => IterableBase.iterableToFullString(this, '{', '}');
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index.b_plus_tree;

import 'dart:collection';


/**
 * A simple B+ tree (http://en.wikipedia.org/wiki/B+_tree) implementation.
 *
 * [K] is the keys type.
 * [V] is the values type.
 * [N] is the type of node identifiers using by the [NodeManager].
 */
class BPlusTree<K, V, N> {
  /**
   * The [Comparator] to compare keys.
   */
  final Comparator<K> _comparator;

  /**
   * The [NodeManager] to manage nodes.
   */
  final NodeManager<K, V, N> _manager;

  /**
   * The maximum number of keys in an index node.
   */
  final int _maxIndexKeys;

  /**
   * The maximum number of keys in a leaf node.
   */
  final int _maxLeafKeys;

  /**
   * The root node.
   */
  _Node<K, V, N> _root;

  /**
   * Creates a new [BPlusTree] instance.
   */
  BPlusTree(this._comparator, NodeManager<K, V, N> manager)
      : _manager = manager,
        _maxIndexKeys = manager.maxIndexKeys,
        _maxLeafKeys = manager.maxLeafKeys {
    _root = _newLeafNode();
    _writeLeafNode(_root);
  }

  /**
   * Returns the value for [key] or `null` if [key] is not in the tree.
   */
  V find(K key) {
    return _root.find(key);
  }

  /**
   * Associates the [key] with the given [value].
   *
   * If the key was already in the tree, its associated value is changed.
   * Otherwise the key-value pair is added to the tree.
   */
  void insert(K key, V value) {
    _Split<K, N> result = _root.insert(key, value);
    if (result != null) {
      _IndexNode<K, V, N> newRoot = _newIndexNode();
      newRoot.keys.add(result.key);
      newRoot.children.add(result.left);
      newRoot.children.add(result.right);
      _root = newRoot;
      _writeIndexNode(_root);
    }
  }

  /**
   * Removes the association for the given [key].
   *
   * Returns the value associated with [key] in the tree or `null` if [key] is
   * not in the tree.
   */
  V remove(K key) {
    _Remove<K, V> result = _root.remove(key, null, null, null);
    if (_root is _IndexNode<K, V, N>) {
      List<N> children = (_root as _IndexNode<K, V, N>).children;
      if (children.length == 1) {
        _manager.delete(_root.id);
        _root = _readNode(children[0]);
      }
    }
    return result.value;
  }

  /**
   * Writes a textual presentation of the tree into [buffer].
   */
  void writeOn(StringBuffer buffer) {
    _root.writeOn(buffer, '');
  }

  /**
   * Creates a new [_IndexNode] instance.
   */
  _IndexNode<K, V, N> _newIndexNode() {
    N id = _manager.createIndex();
    return new _IndexNode<K, V, N>(this, id, _maxIndexKeys);
  }

  /**
   * Creates a new [_LeafNode] instance.
   */
  _LeafNode<K, V, N> _newLeafNode() {
    N id = _manager.createLeaf();
    return new _LeafNode<K, V, N>(this, id, _maxLeafKeys);
  }

  /**
   * Reads the [_IndexNode] with [id] from the manager.
   */
  _IndexNode<K, V, N> _readIndexNode(N id) {
    IndexNodeData<K, N> data = _manager.readIndex(id);
    _IndexNode<K, V, N> node = new _IndexNode<K, V, N>(this, id, _maxIndexKeys);
    node.keys = data.keys;
    node.children = data.children;
    return node;
  }

  /**
   * Reads the [_LeafNode] with [id] from the manager.
   */
  _LeafNode<K, V, N> _readLeafNode(N id) {
    _LeafNode<K, V, N> node = new _LeafNode<K, V, N>(this, id, _maxLeafKeys);
    LeafNodeData<K, V> data = _manager.readLeaf(id);
    node.keys = data.keys;
    node.values = data.values;
    return node;
  }

  /**
   * Reads the [_IndexNode] or [_LeafNode] with [id] from the manager.
   */
  _Node<K, V, N> _readNode(N id) {
    if (_manager.isIndex(id)) {
      return _readIndexNode(id);
    } else {
      return _readLeafNode(id);
    }
  }

  /**
   * Writes [node] into the manager.
   */
  void _writeIndexNode(_IndexNode<K, V, N> node) {
    _manager.writeIndex(node.id, new IndexNodeData<K, N>(node.keys, node.children));
  }

  /**
   * Writes [node] into the manager.
   */
  void _writeLeafNode(_LeafNode<K, V, N> node) {
    _manager.writeLeaf(node.id, new LeafNodeData<K, V>(node.keys, node.values));
  }
}


/**
 * A container with information about an index node.
 */
class IndexNodeData<K, N> {
  final List<N> children;
  final List<K> keys;
  IndexNodeData(this.keys, this.children);
}


/**
 * A container with information about a leaf node.
 */
class LeafNodeData<K, V> {
  final List<K> keys;
  final List<V> values;
  LeafNodeData(this.keys, this.values);
}


/**
 * An implementation of [NodeManager] that keeps node information in memory.
 */
class MemoryNodeManager<K, V> implements NodeManager<K, V, int> {
  final int maxIndexKeys;
  final int maxLeafKeys;
  Map<int, IndexNodeData> _indexDataMap = new HashMap<int, IndexNodeData>();
  Map<int, LeafNodeData> _leafDataMap = new HashMap<int, LeafNodeData>();

  int _nextPageIndexId = 0;
  int _nextPageLeafId = 1;

  MemoryNodeManager(this.maxIndexKeys, this.maxLeafKeys);

  @override
  int createIndex() {
    int id = _nextPageIndexId;
    _nextPageIndexId += 2;
    return id;
  }

  @override
  int createLeaf() {
    int id = _nextPageLeafId;
    _nextPageLeafId += 2;
    return id;
  }

  @override
  void delete(int id) {
    if (isIndex(id)) {
      _indexDataMap.remove(id);
    } else {
      _leafDataMap.remove(id);
    }
  }

  @override
  bool isIndex(int id) {
    return id.isEven;
  }

  @override
  IndexNodeData<K, int> readIndex(int id) {
    return _indexDataMap[id];
  }

  @override
  LeafNodeData<K, V> readLeaf(int id) {
    return _leafDataMap[id];
  }

  @override
  void writeIndex(int id, IndexNodeData<K, int> data) {
    _indexDataMap[id] = data;
  }

  @override
  void writeLeaf(int id, LeafNodeData<K, V> data) {
    _leafDataMap[id] = data;
  }
}


/**
 * A manager that manages nodes.
 */
abstract class NodeManager<K, V, N> {
  /**
   * The maximum number of keys in an index node.
   */
  int get maxIndexKeys;

  /**
   * The maximum number of keys in a leaf node.
   */
  int get maxLeafKeys;

  /**
   * Generates an identifier for a new index node.
   */
  N createIndex();

  /**
   * Generates an identifier for a new leaf node.
   */
  N createLeaf();

  /**
   * Deletes the node with the given identifier.
   */
  void delete(N id);

  /**
   * Checks if the node with the given identifier is an index or a leaf node.
   */
  bool isIndex(N id);

  /**
   * Reads information about the index node with the given identifier.
   */
  IndexNodeData<K, N> readIndex(N id);

  /**
   * Reads information about the leaf node with the given identifier.
   */
  LeafNodeData<K, V> readLeaf(N id);

  /**
   * Writes information about the index node with the given identifier.
   */
  void writeIndex(N id, IndexNodeData<K, N> data);

  /**
   * Writes information about the leaf node with the given identifier.
   */
  void writeLeaf(N id, LeafNodeData<K, V> data);
}


/**
 * An index node with keys and children references.
 */
class _IndexNode<K, V, N> extends _Node<K, V, N> {
  List<N> children = new List<N>();
  final int maxKeys;
  final int minKeys;

  _IndexNode(BPlusTree<K, V, N> tree, N id, int maxKeys)
      : super(tree, id),
        maxKeys = maxKeys,
        minKeys = maxKeys ~/ 2;

  @override
  V find(K key) {
    int index = _findChildIndex(key);
    _Node<K, V, N> child = tree._readNode(children[index]);
    return child.find(key);
  }

  _Split<K, N> insert(K key, V value) {
    // Early split.
    if (keys.length == maxKeys) {
      int middle = (maxKeys + 1) ~/ 2;
      K splitKey = keys[middle];
      // Overflow into a new sibling.
      _IndexNode<K, V, N> sibling = tree._newIndexNode();
      sibling.keys.addAll(keys.getRange(middle + 1, keys.length));
      sibling.children.addAll(children.getRange(middle + 1, children.length));
      keys.length = middle;
      children.length = middle + 1;
      // Insert into this node or sibling.
      if (comparator(key, splitKey) < 0) {
        _insertNotFull(key, value);
      } else {
        sibling._insertNotFull(key, value);
      }
      // Prepare split.
      tree._writeIndexNode(this);
      tree._writeIndexNode(sibling);
      return new _Split<K, N>(splitKey, id, sibling.id);
    }
    // No split.
    _insertNotFull(key, value);
    return null;
  }

  @override
  _Remove<K, V> remove(K key, _Node<K, V, N> left, K anchor, _Node<K, V,
      N> right) {
    int index = _findChildIndex(key);
    K thisAnchor = index == 0 ? keys[0] : keys[index - 1];
    // Prepare children.
    _Node<K, V, N> child = tree._readNode(children[index]);
    _Node<K, V, N> leftChild;
    _Node<K, V, N> rightChild;
    if (index != 0) {
      leftChild = tree._readNode(children[index - 1]);
    } else {
      leftChild = null;
    }
    if (index < children.length - 1) {
      rightChild = tree._readNode(children[index + 1]);
    } else {
      rightChild = null;
    }
    // Ask child to remove.
    _Remove<K, V> result = child.remove(key, leftChild, thisAnchor, rightChild);
    V value = result.value;
    if (value == null) {
      return new _Remove<K, V>(value);
    }
    // Do keys / children updates
    bool hasUpdates = false;
    {
      // Update anchor if borrowed.
      if (result.leftAnchor != null) {
        keys[index - 1] = result.leftAnchor;
        hasUpdates = true;
      }
      if (result.rightAnchor != null) {
        keys[index] = result.rightAnchor;
        hasUpdates = true;
      }
      // Update keys / children if merged.
      if (result.mergedLeft) {
        keys.removeAt(index - 1);
        N child = children.removeAt(index);
        manager.delete(child);
        hasUpdates = true;
      }
      if (result.mergedRight) {
        keys.removeAt(index);
        N child = children.removeAt(index);
        manager.delete(child);
        hasUpdates = true;
      }
    }
    // Write if updated.
    if (!hasUpdates) {
      return new _Remove<K, V>(value);
    }
    tree._writeIndexNode(this);
    // Perform balancing.
    if (keys.length < minKeys) {
      // Try left sibling.
      if (left is _IndexNode<K, V, N>) {
        // Try to redistribute.
        int leftLength = left.keys.length;
        if (leftLength > minKeys) {
          int halfExcess = (leftLength - minKeys + 1) ~/ 2;
          int newLeftLength = leftLength - halfExcess;
          keys.insert(0, anchor);
          keys.insertAll(0, left.keys.getRange(newLeftLength, leftLength));
          children.insertAll(0, left.children.getRange(newLeftLength, leftLength
              + 1));
          K newAnchor = left.keys[newLeftLength - 1];
          left.keys.length = newLeftLength - 1;
          left.children.length = newLeftLength;
          tree._writeIndexNode(this);
          tree._writeIndexNode(left);
          return new _Remove<K, V>.borrowLeft(value, newAnchor);
        }
        // Do merge.
        left.keys.add(anchor);
        left.keys.addAll(keys);
        left.children.addAll(children);
        tree._writeIndexNode(this);
        tree._writeIndexNode(left);
        return new _Remove<K, V>.mergeLeft(value);
      }
      // Try right sibling.
      if (right is _IndexNode<K, V, N>) {
        // Try to redistribute.
        int rightLength = right.keys.length;
        if (rightLength > minKeys) {
          int halfExcess = (rightLength - minKeys + 1) ~/ 2;
          keys.add(anchor);
          keys.addAll(right.keys.getRange(0, halfExcess - 1));
          children.addAll(right.children.getRange(0, halfExcess));
          K newAnchor = right.keys[halfExcess - 1];
          right.keys.removeRange(0, halfExcess);
          right.children.removeRange(0, halfExcess);
          tree._writeIndexNode(this);
          tree._writeIndexNode(right);
          return new _Remove<K, V>.borrowRight(value, newAnchor);
        }
        // Do merge.
        right.keys.insert(0, anchor);
        right.keys.insertAll(0, keys);
        right.children.insertAll(0, children);
        tree._writeIndexNode(this);
        tree._writeIndexNode(right);
        return new _Remove<K, V>.mergeRight(value);
      }
    }
    // No balancing required.
    return new _Remove<K, V>(value);
  }

  @override
  void writeOn(StringBuffer buffer, String indent) {
    buffer.write(indent);
    buffer.write('INode {\n');
    for (int i = 0; i < keys.length; i++) {
      _Node<K, V, N> child = tree._readNode(children[i]);
      child.writeOn(buffer, indent + '    ');
      buffer.write(indent);
      buffer.write('  ');
      buffer.write(keys[i]);
      buffer.write('\n');
    }
    _Node<K, V, N> child = tree._readNode(children[keys.length]);
    child.writeOn(buffer, indent + '    ');
    buffer.write(indent);
    buffer.write('}\n');
  }

  /**
   * Returns the index of the child into which [key] should be inserted.
   */
  int _findChildIndex(K key) {
    int lo = 0;
    int hi = keys.length - 1;
    while (lo <= hi) {
      int mid = lo + (hi - lo) ~/ 2;
      int compare = comparator(key, keys[mid]);
      if (compare < 0) {
        hi = mid - 1;
      } else if (compare > 0) {
        lo = mid + 1;
      } else {
        return mid + 1;
      }
    }
    return lo;
  }

  void _insertNotFull(K key, V value) {
    int index = _findChildIndex(key);
    _Node<K, V, N> child = tree._readNode(children[index]);
    _Split<K, N> result = child.insert(key, value);
    if (result != null) {
      keys.insert(index, result.key);
      children[index] = result.left;
      children.insert(index + 1, result.right);
      tree._writeIndexNode(this);
    }
  }
}


/**
 * A leaf node with keys and values.
 */
class _LeafNode<K, V, N> extends _Node<K, V, N> {
  final int maxKeys;
  final int minKeys;
  List<V> values = new List<V>();

  _LeafNode(BPlusTree<K, V, N> tree, N id, int maxKeys)
      : super(tree, id),
        maxKeys = maxKeys,
        minKeys = maxKeys ~/ 2;

  @override
  V find(K key) {
    int index = _findKeyIndex(key);
    if (index < 0) {
      return null;
    }
    if (index >= keys.length) {
      return null;
    }
    if (keys[index] != key) {
      return null;
    }
    return values[index];
  }

  _Split<K, N> insert(K key, V value) {
    int index = _findKeyIndex(key);
    // The node is full.
    if (keys.length == maxKeys) {
      int middle = (maxKeys + 1) ~/ 2;
      _LeafNode<K, V, N> sibling = tree._newLeafNode();
      sibling.keys.addAll(keys.getRange(middle, keys.length));
      sibling.values.addAll(values.getRange(middle, values.length));
      keys.length = middle;
      values.length = middle;
      // Insert into the left / right sibling.
      if (index < middle) {
        _insertNotFull(key, value, index);
      } else {
        sibling._insertNotFull(key, value, index - middle);
      }
      // Notify the parent about the split.
      tree._writeLeafNode(this);
      tree._writeLeafNode(sibling);
      return new _Split<K, N>(sibling.keys[0], id, sibling.id);
    }
    // The node was not full.
    _insertNotFull(key, value, index);
    return null;
  }

  @override
  _Remove<K, V> remove(K key, _Node<K, V, N> left, K anchor, _Node<K, V,
      N> right) {
    // Find the key.
    int index = keys.indexOf(key);
    if (index == -1) {
      return new _Remove<K, V>(null);
    }
    // Remove key / value.
    keys.removeAt(index);
    V value = values.removeAt(index);
    tree._writeLeafNode(this);
    // Perform balancing.
    if (keys.length < minKeys) {
      // Try left sibling.
      if (left is _LeafNode<K, V, N>) {
        // Try to redistribute.
        int leftLength = left.keys.length;
        if (leftLength > minKeys) {
          int halfExcess = (leftLength - minKeys + 1) ~/ 2;
          int newLeftLength = leftLength - halfExcess;
          keys.insertAll(0, left.keys.getRange(newLeftLength, leftLength));
          values.insertAll(0, left.values.getRange(newLeftLength, leftLength));
          left.keys.length = newLeftLength;
          left.values.length = newLeftLength;
          tree._writeLeafNode(this);
          tree._writeLeafNode(left);
          return new _Remove<K, V>.borrowLeft(value, keys.first);
        }
        // Do merge.
        left.keys.addAll(keys);
        left.values.addAll(values);
        tree._writeLeafNode(this);
        tree._writeLeafNode(left);
        return new _Remove<K, V>.mergeLeft(value);
      }
      // Try right sibling.
      if (right is _LeafNode<K, V, N>) {
        // Try to redistribute.
        int rightLength = right.keys.length;
        if (rightLength > minKeys) {
          int halfExcess = (rightLength - minKeys + 1) ~/ 2;
          keys.addAll(right.keys.getRange(0, halfExcess));
          values.addAll(right.values.getRange(0, halfExcess));
          right.keys.removeRange(0, halfExcess);
          right.values.removeRange(0, halfExcess);
          tree._writeLeafNode(this);
          tree._writeLeafNode(right);
          return new _Remove<K, V>.borrowRight(value, right.keys.first);
        }
        // Do merge.
        right.keys.insertAll(0, keys);
        right.values.insertAll(0, values);
        tree._writeLeafNode(this);
        tree._writeLeafNode(right);
        return new _Remove<K, V>.mergeRight(value);
      }
    }
    // No balancing required.
    return new _Remove<K, V>(value);
  }

  @override
  void writeOn(StringBuffer buffer, String indent) {
    buffer.write(indent);
    buffer.write('LNode {');
    for (int i = 0; i < keys.length; i++) {
      if (i != 0) {
        buffer.write(', ');
      }
      buffer.write(keys[i]);
      buffer.write(': ');
      buffer.write(values[i]);
    }
    buffer.write('}\n');
  }

  /**
   * Returns the index where [key] should be inserted.
   */
  int _findKeyIndex(K key) {
    int lo = 0;
    int hi = keys.length - 1;
    while (lo <= hi) {
      int mid = lo + (hi - lo) ~/ 2;
      int compare = comparator(key, keys[mid]);
      if (compare < 0) {
        hi = mid - 1;
      } else if (compare > 0) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    return lo;
  }

  void _insertNotFull(K key, V value, int index) {
    if (index < keys.length && comparator(keys[index], key) == 0) {
      values[index] = value;
    } else {
      keys.insert(index, key);
      values.insert(index, value);
    }
    tree._writeLeafNode(this);
  }
}


/**
 * An internal or leaf node.
 */
abstract class _Node<K, V, N> {
  /**
   * The [Comparator] to compare keys.
   */
  final Comparator<K> comparator;

  /**
   * The identifier of this node.
   */
  final N id;

  /**
   *  The list of keys.
   */
  List<K> keys = new List<K>();

  /**
   * The [NodeManager] for this tree.
   */
  final NodeManager<K, V, N> manager;

  /**
   * The [BPlusTree] this node belongs to.
   */
  final BPlusTree<K, V, N> tree;

  _Node(BPlusTree<K, V, N> tree, this.id)
      : tree = tree,
        comparator = tree._comparator,
        manager = tree._manager;

  /**
   * Looks for [key].
   *
   * Returns the associated value if found.
   * Returns `null` if not found.
   */
  V find(K key);

  /**
   * Inserts the [key] / [value] pair into this [_Node].
   *
   * Returns a [_Split] object if split happens, or `null` otherwise.
   */
  _Split<K, N> insert(K key, V value);

  /**
   * Removes the association for the given [key].
   *
   * Returns the [_Remove] information about an operation performed.
   * It may be restructuring or merging, with [left] or [left] siblings.
   */
  _Remove<K, V> remove(K key, _Node<K, V, N> left, K anchor, _Node<K, V,
      N> right);

  /**
   * Writes a textual presentation of the tree into [buffer].
   */
  void writeOn(StringBuffer buffer, String indent);
}


/**
 * A container with information about redistribute / merge.
 */
class _Remove<K, V> {
  K leftAnchor;
  bool mergedLeft = false;
  bool mergedRight = false;
  K rightAnchor;
  final V value;
  _Remove(this.value);
  _Remove.borrowLeft(this.value, this.leftAnchor);
  _Remove.borrowRight(this.value, this.rightAnchor);
  _Remove.mergeLeft(this.value) : mergedLeft = true;
  _Remove.mergeRight(this.value) : mergedRight = true;
}


/**
 * A container with information about split during insert.
 */
class _Split<K, N> {
  final K key;
  final N left;
  final N right;
  _Split(this.key, this.left, this.right);
}

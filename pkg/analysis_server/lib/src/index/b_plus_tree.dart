// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index.b_plus_tree;


/**
 * A simple B+ tree (http://en.wikipedia.org/wiki/B+_tree) implementation.
 */
class BPlusTree<K, V> {
  /**
   * The [Comparator] to compare keys.
   */
  final Comparator<K> _comparator;

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
  _Node<K, V> _root;

  BPlusTree(this._maxIndexKeys, this._maxLeafKeys, this._comparator) {
    _root = new _LeafNode(_maxLeafKeys, _comparator);
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
    _Split<K, V> result = _root.insert(key, value);
    if (result != null) {
      _IndexNode<K, V> newRoot = new _IndexNode<K, V>(_maxIndexKeys,
          _comparator);
      newRoot.keys.add(result.key);
      newRoot.children.add(result.left);
      newRoot.children.add(result.right);
      _root = newRoot;
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
    if (_root is _IndexNode<K, V>) {
      List<_Node<K, V>> children = (_root as _IndexNode<K, V>).children;
      if (children.length == 1) {
        _root = children[0];
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
}


/**
 * An index node with keys and children references.
 */
class _IndexNode<K, V> extends _Node<K, V> {
  final List<_Node<K, V>> children = new List<_Node<K, V>>();
  final int maxKeys;
  final int minKeys;

  _IndexNode(int maxKeys, Comparator<K> comparator)
      : super(comparator),
        maxKeys = maxKeys,
        minKeys = maxKeys ~/ 2;

  @override
  V find(K key) {
    int index = findChildIndex(key);
    return children[index].find(key);
  }

  /**
   * Returns the index of the child into which [key] should be inserted.
   */
  int findChildIndex(K key) {
    for (int i = 0; i < keys.length; i++) {
      if (comparator(keys[i], key) > 0) {
        return i;
      }
    }
    return keys.length;
  }

  _Split<K, V> insert(K key, V value) {
    // Early split.
    if (keys.length == maxKeys) {
      int middle = (maxKeys + 1) ~/ 2;
      K splitKey = keys[middle];
      _IndexNode<K, V> sibling = new _IndexNode<K, V>(maxKeys, comparator);
      sibling.keys.addAll(keys.getRange(middle + 1, keys.length));
      sibling.children.addAll(children.getRange(middle + 1, children.length));
      keys.length = middle;
      children.length = middle + 1;
      // Prepare split.
      _Split<K, V> result = new _Split<K, V>(splitKey, this, sibling);
      if (comparator(key, result.key) < 0) {
        insertNotFull(key, value);
      } else {
        sibling.insertNotFull(key, value);
      }
      return result;
    }
    // No split.
    insertNotFull(key, value);
    return null;
  }

  void insertNotFull(K key, V value) {
    int index = findChildIndex(key);
    _Split<K, V> result = children[index].insert(key, value);
    if (result != null) {
      keys.insert(index, result.key);
      children[index] = result.left;
      children.insert(index + 1, result.right);
    }
  }

  @override
  _Remove<K, V> remove(K key, _Node<K, V> left, K anchor, _Node<K, V> right) {
    int index = findChildIndex(key);
    K thisAnchor = index == 0 ? keys[0] : keys[index - 1];
    _Node<K, V> child = children[index];
    bool hasLeft = index != 0;
    bool hasRight = index < children.length - 1;
    _Node<K, V> leftChild = hasLeft ? children[index - 1] : null;
    _Node<K, V> rightChild = hasRight ? children[index + 1] : null;
    // Ask child to remove.
    _Remove<K, V> result = child.remove(key, leftChild, thisAnchor, rightChild);
    V value = result.value;
    if (value == null) {
      return new _Remove<K, V>(value);
    }
    // Update anchor if borrowed.
    if (result.leftAnchor != null) {
      keys[index - 1] = result.leftAnchor;
    }
    if (result.rightAnchor != null) {
      keys[index] = result.rightAnchor;
    }
    // Update keys / children if merged.
    if (result.mergedLeft) {
      keys.removeAt(index - 1);
      children.removeAt(index);
    }
    if (result.mergedRight) {
      keys.removeAt(index);
      children.removeAt(index);
    }
    // Perform balancing.
    if (keys.length < minKeys) {
      // Try left sibling.
      if (left is _IndexNode<K, V>) {
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
          return new _Remove<K, V>.borrowLeft(value, newAnchor);
        }
        // Do merge.
        left.keys.add(anchor);
        left.keys.addAll(keys);
        left.children.addAll(children);
        return new _Remove<K, V>.mergeLeft(value);
      }
      // Try right sibling.
      if (right is _IndexNode<K, V>) {
        // Try to redistribute.
        var rightLength = right.keys.length;
        if (rightLength > minKeys) {
          int halfExcess = (rightLength - minKeys + 1) ~/ 2;
          keys.add(anchor);
          keys.addAll(right.keys.getRange(0, halfExcess - 1));
          children.addAll(right.children.getRange(0, halfExcess));
          K newAnchor = right.keys[halfExcess - 1];
          right.keys.removeRange(0, halfExcess);
          right.children.removeRange(0, halfExcess);
          return new _Remove<K, V>.borrowRight(value, newAnchor);
        }
        // Do merge.
        right.keys.insert(0, anchor);
        right.keys.insertAll(0, keys);
        right.children.insertAll(0, children);
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
      children[i].writeOn(buffer, indent + '    ');
      buffer.write(indent);
      buffer.write('  ');
      buffer.write(keys[i]);
      buffer.write('\n');
    }
    children[keys.length].writeOn(buffer, indent + '    ');
    buffer.write(indent);
    buffer.write('}\n');
  }
}


/**
 * A leaf node with keys and values.
 */
class _LeafNode<K, V> extends _Node<K, V> {
  final int maxKeys;
  final int minKeys;

  /**
   *  The list of values.
   */
  final List<V> values = new List<V>();

  _LeafNode(int maxKeys, Comparator<K> comparator)
      : super(comparator),
        maxKeys = maxKeys,
        minKeys = maxKeys ~/ 2;

  @override
  V find(K key) {
    int index = findKeyIndex(key);
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

  /**
   * Returns the index where [key] should be inserted.
   */
  int findKeyIndex(K key) {
    for (int i = 0; i < keys.length; i++) {
      if (comparator(keys[i], key) >= 0) {
        return i;
      }
    }
    return keys.length;
  }

  _Split<K, V> insert(K key, V value) {
    int index = findKeyIndex(key);
    // The node is full.
    if (keys.length == maxKeys) {
      int middle = (maxKeys + 1) ~/ 2;
      _LeafNode<K, V> sibling = new _LeafNode<K, V>(maxKeys, comparator);
      sibling.keys.addAll(keys.getRange(middle, keys.length));
      sibling.values.addAll(values.getRange(middle, values.length));
      keys.length = middle;
      values.length = middle;
      // Insert into the left / right sibling.
      if (index < middle) {
        insertNotFull(key, value, index);
      } else {
        sibling.insertNotFull(key, value, index - middle);
      }
      // Notify the parent about the split.
      return new _Split<K, V>(sibling.keys[0], this, sibling);
    }
    // The node was not full.
    insertNotFull(key, value, index);
    return null;
  }

  void insertNotFull(K key, V value, int index) {
    if (index < keys.length && keys[index] == key) {
      values[index] = value;
    } else {
      keys.insert(index, key);
      values.insert(index, value);
    }
  }

  @override
  _Remove<K, V> remove(K key, _Node<K, V> left, K anchor, _Node<K, V> right) {
    // Find the key.
    int index = keys.indexOf(key);
    if (index == -1) {
      return new _Remove<K, V>(null);
    }
    // Key key / value.
    keys.removeAt(index);
    V value = values.removeAt(index);
    // Perform balancing.
    if (keys.length < minKeys) {
      // Try left sibling.
      if (left is _LeafNode<K, V>) {
        // Try to redistribute.
        int leftLength = left.keys.length;
        if (leftLength > minKeys) {
          int halfExcess = (leftLength - minKeys + 1) ~/ 2;
          int newLeftLength = leftLength - halfExcess;
          keys.insertAll(0, left.keys.getRange(newLeftLength, leftLength));
          values.insertAll(0, left.values.getRange(newLeftLength, leftLength));
          left.keys.length = newLeftLength;
          left.values.length = newLeftLength;
          return new _Remove<K, V>.borrowLeft(value, keys.first);
        }
        // Do merge.
        left.keys.addAll(keys);
        left.values.addAll(values);
        return new _Remove<K, V>.mergeLeft(value);
      }
      // Try right sibling.
      if (right is _LeafNode<K, V>) {
        // Try to redistribute.
        var rightLength = right.keys.length;
        if (rightLength > minKeys) {
          int halfExcess = (rightLength - minKeys + 1) ~/ 2;
          keys.addAll(right.keys.getRange(0, halfExcess));
          values.addAll(right.values.getRange(0, halfExcess));
          right.keys.removeRange(0, halfExcess);
          right.values.removeRange(0, halfExcess);
          return new _Remove<K, V>.borrowRight(value, right.keys.first);
        }
        // Do merge.
        right.keys.insertAll(0, keys);
        right.values.insertAll(0, values);
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
}


/**
 * An internal or leaf node.
 */
abstract class _Node<K, V> {
  /**
   * The [Comparator] to compare keys.
   */
  Comparator<K> comparator;

  /**
   *  The list of keys.
   */
  List<K> keys = new List<K>();

  _Node(this.comparator);

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
  _Split<K, V> insert(K key, V value);

  /**
   * Removes the association for the given [key].
   *
   * Returns the [_Remove] information about an operation performed.
   * It may be restructuring or merging, with [left] or [left] siblings.
   */
  _Remove<K, V> remove(K key, _Node<K, V> left, K anchor, _Node<K, V> right);

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
class _Split<K, V> {
  final K key;
  final _Node<K, V> left;
  final _Node<K, V> right;
  _Split(this.key, this.left, this.right);
}

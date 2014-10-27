// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities.collection;

import 'dart:collection';
import "dart:math" as math;

import 'java_core.dart';
import 'scanner.dart' show Token;

/**
 * The class `BooleanArray` defines methods for operating on integers as if they were arrays
 * of booleans. These arrays can be indexed by either integers or by enumeration constants.
 */
class BooleanArray {
  /**
   * Return the value of the element at the given index.
   *
   * @param array the array being accessed
   * @param index the index of the element being accessed
   * @return the value of the element at the given index
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static bool get(int array, int index) {
    _checkIndex(index);
    return (array & (1 << index)) > 0;
  }

  /**
   * Return the value of the element at the given index.
   *
   * @param array the array being accessed
   * @param index the index of the element being accessed
   * @return the value of the element at the given index
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static bool getEnum(int array, Enum index) => get(array, index.ordinal);

  /**
   * Set the value of the element at the given index to the given value.
   *
   * @param array the array being modified
   * @param index the index of the element being set
   * @param value the value to be assigned to the element
   * @return the updated value of the array
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static int set(int array, int index, bool value) {
    _checkIndex(index);
    if (value) {
      return array | (1 << index);
    } else {
      return array & ~(1 << index);
    }
  }

  /**
   * Set the value of the element at the given index to the given value.
   *
   * @param array the array being modified
   * @param index the index of the element being set
   * @param value the value to be assigned to the element
   * @return the updated value of the array
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static int setEnum(int array, Enum index, bool value) => set(array, index.ordinal, value);

  /**
   * Throw an exception if the index is not within the bounds allowed for an integer-encoded array
   * of boolean values.
   *
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static void _checkIndex(int index) {
    if (index < 0 || index > 30) {
      throw new RangeError("Index not between 0 and 30: ${index}");
    }
  }
}

/**
 * Instances of the class `DirectedGraph` implement a directed graph in which the nodes are
 * arbitrary (client provided) objects and edges are represented implicitly. The graph will allow an
 * edge from any node to any other node, including itself, but will not represent multiple edges
 * between the same pair of nodes.
 *
 * @param N the type of the nodes in the graph
 */
class DirectedGraph<N> {
  /**
   * The table encoding the edges in the graph. An edge is represented by an entry mapping the head
   * to a set of tails. Nodes that are not the head of any edge are represented by an entry mapping
   * the node to an empty set of tails.
   */
  HashMap<N, HashSet<N>> _edges = new HashMap<N, HashSet<N>>();

  /**
   * Add an edge from the given head node to the given tail node. Both nodes will be a part of the
   * graph after this method is invoked, whether or not they were before.
   *
   * @param head the node at the head of the edge
   * @param tail the node at the tail of the edge
   */
  void addEdge(N head, N tail) {
    //
    // First, ensure that the tail is a node known to the graph.
    //
    if (_edges[tail] == null) {
      _edges[tail] = new HashSet<N>();
    }
    //
    // Then create the edge.
    //
    HashSet<N> tails = _edges[head];
    if (tails == null) {
      tails = new HashSet<N>();
      _edges[head] = tails;
    }
    tails.add(tail);
  }

  /**
   * Add the given node to the set of nodes in the graph.
   *
   * @param node the node to be added
   */
  void addNode(N node) {
    HashSet<N> tails = _edges[node];
    if (tails == null) {
      _edges[node] = new HashSet<N>();
    }
  }

  /**
   * Run a topological sort of the graph. Since the graph may contain cycles, this results in a list
   * of strongly connected components rather than a list of nodes. The nodes in each strongly
   * connected components only have edges that point to nodes in the same component or earlier
   * components.
   */
  List<List<N>> computeTopologicalSort() {
    DirectedGraph_SccFinder<N> finder = new DirectedGraph_SccFinder<N>(this);
    return finder.computeTopologicalSort();
  }

  /**
   * Return true if the graph contains at least one path from `source` to `destination`.
   */
  bool containsPath(N source, N destination) {
    HashSet<N> nodesVisited = new HashSet<N>();
    return _containsPathInternal(source, destination, nodesVisited);
  }

  /**
   * Return a list of nodes that form a cycle containing the given node. If the node is not part of
   * this graph, then a list containing only the node itself will be returned.
   *
   * @return a list of nodes that form a cycle containing the given node
   */
  List<N> findCycleContaining(N node) {
    if (node == null) {
      throw new IllegalArgumentException();
    }
    DirectedGraph_SccFinder<N> finder = new DirectedGraph_SccFinder<N>(this);
    return finder.componentContaining(node);
  }

  /**
   * Return the number of nodes in this graph.
   *
   * @return the number of nodes in this graph
   */
  int get nodeCount => _edges.length;

  /**
   * Return a set of all nodes in the graph.
   */
  Set<N> get nodes => _edges.keys.toSet();

  /**
   * Return a set containing the tails of edges that have the given node as their head. The set will
   * be empty if there are no such edges or if the node is not part of the graph. Clients must not
   * modify the returned set.
   *
   * @param head the node at the head of all of the edges whose tails are to be returned
   * @return a set containing the tails of edges that have the given node as their head
   */
  Set<N> getTails(N head) {
    HashSet<N> tails = _edges[head];
    if (tails == null) {
      return new HashSet<N>();
    }
    return tails;
  }

  /**
   * Return `true` if this graph is empty.
   *
   * @return `true` if this graph is empty
   */
  bool get isEmpty => _edges.isEmpty;

  /**
   * Remove all of the given nodes from this graph. As a consequence, any edges for which those
   * nodes were either a head or a tail will also be removed.
   *
   * @param nodes the nodes to be removed
   */
  void removeAllNodes(List<N> nodes) {
    for (N node in nodes) {
      removeNode(node);
    }
  }

  /**
   * Remove the edge from the given head node to the given tail node. If there was no such edge then
   * the graph will be unmodified: the number of edges will be the same and the set of nodes will be
   * the same (neither node will either be added or removed).
   *
   * @param head the node at the head of the edge
   * @param tail the node at the tail of the edge
   * @return `true` if the graph was modified as a result of this operation
   */
  void removeEdge(N head, N tail) {
    HashSet<N> tails = _edges[head];
    if (tails != null) {
      tails.remove(tail);
    }
  }

  /**
   * Remove the given node from this graph. As a consequence, any edges for which that node was
   * either a head or a tail will also be removed.
   *
   * @param node the node to be removed
   */
  void removeNode(N node) {
    _edges.remove(node);
    for (HashSet<N> tails in _edges.values) {
      tails.remove(node);
    }
  }

  /**
   * Find one node (referred to as a sink node) that has no outgoing edges (that is, for which there
   * are no edges that have that node as the head of the edge) and remove it from this graph. Return
   * the node that was removed, or `null` if there are no such nodes either because the graph
   * is empty or because every node in the graph has at least one outgoing edge. As a consequence of
   * removing the node from the graph any edges for which that node was a tail will also be removed.
   *
   * @return the sink node that was removed
   */
  N removeSink() {
    N sink = _findSink();
    if (sink == null) {
      return null;
    }
    removeNode(sink);
    return sink;
  }

  bool _containsPathInternal(N source, N destination, HashSet<N> nodesVisited) {
    if (identical(source, destination)) {
      return true;
    }
    HashSet<N> tails = _edges[source];
    if (tails != null) {
      nodesVisited.add(source);
      for (N tail in tails) {
        if (!nodesVisited.contains(tail)) {
          if (_containsPathInternal(tail, destination, nodesVisited)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Return one node that has no outgoing edges (that is, for which there are no edges that have
   * that node as the head of the edge), or `null` if there are no such nodes.
   *
   * @return a sink node
   */
  N _findSink() {
    for (N key in _edges.keys) {
      if (_edges[key].isEmpty) return key;
    }
    return null;
  }
}

/**
 * Instances of the class `NodeInfo` are used by the [SccFinder] to maintain
 * information about the nodes that have been examined.
 *
 * @param N the type of the nodes corresponding to the entries
 */
class DirectedGraph_NodeInfo<N> {
  /**
   * The depth of this node.
   */
  int index = 0;

  /**
   * The depth of the first node in a cycle.
   */
  int lowlink = 0;

  /**
   * A flag indicating whether the corresponding node is on the stack. Used to remove the need for
   * searching a collection for the node each time the question needs to be asked.
   */
  bool onStack = false;

  /**
   * The component that contains the corresponding node.
   */
  List<N> component;

  /**
   * Initialize a newly created information holder to represent a node at the given depth.
   *
   * @param depth the depth of the node being represented
   */
  DirectedGraph_NodeInfo(int depth) {
    index = depth;
    lowlink = depth;
    onStack = false;
  }
}

/**
 * Instances of the class `SccFinder` implement Tarjan's Algorithm for finding the strongly
 * connected components in a graph.
 */
class DirectedGraph_SccFinder<N> {
  /**
   * The graph to work with.
   */
  final DirectedGraph<N> _graph;

  /**
   * The index used to uniquely identify the depth of nodes.
   */
  int _index = 0;

  /**
   * The stack of nodes that are being visited in order to identify components.
   */
  List<N> _stack = new List<N>();

  /**
   * A table mapping nodes to information about the nodes that is used by this algorithm.
   */
  HashMap<N, DirectedGraph_NodeInfo<N>> _nodeMap = new HashMap<N, DirectedGraph_NodeInfo<N>>();

  /**
   * A list of all strongly connected components found, in topological sort order (each node in a
   * strongly connected component only has edges that point to nodes in the same component or
   * earlier components).
   */
  List<List<N>> _allComponents = new List<List<N>>();

  /**
   * Initialize a newly created finder.
   */
  DirectedGraph_SccFinder(this._graph) : super();

  /**
   * Return a list containing the nodes that are part of the strongly connected component that
   * contains the given node.
   *
   * @param node the node used to identify the strongly connected component to be returned
   * @return the nodes that are part of the strongly connected component that contains the given
   *         node
   */
  List<N> componentContaining(N node) => _strongConnect(node).component;

  /**
   * Run Tarjan's algorithm and return the resulting list of strongly connected components. The
   * list is in topological sort order (each node in a strongly connected component only has edges
   * that point to nodes in the same component or earlier components).
   */
  List<List<N>> computeTopologicalSort() {
    for (N node in _graph._edges.keys.toSet()) {
      DirectedGraph_NodeInfo<N> nodeInfo = _nodeMap[node];
      if (nodeInfo == null) {
        _strongConnect(node);
      }
    }
    return _allComponents;
  }

  /**
   * Remove and return the top-most element from the stack.
   *
   * @return the element that was removed
   */
  N _pop() {
    N node = _stack.removeAt(_stack.length - 1);
    _nodeMap[node].onStack = false;
    return node;
  }

  /**
   * Add the given node to the stack.
   *
   * @param node the node to be added to the stack
   */
  void _push(N node) {
    _nodeMap[node].onStack = true;
    _stack.add(node);
  }

  /**
   * Compute the strongly connected component that contains the given node as well as any
   * components containing nodes that are reachable from the given component.
   *
   * @param v the node from which the search will begin
   * @return the information about the given node
   */
  DirectedGraph_NodeInfo<N> _strongConnect(N v) {
    //
    // Set the depth index for v to the smallest unused index
    //
    DirectedGraph_NodeInfo<N> vInfo = new DirectedGraph_NodeInfo<N>(_index++);
    _nodeMap[v] = vInfo;
    _push(v);
    //
    // Consider successors of v
    //
    HashSet<N> tails = _graph._edges[v];
    if (tails != null) {
      for (N w in tails) {
        DirectedGraph_NodeInfo<N> wInfo = _nodeMap[w];
        if (wInfo == null) {
          // Successor w has not yet been visited; recurse on it
          wInfo = _strongConnect(w);
          vInfo.lowlink = math.min(vInfo.lowlink, wInfo.lowlink);
        } else if (wInfo.onStack) {
          // Successor w is in stack S and hence in the current SCC
          vInfo.lowlink = math.min(vInfo.lowlink, wInfo.index);
        }
      }
    }
    //
    // If v is a root node, pop the stack and generate an SCC
    //
    if (vInfo.lowlink == vInfo.index) {
      List<N> component = new List<N>();
      N w;
      do {
        w = _pop();
        component.add(w);
        _nodeMap[w].component = component;
      } while (!identical(w, v));
      _allComponents.add(component);
    }
    return vInfo;
  }
}

/**
 * The class `ListUtilities` defines utility methods useful for working with [List
 ].
 */
class ListUtilities {
  /**
   * Add all of the elements in the given array to the given list.
   *
   * @param list the list to which the elements are to be added
   * @param elements the elements to be added to the list
   */
  static void addAll(List list, List<Object> elements) {
    int count = elements.length;
    for (int i = 0; i < count; i++) {
      list.add(elements[i]);
    }
  }
}

/**
 * The interface `MapIterator` defines the behavior of objects that iterate over the entries
 * in a map.
 *
 * This interface defines the concept of a current entry and provides methods to access the key and
 * value in the current entry. When an iterator is first created it will be positioned before the
 * first entry and there is no current entry until [moveNext] is invoked. When all of the
 * entries have been accessed there will also be no current entry.
 *
 * There is no guarantee made about the order in which the entries are accessible.
 */
abstract class MapIterator<K, V> {
  /**
   * Return the key associated with the current element.
   *
   * @return the key associated with the current element
   * @throws NoSuchElementException if there is no current element
   */
  K get key;

  /**
   * Return the value associated with the current element.
   *
   * @return the value associated with the current element
   * @throws NoSuchElementException if there is no current element
   */
  V get value;

  /**
   * Advance to the next entry in the map. Return `true` if there is a current element that
   * can be accessed after this method returns. It is safe to invoke this method even if the
   * previous invocation returned `false`.
   *
   * @return `true` if there is a current element that can be accessed
   */
  bool moveNext();

  /**
   * Set the value associated with the current element to the given value.
   *
   * @param newValue the new value to be associated with the current element
   * @throws NoSuchElementException if there is no current element
   */
  void set value(V newValue);
}

/**
 * Instances of the class `MultipleMapIterator` implement an iterator that can be used to
 * sequentially access the entries in multiple maps.
 */
class MultipleMapIterator<K, V> implements MapIterator<K, V> {
  /**
   * The iterators used to access the entries.
   */
  List<MapIterator<K, V>> _iterators;

  /**
   * The index of the iterator currently being used to access the entries.
   */
  int _iteratorIndex = -1;

  /**
   * The current iterator, or `null` if there is no current iterator.
   */
  MapIterator<K, V> _currentIterator;

  /**
   * Initialize a newly created iterator to return the entries from the given maps.
   *
   * @param maps the maps containing the entries to be iterated
   */
  MultipleMapIterator(List<Map<K, V>> maps) {
    int count = maps.length;
    _iterators = new List<MapIterator>(count);
    for (int i = 0; i < count; i++) {
      _iterators[i] = new SingleMapIterator<K, V>(maps[i]);
    }
  }

  @override
  K get key {
    if (_currentIterator == null) {
      throw new NoSuchElementException();
    }
    return _currentIterator.key;
  }

  @override
  V get value {
    if (_currentIterator == null) {
      throw new NoSuchElementException();
    }
    return _currentIterator.value;
  }

  @override
  bool moveNext() {
    if (_iteratorIndex < 0) {
      if (_iterators.length == 0) {
        _currentIterator = null;
        return false;
      }
      if (_advanceToNextIterator()) {
        return true;
      } else {
        _currentIterator = null;
        return false;
      }
    }
    if (_currentIterator.moveNext()) {
      return true;
    } else if (_advanceToNextIterator()) {
      return true;
    } else {
      _currentIterator = null;
      return false;
    }
  }

  @override
  void set value(V newValue) {
    if (_currentIterator == null) {
      throw new NoSuchElementException();
    }
    _currentIterator.value = newValue;
  }

  /**
   * Under the assumption that there are no more entries that can be returned using the current
   * iterator, advance to the next iterator that has entries.
   *
   * @return `true` if there is a current iterator that has entries
   */
  bool _advanceToNextIterator() {
    _iteratorIndex++;
    while (_iteratorIndex < _iterators.length) {
      MapIterator<K, V> iterator = _iterators[_iteratorIndex];
      if (iterator.moveNext()) {
        _currentIterator = iterator;
        return true;
      }
      _iteratorIndex++;
    }
    return false;
  }
}

/**
 * Instances of the class `TokenMap` map one set of tokens to another set of tokens.
 */
class TokenMap {
  /**
   * A table mapping tokens to tokens. This should be replaced by a more performant implementation.
   * One possibility is a pair of parallel arrays, with keys being sorted by their offset and a
   * cursor indicating where to start searching.
   */
  HashMap<Token, Token> _map = new HashMap<Token, Token>();

  /**
   * Return the token that is mapped to the given token, or `null` if there is no token
   * corresponding to the given token.
   *
   * @param key the token being mapped to another token
   * @return the token that is mapped to the given token
   */
  Token get(Token key) => _map[key];

  /**
   * Map the key to the value.
   *
   * @param key the token being mapped to the value
   * @param value the token to which the key will be mapped
   */
  void put(Token key, Token value) {
    _map[key] = value;
  }
}

/**
 * Instances of the class `SingleMapIterator` implement an iterator that can be used to access
 * the entries in a single map.
 */
class SingleMapIterator<K, V> implements MapIterator<K, V> {
  /**
   * Returns a new [SingleMapIterator] instance for the given [Map].
   */
  static SingleMapIterator forMap(Map map) => new SingleMapIterator(map);

  /**
   * The [Map] containing the entries to be iterated over.
   */
  final Map<K, V> _map;

  /**
   * The iterator used to access the entries.
   */
  Iterator<K> _keyIterator;

  /**
   * The current key, or `null` if there is no current key.
   */
  K _currentKey;

  /**
   * The current value.
   */
  V _currentValue;

  /**
   * Initialize a newly created iterator to return the entries from the given map.
   *
   * @param map the map containing the entries to be iterated over
   */
  SingleMapIterator(this._map) {
    this._keyIterator = _map.keys.iterator;
  }

  @override
  K get key {
    if (_currentKey == null) {
      throw new NoSuchElementException();
    }
    return _currentKey;
  }

  @override
  V get value {
    if (_currentKey == null) {
      throw new NoSuchElementException();
    }
    return _currentValue;
  }

  @override
  bool moveNext() {
    if (_keyIterator.moveNext()) {
      _currentKey = _keyIterator.current;
      _currentValue = _map[_currentKey];
      return true;
    } else {
      _currentKey = null;
      return false;
    }
  }

  @override
  void set value(V newValue) {
    if (_currentKey == null) {
      throw new NoSuchElementException();
    }
    _currentValue = newValue;
    _map[_currentKey] = newValue;
  }
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/arena.dart';

/// A single use of the result of the instruction in another instruction.
extension type const Use(ArenaPointer _ptr) {
  // Terminator in the use lists.
  static const Use Null = Use(ArenaPointer.Null);

  // Each use occupies 4 slots:
  // instruction index, definition index, next use, previous use.
  static const int instructionOffset = 0;
  static const int definitionOffset = 1;
  static const int nextOffset = 2;
  static const int previousOffset = 3;

  // Size of each use. Should be a power of 2 for efficiency.
  static const int useSize = 4;

  @pragma("vm:prefer-inline")
  void init(FlowGraph graph, Instruction instr) {
    setInstruction(graph, instr);
    setNext(graph, Use.Null);
    setPrevious(graph, Use.Null);
  }

  @pragma("vm:prefer-inline")
  Instruction getInstruction(FlowGraph graph) =>
      graph.instructions[graph[_ptr + instructionOffset]];

  @pragma("vm:prefer-inline")
  void setInstruction(FlowGraph graph, Instruction value) {
    graph[_ptr + instructionOffset] = value.id;
  }

  @pragma("vm:prefer-inline")
  Definition getDefinition(FlowGraph graph) =>
      graph.instructions[graph[_ptr + definitionOffset]] as Definition;

  @pragma("vm:prefer-inline")
  void setDefinition(FlowGraph graph, Definition value) {
    graph[_ptr + definitionOffset] = value.id;
  }

  @pragma("vm:prefer-inline")
  Use getNext(FlowGraph graph) => Use(ArenaPointer(graph[_ptr + nextOffset]));

  @pragma("vm:prefer-inline")
  void setNext(FlowGraph graph, Use value) {
    graph[_ptr + nextOffset] = value._ptr.toInt();
  }

  @pragma("vm:prefer-inline")
  Use getPrevious(FlowGraph graph) =>
      Use(ArenaPointer(graph[_ptr + previousOffset]));

  @pragma("vm:prefer-inline")
  void setPrevious(FlowGraph graph, Use value) {
    graph[_ptr + previousOffset] = value._ptr.toInt();
  }
}

/// Fixed-size array of uses.
extension type const UsesArray(ArenaPointer _ptr) {
  // Array has a length, followed by elements.
  static const int lengthOffset = 0;
  static const int elementsOffset = 1;

  int getLength(FlowGraph graph) {
    assert(_ptr != ArenaPointer.Null);
    return graph[_ptr + lengthOffset];
  }

  Use at(FlowGraph graph, int index) {
    assert(_ptr != ArenaPointer.Null);
    assert(0 <= index && index < getLength(graph));
    return Use(_ptr + elementsOffset + index * Use.useSize);
  }

  int indexOf(FlowGraph graph, Use use) {
    assert(_ptr != ArenaPointer.Null);
    final offset = use._ptr - (_ptr + elementsOffset);
    assert((offset % Use.useSize) == 0);
    final index = offset ~/ Use.useSize;
    assert(0 <= index && index < getLength(graph));
    return index;
  }

  void truncateTo(FlowGraph graph, int newLength) {
    assert(_ptr != ArenaPointer.Null);
    assert((0 <= newLength) && (newLength <= getLength(graph)));
    graph[_ptr + lengthOffset] = newLength;
  }

  static UsesArray allocate(FlowGraph graph, int length) {
    assert(length >= 0);
    final ptr = graph.allocate(elementsOffset + length * Use.useSize);
    graph[ptr + lengthOffset] = length;
    return UsesArray(ptr);
  }
}

class _UsesIterator implements Iterator<Use> {
  final FlowGraph graph;
  Use _current = Use.Null;
  Use _next;

  _UsesIterator(this.graph, this._next);

  @override
  bool moveNext() {
    _current = _next;
    _next = (_current != Use.Null) ? _current.getNext(graph) : Use.Null;
    return (_current != Use.Null);
  }

  @override
  Use get current => _current;
}

class UsesIterable extends Iterable<Use> {
  final FlowGraph graph;
  Use _first;

  UsesIterable(this.graph, this._first);
  UsesIterable.empty(this.graph) : _first = Use.Null;

  @override
  Iterator<Use> get iterator => _UsesIterator(graph, _first);
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/bit_vector.dart';

class Loops extends Iterable<Loop> {
  final FlowGraph graph;

  final List<Loop> _loops = [];

  /// Block preorder number -> innermost Loop.
  final List<Loop?> _loopByBlock;

  Loops._(this.graph)
    : _loopByBlock = List<Loop?>.filled(graph.preorder.length, null);

  Loop? operator [](Block block) => _loopByBlock[block.preorderNumber];

  void operator []=(Block block, Loop loop) {
    _loopByBlock[block.preorderNumber] = loop;
  }

  @override
  Iterator<Loop> get iterator => _loops.iterator;
}

/// Natural loop with one entrance to the loop header and
/// one or more back-edges.
class Loop {
  final Block header;
  final BitVector _body;
  final List<Block> backEdges = [];
  Loop? enclosingLoop;
  late final int depth = _computeDepth();

  Loop._(this.header) : _body = BitVector(header.graph.preorder.length);

  bool contains(Block block) => _body[block.preorderNumber];

  void add(Block block) {
    _body.add(block.preorderNumber);
  }

  /// Add all blocks between [header] and [backEdge].
  void addBody(Block backEdge) {
    final workList = <Block>[];
    add(header);
    if (backEdge != header) {
      add(backEdge);
      workList.add(backEdge);
    }
    while (workList.isNotEmpty) {
      final block = workList.removeLast();
      assert(block.isDominatedBy(header));
      for (final pred in block.predecessors) {
        if (!contains(pred)) {
          add(pred);
          workList.add(pred);
        }
      }
    }
  }

  Iterable<Block> get body => _LoopBodyIterable(this);

  int _computeDepth() {
    int depth = 0;
    for (Loop? loop = this; loop != null; loop = loop.enclosingLoop) {
      ++depth;
    }
    return depth;
  }
}

class _LoopBodyIterable extends Iterable<Block> {
  final Loop loop;
  _LoopBodyIterable(this.loop);

  @override
  Iterator<Block> get iterator =>
      _LoopBodyIterator(loop.header.graph, loop._body.elements.iterator);
}

class _LoopBodyIterator implements Iterator<Block> {
  final FlowGraph _graph;
  final Iterator<int> _bodyIterator;

  _LoopBodyIterator(this._graph, this._bodyIterator);

  @override
  bool moveNext() => _bodyIterator.moveNext();

  @override
  Block get current => _graph.preorder[_bodyIterator.current];
}

/// Compute loops.
Loops computeLoops(FlowGraph graph) {
  final loops = Loops._(graph);

  for (final block in graph.postorder) {
    if (block is JoinBlock && block.predecessors.length > 1) {
      for (final pred in block.predecessors) {
        if (pred.isDominatedBy(block)) {
          final loop = (loops[block] ??= Loop._(block));
          loop.addBody(pred);
          loop.backEdges.add(pred);
        }
      }
    }
  }

  for (final loop in loops) {
    for (final block in loop.body) {
      final innerLoop = loops[block];
      if (innerLoop == null) {
        loops[block] = loop;
      } else {
        assert(loop.contains(innerLoop.header));
      }
    }
  }

  for (final loop in loops) {
    final domLoop = loops[loop.header.dominator!];
    if (domLoop != null && domLoop.contains(loop.header)) {
      loop.enclosingLoop = domLoop;
    }
  }

  return loops;
}

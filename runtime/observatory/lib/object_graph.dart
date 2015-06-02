// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_graph;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:logging/logging.dart';

// Port of dart::ReadStream from vm/datastream.h.
class _ReadStream {
  int position = 0;
  int _size = 0;
  final List<ByteData> _chunks;

  _ReadStream(this._chunks) {
    int n = _chunks.length;
    for (var i = 0; i < n; i++) {
      var chunk = _chunks[i];
      if (i + 1 != n) {
        assert(chunk.lengthInBytes == (1 << 20));
      }
      _size += chunk.lengthInBytes;
    }
  }

  int get pendingBytes => _size - position;

  int getUint8(i) {
    return _chunks[i >> 20].getUint8(i & 0xFFFFF);
  }

  int readUnsigned() {
    int result = 0;
    int shift = 0;
    while (getUint8(position) <= maxUnsignedDataPerByte) {
      result |= getUint8(position) << shift;
      shift += dataBitsPerByte;
      position++;
    }
    result |= (getUint8(position) & byteMask) << shift;
    position++;
    return result;
  }

  static const int dataBitsPerByte = 7;
  static const int byteMask = (1 << dataBitsPerByte) - 1;
  static const int maxUnsignedDataPerByte = byteMask;
}

class ObjectVertex {
  // 0 represents invalid/uninitialized, 1 is the root.
  final int _id;
  final ObjectGraph _graph;

  ObjectVertex._(this._id, this._graph);

  bool get isRoot => _id == 1;

  bool operator ==(other) => _id == other._id && _graph == other._graph;
  int get hashCode => _id;

  int get retainedSize => _graph._retainedSizes[_id];
  ObjectVertex get dominator => new ObjectVertex._(_graph._doms[_id], _graph);

  int get shallowSize {
    var stream = new _ReadStream(_graph._chunks);
    stream.position = _graph._positions[_id];
    stream.readUnsigned(); // addr
    return stream.readUnsigned(); // shallowSize
  }

  int get vmCid {
    var stream = new _ReadStream(_graph._chunks);
    stream.position = _graph._positions[_id];
    stream.readUnsigned(); // addr
    stream.readUnsigned(); // shallowSize
    return stream.readUnsigned(); // cid
  }

  get successors => new _SuccessorsIterable(_graph, _id);

  int get address {
    // Note that everywhere else in this file, "address" really means an address
    // scaled down by kObjectAlignment. They were scaled down so they would fit
    // into Smis on the client.
    var stream = new _ReadStream(_graph._chunks);
    stream.position = _graph._positions[_id];
    var scaledAddr = stream.readUnsigned();
    return scaledAddr * _graph._kObjectAlignment;
  }

  List<ObjectVertex> dominatorTreeChildren() {
    var N = _graph._N;
    var doms = _graph._doms;

    var parentId = _id;
    var domChildren = [];

    for (var childId = 1; childId <= N; childId++) {
      if (doms[childId] == parentId) {
        domChildren.add(new ObjectVertex._(childId, _graph));
      }
    }

    return domChildren;
  }
}

class _SuccessorsIterable extends IterableBase<ObjectVertex> {
  final ObjectGraph _graph;
  final int _id;

  _SuccessorsIterable(this._graph, this._id);

  Iterator<ObjectVertex> get iterator => new _SuccessorsIterator(_graph, _id);
}

class _SuccessorsIterator implements Iterator<ObjectVertex> {
  final ObjectGraph _graph;
  _ReadStream _stream;

  ObjectVertex current;

  _SuccessorsIterator(this._graph, int id) {
    _stream = new _ReadStream(this._graph._chunks);
    _stream.position = _graph._positions[id];
    _stream.readUnsigned(); // addr
    _stream.readUnsigned(); // shallowSize
    var cid = _stream.readUnsigned();
    assert((cid & ~0xFFFF) == 0); // Sanity check: cid's are 16 bit.
  }

  bool moveNext() {
    while (true) {
      var nextAddr = _stream.readUnsigned();
      if (nextAddr == 0) return false;
      var nextId = _graph._addrToId[nextAddr];
      if (nextId == null) continue; // Reference to VM isolate's heap.
      current = new ObjectVertex._(nextId, _graph);
      return true;
    }
  }
}

class _VerticesIterable extends IterableBase<ObjectVertex> {
  final ObjectGraph _graph;

  _VerticesIterable(this._graph);

  Iterator<ObjectVertex> get iterator => new _VerticesIterator(_graph);
}

class _VerticesIterator implements Iterator<ObjectVertex> {
  final ObjectGraph _graph;

  int _nextId = 0;
  ObjectVertex current;

  _VerticesIterator(this._graph);

  bool moveNext() {
    if (_nextId == _graph._N) return false;
    current = new ObjectVertex._(_nextId++, _graph);
    return true;
  }
}

class ObjectGraph {
  ObjectGraph(List<ByteData> chunks, int nodeCount)
    : this._chunks = chunks
    , this._N = nodeCount;

  int get size => _size;
  int get vertexCount => _N;
  int get edgeCount => _E;

  ObjectVertex get root => new ObjectVertex._(1, this);
  Iterable<ObjectVertex> get vertices => new _VerticesIterable(this);

  Iterable<ObjectVertex> getMostRetained({int classId, int limit}) {
    List<ObjectVertex> _mostRetained =
      new List<ObjectVertex>.from(vertices.where((u) => !u.isRoot));
    _mostRetained.sort((u, v) => v.retainedSize - u.retainedSize);

    var result = _mostRetained;
    if (classId != null) {
      result = result.where((u) => u.vmCid == classId);
    }
    if (limit != null) {
      result = result.take(limit);
    }
    return result;
  }

  Future process(statusReporter) async {
    // We build futures here instead of marking the steps as async to avoid the
    // heavy lifting being inside a transformed method.

    statusReporter.add("Finding node positions...");
    await new Future(() => _buildPositions());

    statusReporter.add("Finding post order...");
    await new Future(() => _buildPostOrder());

    statusReporter.add("Finding predecessors...");
    await new Future(() => _buildPredecessors());

    statusReporter.add("Finding dominators...");
    await new Future(() => _buildDominators());

    _firstPreds = null;
    _preds = null;
    _postOrderIndices = null;

    statusReporter.add("Finding retained sizes...");
    await new Future(() => _calculateRetainedSizes());

    _postOrderOrdinals = null;

    statusReporter.add("Loaded");
    return this;
  }

  final List<ByteData> _chunks;

  int _kObjectAlignment;
  int _N;
  int _E;
  int _size;

  Map<int, int> _addrToId = new Map<int, int>();

  // Indexed by node id, with id 0 representing invalid/uninitialized.
  Uint32List _positions; // Position of the node in the snapshot.
  Uint32List _postOrderOrdinals; // post-order index -> id
  Uint32List _postOrderIndices; // id -> post-order index
  Uint32List _firstPreds; // Offset into preds.
  Uint32List _preds;
  Uint32List _doms;
  Uint32List _retainedSizes;

  void _buildPositions() {
    var N = _N;
    var addrToId = _addrToId;

    var positions = new Uint32List(N + 1);

    var stream = new _ReadStream(_chunks);
    _kObjectAlignment = stream.readUnsigned();

    var id = 1;
    while (stream.pendingBytes > 0) {
      positions[id] = stream.position;
      var addr = stream.readUnsigned();
      stream.readUnsigned(); // shallowSize
      stream.readUnsigned(); // cid
      addrToId[addr] = id;

      var succAddr = stream.readUnsigned();
      while (succAddr != 0) {
        succAddr = stream.readUnsigned();
      }
      id++;
    }
    assert(id == (N + 1));

    var root = addrToId[0];
    assert(root == 1);

    _positions = positions;
  }

  void _buildPostOrder() {
    var N = _N;
    var E = 0;
    var addrToId = _addrToId;
    var positions = _positions;

    var postOrderOrdinals = new Uint32List(N);
    var postOrderIndices = new Uint32List(N + 1);
    var stackNodes = new Uint32List(N);
    var stackCurrentEdgePos = new Uint32List(N);

    var visited = new Uint8List(N + 1);
    var postOrderIndex = 0;
    var stackTop = 0;
    var root = 1;

    stackNodes[0] = root;

    var stream = new _ReadStream(_chunks);
    stream.position = positions[root];
    stream.readUnsigned(); // addr
    stream.readUnsigned(); // shallowSize
    stream.readUnsigned(); // cid
    stackCurrentEdgePos[0] = stream.position;
    visited[root] = 1;

    while (stackTop >= 0) {
      var n = stackNodes[stackTop];
      var edgePos = stackCurrentEdgePos[stackTop];

      stream.position = edgePos;
      var childAddr = stream.readUnsigned();
      if (childAddr != 0) {
        stackCurrentEdgePos[stackTop] = stream.position;
        var childId = addrToId[childAddr];
        if (childId == null) continue; // Reference to VM isolate's heap.
        E++;
        if (visited[childId] == 1) continue;

        stackTop++;
        stackNodes[stackTop] = childId;

        stream.position = positions[childId];
        stream.readUnsigned(); // addr
        stream.readUnsigned(); // shallowSize
        stream.readUnsigned(); // cid
        stackCurrentEdgePos[stackTop] = stream.position; // i.e., first edge
        visited[childId] = 1;
      } else {
        // Done with all children.
        postOrderIndices[n] = postOrderIndex;
        postOrderOrdinals[postOrderIndex++] = n;
        stackTop--;
      }
    }

    assert(postOrderIndex == N);
    assert(postOrderOrdinals[N - 1] == root);

    _postOrderOrdinals = postOrderOrdinals;
    _postOrderIndices = postOrderIndices;
    _E = E;
  }

  void _buildPredecessors() {
    var N = _N;
    var E = _E;
    var addrToId = _addrToId;
    var positions = _positions;

    // This is first filled with the predecessor counts, then reused to hold the
    // offset to the first predecessor (see alias below).
    // + 1 because 0 is a sentinel
    // + 1 so the number of predecessors can be found from the difference with
    // the next node's offset.
    var numPreds = new Uint32List(N + 2);
    var preds = new Uint32List(E);

    // Count predecessors of each node.
    var stream = new _ReadStream(_chunks);
    for (var i = 1; i <= N; i++) {
      stream.position = positions[i];
      stream.readUnsigned(); // addr
      stream.readUnsigned(); // shallowSize
      stream.readUnsigned(); // cid
      var succAddr = stream.readUnsigned();
      while (succAddr != 0) {
        var succId = addrToId[succAddr];
        if (succId != null) {
          numPreds[succId]++;
        } else {
          // Reference to VM isolate's heap.
        }
        succAddr = stream.readUnsigned();
      }
    }

    // Assign indices into predecessors array.
    var firstPreds = numPreds;  // Alias.
    var nextPreds = new Uint32List(N + 1);
    var predIndex = 0;
    for (var i = 1; i <= N; i++) {
      var thisPredIndex = predIndex;
      predIndex += numPreds[i];
      firstPreds[i] = thisPredIndex;
      nextPreds[i] = thisPredIndex;
    }
    assert(predIndex == E);
    firstPreds[N + 1] = E; // Extra entry for cheap boundary detection.

    // Fill predecessors array.
    for (var i = 1; i <= N; i++) {
      stream.position = positions[i];
      stream.readUnsigned(); // addr
      stream.readUnsigned(); // shallowSize
      stream.readUnsigned(); // cid
      var succAddr = stream.readUnsigned();
      while (succAddr != 0) {
        var succId = addrToId[succAddr];
        if (succId != null) {
          var predIndex = nextPreds[succId]++;
          preds[predIndex] = i;
        } else {
          // Reference to VM isolate's heap.
        }
        succAddr = stream.readUnsigned();
      }
    }

    _firstPreds = firstPreds;
    _preds = preds;
  }

  // "A Simple, Fast Dominance Algorithm"
  // Keith D. Cooper, Timothy J. Harvey, and Ken Kennedy
  void _buildDominators() {
    var N = _N;

    var postOrder = _postOrderOrdinals;
    var postOrderIndex = _postOrderIndices;
    var firstPreds = _firstPreds;
    var preds = _preds;

    var root = 1;
    var rootPostOrderIndex = postOrderIndex[root];
    var domByPOI = new Uint32List(N + 1);

    domByPOI[rootPostOrderIndex] = rootPostOrderIndex;

    var iteration = 0;
    var changed = true;
    while (changed) {
      changed = false;
      Logger.root.info("Find dominators iteration $iteration");
      iteration++; // dart2js heaps typically converge in 10 iterations.

      // Visit the nodes, except the root, in reverse post order (top down).
      for (var curPostOrderIndex = rootPostOrderIndex - 1;
           curPostOrderIndex > 1;
           curPostOrderIndex--) {
        if (domByPOI[curPostOrderIndex] == rootPostOrderIndex)
          continue;

        var nodeOrdinal = postOrder[curPostOrderIndex];
        var newDomIndex = 0; // 0 = undefined

        // Intersect the DOM sets of the node's precedessors.
        var beginPredIndex = firstPreds[nodeOrdinal];
        var endPredIndex = firstPreds[nodeOrdinal + 1];
        for (var predIndex = beginPredIndex;
             predIndex < endPredIndex;
             predIndex++) {
          var predOrdinal = preds[predIndex];
          var predPostOrderIndex = postOrderIndex[predOrdinal];
          if (domByPOI[predPostOrderIndex] != 0) {
            if (newDomIndex == 0) {
              newDomIndex = predPostOrderIndex;
            } else {
              // Note this two finger algorithm to find the DOM intersection
              // relies on comparing nodes by their post order index.
              while (predPostOrderIndex != newDomIndex) {
                while(predPostOrderIndex < newDomIndex)
                  predPostOrderIndex = domByPOI[predPostOrderIndex];
                while (newDomIndex < predPostOrderIndex)
                  newDomIndex = domByPOI[newDomIndex];
              }
            }
            if (newDomIndex == rootPostOrderIndex) {
              break;
            }
          }
        }
        if (newDomIndex != 0 && domByPOI[curPostOrderIndex] != newDomIndex) {
          domByPOI[curPostOrderIndex] = newDomIndex;
          changed = true;
        }
      }
    }

    // Reindex doms by id instead of post order index so we can throw away
    // the post order arrays.
    var domById = new Uint32List(N + 1);
    for (var id = 1; id <= N; id++) {
      domById[id] = postOrder[domByPOI[postOrderIndex[id]]];
    }

    domById[root] = 0;

    _doms = domById;
  }

  void _calculateRetainedSizes() {
    var N = _N;

    var size = 0;
    var positions = _positions;
    var postOrderOrdinals = _postOrderOrdinals;
    var doms = _doms;
    var retainedSizes = new Uint32List(N + 1);

    // Start with retained size as shallow size.
    var reader = new _ReadStream(_chunks);
    for (var i = 1; i <= N; i++) {
      reader.position = positions[i];
      reader.readUnsigned(); // addr
      var shallowSize = reader.readUnsigned();
      retainedSizes[i] = shallowSize;
      size += shallowSize;
    }

    // In post order (bottom up), add retained size to dominator's retained
    // size, skipping root.
    for (var o = 0; o < (N - 1); o++) {
      var i = postOrderOrdinals[o];
      assert(i != 1);
      retainedSizes[doms[i]] += retainedSizes[i];
    }

    _retainedSizes = retainedSizes;
    _size = size;
  }
}

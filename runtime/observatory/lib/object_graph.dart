// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_graph;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:logging/logging.dart';

class _JenkinsSmiHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash3(a, b, c) => finish(combine(combine(combine(0, a), b), c));
}

// Map<[uint32, uint32, uint32], uint32>
class AddressMapper {
  final Uint32List _table;

  // * 4 ~/3 for 75% load factor
  // * 4 for four-tuple entries
  AddressMapper(int N) : _table = new Uint32List((N * 4 ~/ 3) * 4);

  int _scanFor(int high, int mid, int low) {
    var hash = _JenkinsSmiHash.hash3(high, mid, low);
    var start = (hash % _table.length) & ~3;
    var index = start;
    do {
      if (_table[index + 3] == 0) return index;
      if (_table[index] == high &&
          _table[index + 1] == mid &&
          _table[index + 2] == low) return index;
      index = (index + 4) % _table.length;
    } while (index != start);

    throw new Exception("Interal error: table full");
  }

  int get(int high, int mid, int low) {
    int index = _scanFor(high, mid, low);
    if (_table[index + 3] == 0) return null;
    return _table[index + 3];
  }

  int put(int high, int mid, int low, int id) {
    if (id == 0) throw new Exception("Internal error: invalid id");

    int index = _scanFor(high, mid, low);
    if ((_table[index + 3] != 0)) {
      throw new Exception("Internal error: attempt to overwrite key");
    }
    _table[index] = high;
    _table[index + 1] = mid;
    _table[index + 2] = low;
    _table[index + 3] = id;
    return id;
  }
}


// Port of dart::ReadStream from vm/datastream.h.
//
// The heap snapshot is a series of variable-length unsigned integers. For
// each byte in the stream, the high bit marks the last byte of an integer and
// the low 7 bits are the payload. The payloads are sent in little endian
// order.
// The largest values used are 64-bit addresses.
// We read in 4 payload chunks (28-bits) to stay in Smi range on Javascript.
// We read them into instance variables ('low', 'mid' and 'high') to avoid
// allocating a container.
class ReadStream {
  int position = 0;
  int _size = 0;
  final List<ByteData> _chunks;

  ReadStream(this._chunks) {
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

  int _getUint8(i) {
    return _chunks[i >> 20].getUint8(i & 0xFFFFF);
  }

  int low = 0;
  int mid = 0;
  int high = 0;

  int get clampedUint32 {
    if (high != 0 || mid > 0xF) {
      return 0xFFFFFFFF;
    } else {
      // Not shift as JS shifts are signed 32-bit.
      return mid * 0x10000000 + low;
    }
  }

  int get highUint32 {
    return high * (1 << 24) + (mid >> 4);
  }

  int get lowUint32 {
    return (mid & 0xF) * (1 << 28) + low;
  }

  bool get isZero {
    return (high == 0) && (mid == 0) && (low == 0);
  }

  void readUnsigned() {
    low = 0;
    mid = 0;
    high = 0;

    // Low 28 bits.
    var digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      low |= (digit & byteMask << 0);
      return;
    }
    low |= (digit << 0);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      low |= ((digit & byteMask) << 7);
      return;
    }
    low |= (digit << 7);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      low |= ((digit & byteMask) << 14);
      return;
    }
    low |= (digit << 14);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      low |= ((digit & byteMask) << 21);
      return;
    }
    low |= (digit << 21);

    // Mid 28 bits.
    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      mid |= (digit & byteMask << 0);
      return;
    }
    mid |= (digit << 0);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      mid |= ((digit & byteMask) << 7);
      return;
    }
    mid |= (digit << 7);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      mid |= ((digit & byteMask) << 14);
      return;
    }
    mid |= (digit << 14);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      mid |= ((digit & byteMask) << 21);
      return;
    }
    mid |= (digit << 21);

    // High 28 bits.
    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      high |= (digit & byteMask << 0);
      return;
    }
    high |= (digit << 0);

    digit = _getUint8(position++);
    if (digit > maxUnsignedDataPerByte) {
      high |= ((digit & byteMask) << 7);
      return;
    }
    high |= (digit << 7);
    throw new Exception("Format error: snapshot field exceeds 64 bits");
  }

  void skipUnsigned() {
    while (_getUint8(position++) <= maxUnsignedDataPerByte);
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

  int get shallowSize => _graph._shallowSizes[_id];
  int get vmCid => _graph._cids[_id];

  get successors => new _SuccessorsIterable(_graph, _id);

  String get address {
    // Note that everywhere else in this file, "address" really means an address
    // scaled down by kObjectAlignment. They were scaled down so they would fit
    // into Smis on the client.

    var high32 = _graph._addressesHigh[_id];
    var low32 = _graph._addressesLow[_id];

    // Complicated way to do (high:low * _kObjectAlignment).toHexString()
    // without intermediate values exceeding int32.

    var strAddr = "";
    var carry = 0;
    combine4(nibble) {
      nibble = nibble * _graph._kObjectAlignment + carry;
      carry = nibble >> 4;
      nibble = nibble & 0xF;
      strAddr = nibble.toRadixString(16) + strAddr;
    }
    combine32(thirtyTwoBits) {
      for (int shift = 0; shift < 32; shift += 4) {
        combine4((thirtyTwoBits >> shift) & 0xF);
      }
    }
    combine32(low32);
    combine32(high32);
    return strAddr;
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
  int _nextSuccIndex;
  int _limitSuccIndex;

  ObjectVertex current;

  _SuccessorsIterator(this._graph, int id) {
    _nextSuccIndex = _graph._firstSuccs[id];
    _limitSuccIndex = _graph._firstSuccs[id + 1];
  }

  bool moveNext() {
    if (_nextSuccIndex < _limitSuccIndex) {
      var succId = _graph._succs[_nextSuccIndex++];
      current = new ObjectVertex._(succId, _graph);
      return true;
    }
    return false;
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

    statusReporter.add("Remapping $_N objects...");
    await new Future(() => _remapNodes());

    statusReporter.add("Remapping $_E references...");
    await new Future(() => _remapEdges());

    _addrToId = null;
    _chunks = null;

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

  List<ByteData> _chunks;

  int _kObjectAlignment;
  int _N;
  int _E;
  int _size;

  // Indexed by node id, with id 0 representing invalid/uninitialized.
  // From snapshot.
  Uint16List _cids;
  Uint32List _shallowSizes;
  Uint32List _firstSuccs;
  Uint32List _succs;
  Uint32List _addressesLow; // No Uint64List in Javascript.
  Uint32List _addressesHigh;

  // Intermediates.
  AddressMapper _addrToId;
  Uint32List _postOrderOrdinals; // post-order index -> id
  Uint32List _postOrderIndices; // id -> post-order index
  Uint32List _firstPreds; // Offset into preds.
  Uint32List _preds;

  // Outputs.
  Uint32List _doms;
  Uint32List _retainedSizes;

  void _remapNodes() {
    var N = _N;
    var E = 0;
    var addrToId = new AddressMapper(N);

    var addressesHigh = new Uint32List(N + 1);
    var addressesLow = new Uint32List(N + 1);
    var shallowSizes = new Uint32List(N + 1);
    var cids = new Uint16List(N + 1);

    var stream = new ReadStream(_chunks);
    stream.readUnsigned();
    _kObjectAlignment = stream.clampedUint32;

    var id = 1;
    while (stream.pendingBytes > 0) {
      stream.readUnsigned(); // addr
      addrToId.put(stream.high, stream.mid, stream.low, id);
      addressesHigh[id] = stream.highUint32;
      addressesLow[id] = stream.lowUint32;
      stream.readUnsigned(); // shallowSize
      shallowSizes[id] = stream.clampedUint32;
      stream.readUnsigned(); // cid
      cids[id] = stream.clampedUint32;

      stream.readUnsigned();
      while (!stream.isZero) {
        E++;
        stream.readUnsigned();
      }
      id++;
    }
    assert(id == (N + 1));

    var root = addrToId.get(0, 0, 0);
    assert(root == 1);

    _E = E;
    _addrToId = addrToId;
    _addressesLow = addressesLow;
    _addressesHigh = addressesHigh;
    _shallowSizes = shallowSizes;
    _cids = cids;
  }

  void _remapEdges() {
    var N = _N;
    var E = _E;
    var addrToId = _addrToId;

    var firstSuccs = new Uint32List(N + 2);
    var succs = new Uint32List(E);

    var stream = new ReadStream(_chunks);
    stream.skipUnsigned(); // addr alignment

    var id = 1, edge = 0;
    while (stream.pendingBytes > 0) {
      stream.skipUnsigned(); // addr
      stream.skipUnsigned(); // shallowSize
      stream.skipUnsigned(); // cid

      firstSuccs[id] = edge;

      stream.readUnsigned();
      while (!stream.isZero) {
        var childId = addrToId.get(stream.high, stream.mid, stream.low);
        if (childId != null) {
          succs[edge] = childId;
          edge++;
        } else { 
          // Reference into VM isolate's heap.
        }
        stream.readUnsigned();
      }
      id++;
    }
    firstSuccs[id] = edge; // Extra entry for cheap boundary detection.

    assert(id == N + 1);
    assert(edge <= E); // edge is smaller because E was computed before we knew
                       // if references pointed into the VM isolate

    _E = edge;
    _firstSuccs = firstSuccs;
    _succs = succs;
  }

  void _buildPostOrder() {
    var N = _N;
    var E = _E;
    var firstSuccs = _firstSuccs;
    var succs = _succs;

    var postOrderOrdinals = new Uint32List(N);
    var postOrderIndices = new Uint32List(N + 1);
    var stackNodes = new Uint32List(N);
    var stackCurrentEdgePos = new Uint32List(N);

    var visited = new Uint8List(N + 1);
    var postOrderIndex = 0;
    var stackTop = 0;
    var root = 1;

    stackNodes[0] = root;
    stackCurrentEdgePos[0] = firstSuccs[root];
    visited[root] = 1;

    while (stackTop >= 0) {
      var n = stackNodes[stackTop];
      var edgePos = stackCurrentEdgePos[stackTop];

      if (edgePos < firstSuccs[n + 1]) {
        var childId = succs[edgePos];
        edgePos++;
        stackCurrentEdgePos[stackTop] = edgePos;
        if (visited[childId] == 1) continue;

        // Push child.
        stackTop++;
        stackNodes[stackTop] = childId;
        edgePos = firstSuccs[childId];
        stackCurrentEdgePos[stackTop] = edgePos;
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
    var firstSuccs = _firstSuccs;
    var succs = _succs;

    // This is first filled with the predecessor counts, then reused to hold the
    // offset to the first predecessor (see alias below).
    // + 1 because 0 is a sentinel
    // + 1 so the number of predecessors can be found from the difference with
    // the next node's offset.
    var numPreds = new Uint32List(N + 2);
    var preds = new Uint32List(E);

    // Count predecessors of each node.
    for (var succIndex = 0; succIndex < E; succIndex++) {
      var succId = succs[succIndex];
      numPreds[succId]++;
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
      var startSuccIndex = firstSuccs[i];
      var limitSuccIndex = firstSuccs[i + 1];
      for (var succIndex = startSuccIndex;
           succIndex < limitSuccIndex;
           succIndex++) {
        var succId = succs[succIndex];
        var predIndex = nextPreds[succId]++;
        preds[predIndex] = i;
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

    Logger.root.info("Start remap dominators");

    // Reindex doms by id instead of post order index so we can throw away
    // the post order arrays.
    var domById = new Uint32List(N + 1);
    for (var id = 1; id <= N; id++) {
      domById[id] = postOrder[domByPOI[postOrderIndex[id]]];
    }

    Logger.root.info("End remap dominators");

    domById[root] = 0;

    _doms = domById;
  }

  void _calculateRetainedSizes() {
    var N = _N;

    var size = 0;
    var shallowSizes = _shallowSizes;
    var postOrderOrdinals = _postOrderOrdinals;
    var doms = _doms;

    // Sum shallow sizes.
    for (var i = 1; i < N; i++) {
      size += shallowSizes[i];
    }

    // Start with retained size as shallow size.
    var retainedSizes = new Uint32List.fromList(shallowSizes);

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

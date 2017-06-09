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
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
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

// Node indices for the root and sentinel nodes. Note that using 0 as the
// sentinel means a newly allocated typed array comes initialized with all
// elements as the sentinel.
const ROOT = 1;
const SENTINEL = 0;

class ObjectVertex {
  final int _id;
  final ObjectGraph _graph;

  ObjectVertex._(this._id, this._graph);

  bool get isRoot => ROOT == _id;
  bool get isStack => vmCid == _graph._kStackCid;

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

    for (var childId = ROOT; childId <= N; childId++) {
      if (doms[childId] == parentId) {
        domChildren.add(new ObjectVertex._(childId, _graph));
      }
    }

    return domChildren;
  }
}

// A node in the dominator tree where siblings with the same class are merged.
// That is, a set of objects with the same cid whose parent chains in the
// dominator tree have the same cids at each level. [id_] is the representative
// object of this set. The other members of the set are found by walking the
// mergedDomNext links until finding the sentinel node or a node with a
// different class.
class MergedObjectVertex {
  final int _id;
  final ObjectGraph _graph;

  MergedObjectVertex._(this._id, this._graph);

  bool get isRoot => ROOT == _id;
  bool get isStack => vmCid == _graph._kStackCid;

  bool operator ==(other) => _id == other._id && _graph == other._graph;
  int get hashCode => _id;

  int get vmCid => _graph._cids[_id];

  int get shallowSize {
    var cids = _graph._cids;
    var size = 0;
    var sibling = _id;
    while (sibling != SENTINEL && cids[sibling] == cids[_id]) {
      size += _graph._shallowSizes[sibling];
      sibling = _graph._mergedDomNext[sibling];
    }
    return size;
  }

  int get retainedSize {
    var cids = _graph._cids;
    var size = 0;
    var sibling = _id;
    while (sibling != SENTINEL && cids[sibling] == cids[_id]) {
      size += _graph._retainedSizes[sibling];
      sibling = _graph._mergedDomNext[sibling];
    }
    return size;
  }

  int get instanceCount {
    var cids = _graph._cids;
    var count = 0;
    var sibling = _id;
    while (sibling != SENTINEL && cids[sibling] == cids[_id]) {
      count++;
      sibling = _graph._mergedDomNext[sibling];
    }
    return count;
  }

  List<MergedObjectVertex> dominatorTreeChildren() {
    var next = _graph._mergedDomNext;
    var cids = _graph._cids;

    var domChildren = [];
    var prev = SENTINEL;
    var child = _graph._mergedDomHead[_id];
    // Walk the list of children and look for the representative objects, i.e.
    // the first sibling of each cid.
    while (child != SENTINEL) {
      if (prev == SENTINEL || cids[prev] != cids[child]) {
        domChildren.add(new MergedObjectVertex._(child, _graph));
      }
      prev = child;
      child = next[child];
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
      : this._chunks = chunks,
        this._N = nodeCount;

  int get size => _size;
  int get vertexCount => _N;
  int get edgeCount => _E;

  ObjectVertex get root => new ObjectVertex._(ROOT, this);
  MergedObjectVertex get mergedRoot => new MergedObjectVertex._(ROOT, this);
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

  Stream<List> process() {
    final controller = new StreamController<List>.broadcast();
    (() async {
      // We build futures here instead of marking the steps as async to avoid the
      // heavy lifting being inside a transformed method.

      controller.add(["Remapping $_N objects...", 0.0]);
      await new Future(() => _remapNodes());

      controller.add(["Remapping $_E references...", 15.0]);
      await new Future(() => _remapEdges());

      _addrToId = null;
      _chunks = null;

      controller.add(["Finding depth-first order...", 30.0]);
      await new Future(() => _dfs());

      controller.add(["Finding predecessors...", 40.0]);
      await new Future(() => _buildPredecessors());

      controller.add(["Finding dominators...", 50.0]);
      await new Future(() => _buildDominators());

      _firstPreds = null;
      _preds = null;

      _semi = null;
      _parent = null;

      controller.add(["Finding retained sizes...", 60.0]);
      await new Future(() => _calculateRetainedSizes());

      _vertex = null;

      controller.add(["Linking dominator tree children...", 70.0]);
      await new Future(() => _linkDominatorChildren());

      controller.add(["Sorting dominator tree children...", 80.0]);
      await new Future(() => _sortDominatorChildren());

      controller.add(["Merging dominator tree siblings...", 90.0]);
      await new Future(() => _mergeDominatorSiblings());

      controller.add(["Processed", 100.0]);
      controller.close();
    }());
    return controller.stream;
  }

  List<ByteData> _chunks;

  int _kObjectAlignment;
  int _kStackCid;
  int _N; // Objects in the snapshot.
  int _Nconnected; // Objects reachable from root.
  int _E; // References in the snapshot.
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
  Uint32List _vertex;
  Uint32List _parent;
  Uint32List _semi;
  Uint32List _firstPreds; // Offset into preds.
  Uint32List _preds;

  // Outputs.
  Uint32List _doms;
  Uint32List _retainedSizes;
  Uint32List _mergedDomHead;
  Uint32List _mergedDomNext;

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
    stream.readUnsigned();
    _kStackCid = stream.clampedUint32;

    var id = ROOT;
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

    assert(ROOT == addrToId.get(0, 0, 0));

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
    stream.skipUnsigned(); // kObjectAlignment
    stream.skipUnsigned(); // kStackCid

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
          throw new Exception(
              "Heap snapshot contains an edge but lacks its target node");
        }
        stream.readUnsigned();
      }
      id++;
    }
    firstSuccs[id] = edge; // Extra entry for cheap boundary detection.

    assert(id == N + 1);
    assert(edge == E);

    _E = edge;
    _firstSuccs = firstSuccs;
    _succs = succs;
  }

  void _dfs() {
    var N = _N;
    var firstSuccs = _firstSuccs;
    var succs = _succs;

    var stackNodes = new Uint32List(N);
    var stackCurrentEdgePos = new Uint32List(N);

    var vertex = new Uint32List(N + 1);
    var semi = new Uint32List(N + 1);
    var parent = new Uint32List(N + 1);
    var dfsNumber = 0;

    var stackTop = 0;

    // Push root.
    stackNodes[0] = ROOT;
    stackCurrentEdgePos[0] = firstSuccs[ROOT];

    while (stackTop >= 0) {
      var v = stackNodes[stackTop];
      var edgePos = stackCurrentEdgePos[stackTop];

      if (semi[v] == 0) {
        // First visit.
        dfsNumber++;
        semi[v] = dfsNumber;
        vertex[dfsNumber] = v;
      }

      if (edgePos < firstSuccs[v + 1]) {
        var childId = succs[edgePos];
        edgePos++;
        stackCurrentEdgePos[stackTop] = edgePos;

        if (semi[childId] == 0) {
          parent[childId] = v;

          // Push child.
          stackTop++;
          stackNodes[stackTop] = childId;
          stackCurrentEdgePos[stackTop] = firstSuccs[childId];
        }
      } else {
        // Done with all children.
        stackTop--;
      }
    }

    if (dfsNumber != N) {
      // This may happen in filtered snapshots.
      Logger.root.warning('Heap snapshot contains unreachable nodes.');
    }

    assert(() {
      for (var i = 1; i <= dfsNumber; i++) {
        var v = vertex[i];
        assert(semi[v] != SENTINEL);
      }
      assert(parent[1] == SENTINEL);
      for (var i = 2; i <= dfsNumber; i++) {
        var v = vertex[i];
        assert(parent[v] != SENTINEL);
      }
      return true;
    });

    if (dfsNumber != N) {
      // Remove successors of unconnected nodes
      for (var i = ROOT + 1; i <= N; i++) {
        if (parent[i] == SENTINEL) {
          var startSuccIndex = firstSuccs[i];
          var limitSuccIndex = firstSuccs[i + 1];
          for (var succIndex = startSuccIndex;
              succIndex < limitSuccIndex;
              succIndex++) {
            succs[succIndex] = SENTINEL;
          }
        }
      }
    }

    _Nconnected = dfsNumber;
    _vertex = vertex;
    _semi = semi;
    _parent = parent;
  }

  void _buildPredecessors() {
    var N = _N;
    var Nconnected = _Nconnected;
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
      if (succId != SENTINEL) {
        numPreds[succId]++;
      }
    }

    // Assign indices into predecessors array.
    var firstPreds = numPreds; // Alias.
    var nextPreds = new Uint32List(N + 1);
    var predIndex = 0;
    for (var i = 1; i <= N; i++) {
      var thisPredIndex = predIndex;
      predIndex += numPreds[i];
      firstPreds[i] = thisPredIndex;
      nextPreds[i] = thisPredIndex;
    }
    if (N == Nconnected) {
      assert(predIndex == E);
    }
    firstPreds[N + 1] = predIndex; // Extra entry for cheap boundary detection.

    // Fill predecessors array.
    for (var i = 1; i <= N; i++) {
      var startSuccIndex = firstSuccs[i];
      var limitSuccIndex = firstSuccs[i + 1];
      for (var succIndex = startSuccIndex;
          succIndex < limitSuccIndex;
          succIndex++) {
        var succId = succs[succIndex];
        if (succId != SENTINEL) {
          var predIndex = nextPreds[succId]++;
          preds[predIndex] = i;
        }
      }
    }

    _firstPreds = firstPreds;
    _preds = preds;
  }

  static int _eval(int v, Uint32List ancestor, Uint32List semi,
      Uint32List label, Uint32List stackNode, Uint8List stackState) {
    if (ancestor[v] == SENTINEL) {
      return label[v];
    } else {
      {
        // Inlined 'compress' with an explicit stack to prevent JS stack
        // overflow.
        var top = 0;
        stackNode[top] = v;
        stackState[top] = 0;
        while (top >= 0) {
          var v = stackNode[top];
          var state = stackState[top];
          if (state == 0) {
            assert(ancestor[v] != 0);
            if (ancestor[ancestor[v]] != 0) {
              stackState[top] = 1;
              // Recurse with ancestor[v]
              top++;
              stackNode[top] = ancestor[v];
              stackState[top] = 0;
            } else {
              top--;
            }
          } else {
            assert(state == 1);
            if (semi[label[ancestor[v]]] < semi[label[v]]) {
              label[v] = label[ancestor[v]];
            }
            ancestor[v] = ancestor[ancestor[v]];
            top--;
          }
        }
      }

      if (semi[label[ancestor[v]]] >= semi[label[v]]) {
        return label[v];
      } else {
        return label[ancestor[v]];
      }
    }
  }

  // Note the version in the main text of Lengauer & Tarjan incorrectly
  // uses parent instead of ancestor. The correct version is in Appendix B.
  static void _link(int v, int w, Uint32List size, Uint32List label,
      Uint32List semi, Uint32List child, Uint32List ancestor) {
    assert(size[0] == 0);
    assert(label[0] == 0);
    assert(semi[0] == 0);
    var s = w;
    while (semi[label[w]] < semi[label[child[s]]]) {
      if (size[s] + size[child[child[s]]] >= 2 * size[child[s]]) {
        ancestor[child[s]] = s;
        child[s] = child[child[s]];
      } else {
        size[child[s]] = size[s];
        s = ancestor[s] = child[s];
      }
    }
    label[s] = label[w];
    size[v] = size[v] + size[w];
    if (size[v] < 2 * size[w]) {
      var tmp = s;
      s = child[v];
      child[v] = tmp;
    }
    while (s != 0) {
      ancestor[s] = v;
      s = child[s];
    }
  }

  // T. Lengauer and R. E. Tarjan. "A Fast Algorithm for Finding Dominators
  // in a Flowgraph."
  void _buildDominators() {
    var N = _N;
    var Nconnected = _Nconnected;

    var vertex = _vertex;
    var semi = _semi;
    var parent = _parent;
    var firstPreds = _firstPreds;
    var preds = _preds;

    var dom = new Uint32List(N + 1);

    var ancestor = new Uint32List(N + 1);
    var label = new Uint32List(N + 1);
    for (var i = 1; i <= N; i++) {
      label[i] = i;
    }
    var buckets = new List(N + 1);
    var child = new Uint32List(N + 1);
    var size = new Uint32List(N + 1);
    for (var i = 1; i <= N; i++) {
      size[i] = 1;
    }
    var stackNode = new Uint32List(N + 1);
    var stackState = new Uint8List(N + 1);

    for (var i = Nconnected; i > 1; i--) {
      var w = vertex[i];
      assert(w != ROOT);

      // Lengauer & Tarjan Step 2.
      var startPred = firstPreds[w];
      var limitPred = firstPreds[w + 1];
      for (var predIndex = startPred; predIndex < limitPred; predIndex++) {
        var v = preds[predIndex];
        var u = _eval(v, ancestor, semi, label, stackNode, stackState);
        if (semi[u] < semi[w]) {
          semi[w] = semi[u];
        }
      }

      // w.semi.bucket.add(w);
      var tmp = vertex[semi[w]];
      if (buckets[tmp] == null) {
        buckets[tmp] = new List();
      }
      buckets[tmp].add(w);

      _link(parent[w], w, size, label, semi, child, ancestor);

      // Lengauer & Tarjan Step 3.
      tmp = parent[w];
      var bucket = buckets[tmp];
      buckets[tmp] = null;
      if (bucket != null) {
        for (var v in bucket) {
          var u = _eval(v, ancestor, semi, label, stackNode, stackState);
          dom[v] = semi[u] < semi[v] ? u : parent[w];
        }
      }
    }
    for (var i = ROOT; i <= N; i++) {
      assert(buckets[i] == null);
    }
    // Lengauer & Tarjan Step 4.
    for (var i = 2; i <= Nconnected; i++) {
      var w = vertex[i];
      if (dom[w] != vertex[semi[w]]) {
        dom[w] = dom[dom[w]];
      }
    }

    _doms = dom;
  }

  void _calculateRetainedSizes() {
    var Nconnected = _Nconnected;

    var size = 0;
    var shallowSizes = _shallowSizes;
    var vertex = _vertex;
    var doms = _doms;

    // Sum shallow sizes.
    for (var i = 1; i <= Nconnected; i++) {
      var v = vertex[i];
      size += shallowSizes[v];
    }

    // Start with retained size as shallow size.
    var retainedSizes = new Uint32List.fromList(shallowSizes);

    // In post order (bottom up), add retained size to dominator's retained
    // size, skipping root.
    for (var i = Nconnected; i > 1; i--) {
      var v = vertex[i];
      assert(v != ROOT);
      retainedSizes[doms[v]] += retainedSizes[v];
    }

    assert(retainedSizes[ROOT] == size); // Root retains everything.

    _retainedSizes = retainedSizes;
    _size = size;
  }

  // Build linked lists of the children for each node in the dominator tree.
  void _linkDominatorChildren() {
    var N = _N;
    var doms = _doms;
    var head = new Uint32List(N + 1);
    var next = new Uint32List(N + 1);

    for (var child = ROOT; child <= N; child++) {
      var parent = doms[child];
      next[child] = head[parent];
      head[parent] = child;
    }

    _mergedDomHead = head;
    _mergedDomNext = next;
  }

  // Merge the given lists according to the given key in ascending order.
  // Returns the head of the merged list.
  static int _mergeSorted(
      int head1, int head2, Uint32List next, Uint16List key) {
    var head = head1;
    var beforeInsert = SENTINEL;
    var afterInsert = head1;
    var startInsert = head2;

    while (startInsert != SENTINEL) {
      while (
          (afterInsert != SENTINEL) && (key[afterInsert] <= key[startInsert])) {
        beforeInsert = afterInsert;
        afterInsert = next[beforeInsert];
      }

      var endInsert = startInsert;
      var peek = next[endInsert];

      while ((peek != SENTINEL) && (key[peek] < key[afterInsert])) {
        endInsert = peek;
        peek = next[endInsert];
      }
      assert(endInsert != SENTINEL);

      if (beforeInsert == SENTINEL) {
        head = startInsert;
      } else {
        next[beforeInsert] = startInsert;
      }
      next[endInsert] = afterInsert;

      startInsert = peek;
      beforeInsert = endInsert;
    }

    return head;
  }

  void _sortDominatorChildren() {
    var N = _N;
    var cids = _cids;
    var head = _mergedDomHead;
    var next = _mergedDomNext;

    // Returns the new head of the sorted list.
    int sort(int head) {
      if (head == SENTINEL) return SENTINEL;
      if (next[head] == SENTINEL) return head;

      // Find the middle of the list.
      int head1 = head;
      int slow = head;
      int fast = head;
      while (next[fast] != SENTINEL && next[next[fast]] != SENTINEL) {
        slow = next[slow];
        fast = next[next[fast]];
      }

      // Split the list in half.
      int head2 = next[slow];
      next[slow] = SENTINEL;

      // Recursively sort the sublists and merge.
      assert(head1 != head2);
      int newHead1 = sort(head1);
      int newHead2 = sort(head2);
      return _mergeSorted(newHead1, newHead2, next, cids);
    }

    // Sort all list of dominator tree children by cid.
    for (var parent = ROOT; parent <= N; parent++) {
      head[parent] = sort(head[parent]);
    }
  }

  void _mergeDominatorSiblings() {
    var N = _N;
    var cids = _cids;
    var head = _mergedDomHead;
    var next = _mergedDomNext;
    var workStack = new Uint32List(N);
    var workStackTop = 0;

    mergeChildrenAndSort(var parent1, var end) {
      assert(parent1 != SENTINEL);
      if (next[parent1] == end) return;

      // Find the middle of the list.
      int slow = parent1;
      int fast = parent1;
      while (next[fast] != end && next[next[fast]] != end) {
        slow = next[slow];
        fast = next[next[fast]];
      }

      int parent2 = next[slow];

      assert(parent2 != SENTINEL);
      assert(parent1 != parent2);
      assert(cids[parent1] == cids[parent2]);

      // Recursively sort the sublists.
      mergeChildrenAndSort(parent1, parent2);
      mergeChildrenAndSort(parent2, end);

      // Merge sorted sublists.
      head[parent1] = _mergeSorted(head[parent1], head[parent2], next, cids);

      // Children moved to parent1.
      head[parent2] = SENTINEL;
    }

    // Push root.
    workStack[workStackTop++] = ROOT;

    while (workStackTop > 0) {
      var parent = workStack[--workStackTop];

      var child = head[parent];
      while (child != SENTINEL) {
        // Push child.
        workStack[workStackTop++] = child;

        // Find next sibling with a different cid.
        var after = child;
        while (after != SENTINEL && cids[after] == cids[child]) {
          after = next[after];
        }

        // From all the siblings between child and after, take their children,
        // merge them and given to child.
        mergeChildrenAndSort(child, after);

        child = after;
      }
    }
  }
}

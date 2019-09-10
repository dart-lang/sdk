// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_graph;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';

class _ReadStream {
  final Uint8List _buffer;
  int _position = 0;

  _ReadStream(this._buffer);

  int readByte() => _buffer[_position++];

  /// Read one ULEB128 number.
  int readUnsigned() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = readByte();
      result |= (part & 0x7F) << shift;
      if ((part & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return result;
  }

  /// Read one SLEB128 number.
  int readSigned() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = readByte();
      result |= (part & 0x7F) << shift;
      shift += 7;
      if ((part & 0x80) == 0) {
        if ((part & 0x40) != 0) {
          result |= (-1 << shift);
        }
        break;
      }
    }
    return result;
  }

  double readFloat64() {
    var bytes = new Uint8List(8);
    for (var i = 0; i < 8; i++) {
      bytes[i] = readByte();
    }
    return new Float64List.view(bytes.buffer)[0];
  }

  String readUtf8() {
    int len = readUnsigned();
    var bytes = new Uint8List(len);
    for (var i = 0; i < len; i++) {
      bytes[i] = readByte();
    }
    return new Utf8Codec(allowMalformed: true).decode(bytes);
  }

  String readLatin1() {
    int len = readUnsigned();
    var codeUnits = new Uint8List(len);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = readByte();
    }
    return new String.fromCharCodes(codeUnits);
  }

  String readUtf16() {
    int len = readUnsigned();
    var codeUnits = new Uint16List(len);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = readByte() | (readByte() << 8);
    }
    return new String.fromCharCodes(codeUnits);
  }
}

// Node indices for the root and sentinel nodes. Note that using 0 as the
// sentinel means a newly allocated typed array comes initialized with all
// elements as the sentinel.
const ROOT = 1;
const SENTINEL = 0;

abstract class SnapshotObject {
  String get label;
  String get description;
  SnapshotClass get klass;
  int get shallowSize;
  int get externalSize;
  int get retainedSize;
  Iterable<SnapshotObject> get successors;
  Iterable<SnapshotObject> get predecessors;
  SnapshotObject get parent;
  Iterable<SnapshotObject> get children;
  List<SnapshotObject> get objects;
}

class _SnapshotObject implements SnapshotObject {
  final int _id;
  final _SnapshotGraph _graph;
  final String label;

  _SnapshotObject._(this._id, this._graph, this.label);

  bool operator ==(other) {
    if (other is _SnapshotObject) {
      return _id == other._id && _graph == other._graph;
    }
    return false;
  }

  int get hashCode => _id;

  int get shallowSize => _graph._shallowSizes[_id];
  int get externalSize => _graph._externalSizes[_id];
  int get retainedSize => _graph._retainedSizes[_id];

  String get description => _graph._describeObject(_id);
  SnapshotClass get klass => _graph._classes[_graph._cids[_id]];

  Iterable<SnapshotObject> get successors =>
      new _SuccessorsIterable(_graph, _id);

  Iterable<SnapshotObject> get predecessors {
    var result = new List<SnapshotObject>();
    var firstSuccs = _graph._firstSuccs;
    var succs = _graph._succs;
    var id = _id;
    var N = _graph._N;
    for (var predId = 1; predId <= N; predId++) {
      var base = firstSuccs[predId];
      var limit = firstSuccs[predId + 1];
      for (var i = base; i < limit; i++) {
        if (succs[i] == id) {
          var cid = _graph._cids[predId];
          var name = _graph._edgeName(cid, i - base);
          result.add(new _SnapshotObject._(predId, _graph, name));
        }
      }
    }
    return result;
  }

  SnapshotObject get parent {
    if (_id == ROOT) {
      return this;
    }
    return new _SnapshotObject._(_graph._doms[_id], _graph, "");
  }

  Iterable<SnapshotObject> get children {
    var N = _graph._N;
    var doms = _graph._doms;

    var parentId = _id;
    var domChildren = <SnapshotObject>[];

    for (var childId = ROOT; childId <= N; childId++) {
      if (doms[childId] == parentId) {
        domChildren.add(new _SnapshotObject._(childId, _graph, ""));
      }
    }

    return domChildren;
  }

  List<SnapshotObject> get objects => <SnapshotObject>[this];
}

// A node in the dominator tree where siblings with the same class are merged.
// That is, a set of objects with the same cid whose parent chains in the
// dominator tree have the same cids at each level. [id_] is the representative
// object of this set. The other members of the set are found by walking the
// mergedDomNext links until finding the sentinel node or a node with a
// different class.
class MergedObjectVertex {
  final int _id;
  final _SnapshotGraph _graph;

  MergedObjectVertex._(this._id, this._graph);

  bool get isRoot => ROOT == _id;

  bool operator ==(other) => _id == other._id && _graph == other._graph;
  int get hashCode => _id;

  SnapshotClass get klass => _graph._classes[_graph._cids[_id]];

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

  int get externalSize {
    var cids = _graph._cids;
    var size = 0;
    var sibling = _id;
    while (sibling != SENTINEL && cids[sibling] == cids[_id]) {
      size += _graph._externalSizes[sibling];
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

  List<SnapshotObject> get objects {
    var result = <SnapshotObject>[];
    var cids = _graph._cids;
    var sibling = _id;
    while (sibling != SENTINEL && cids[sibling] == cids[_id]) {
      result.add(new _SnapshotObject._(sibling, _graph, ""));
      sibling = _graph._mergedDomNext[sibling];
    }
    return result;
  }

  List<MergedObjectVertex> dominatorTreeChildren() {
    var next = _graph._mergedDomNext;
    var cids = _graph._cids;

    var domChildren = <MergedObjectVertex>[];
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

class _SuccessorsIterable extends IterableBase<SnapshotObject> {
  final _SnapshotGraph _graph;
  final int _id;

  _SuccessorsIterable(this._graph, this._id);

  Iterator<SnapshotObject> get iterator => new _SuccessorsIterator(_graph, _id);
}

class _SuccessorsIterator implements Iterator<SnapshotObject> {
  final _SnapshotGraph _graph;
  int _cid;
  int _startSuccIndex;
  int _nextSuccIndex;
  int _limitSuccIndex;

  SnapshotObject current;

  _SuccessorsIterator(this._graph, int id) {
    _cid = _graph._cids[id];
    _startSuccIndex = _graph._firstSuccs[id];
    _nextSuccIndex = _startSuccIndex;
    _limitSuccIndex = _graph._firstSuccs[id + 1];
  }

  bool moveNext() {
    if (_nextSuccIndex < _limitSuccIndex) {
      var index = _nextSuccIndex - _startSuccIndex;
      var succId = _graph._succs[_nextSuccIndex++];
      var name = _graph._edgeName(_cid, index);
      current = new _SnapshotObject._(succId, _graph, name);
      return true;
    }
    return false;
  }
}

class _VerticesIterable extends IterableBase<SnapshotObject> {
  final _SnapshotGraph _graph;

  _VerticesIterable(this._graph);

  Iterator<SnapshotObject> get iterator => new _VerticesIterator(_graph);
}

class _VerticesIterator implements Iterator<SnapshotObject> {
  final _SnapshotGraph _graph;

  int _nextId = 0;
  SnapshotObject current;

  _VerticesIterator(this._graph);

  bool moveNext() {
    if (_nextId == _graph._N) return false;
    current = new _SnapshotObject._(_nextId++, _graph, "");
    return true;
  }
}

class _InstancesIterable extends IterableBase<SnapshotObject> {
  final _SnapshotGraph _graph;
  final int _cid;

  _InstancesIterable(this._graph, this._cid);

  Iterator<SnapshotObject> get iterator => new _InstancesIterator(_graph, _cid);
}

class _InstancesIterator implements Iterator<SnapshotObject> {
  final _SnapshotGraph _graph;
  final int _cid;

  int _nextId = 0;
  SnapshotObject current;

  _InstancesIterator(this._graph, this._cid);

  bool moveNext() {
    while (_nextId < _graph._N) {
      if (_graph._cids[_nextId] == _cid) {
        current = new _SnapshotObject._(_nextId++, _graph, "");
        return true;
      }
      _nextId++;
    }
    return false;
  }
}

abstract class SnapshotClass {
  String get name;
  int get externalSize;
  int get shallowSize;
  int get ownedSize;
  int get instanceCount;
  Iterable<SnapshotObject> get instances;
}

class _SnapshotClass implements SnapshotClass {
  final _SnapshotGraph _graph;
  final int _cid;
  final String name;
  final String libName;
  final String libUri;
  final Map<int, String> fields = new Map<int, String>();

  int totalExternalSize = 0;
  int totalShallowSize = 0;
  int totalInstanceCount = 0;

  int ownedSize = 0;

  int liveExternalSize = 0;
  int liveShallowSize = 0;
  int liveInstanceCount = 0;

  int get shallowSize => liveShallowSize;
  int get externalSize => liveExternalSize;
  int get instanceCount => liveInstanceCount;

  Iterable<SnapshotObject> get instances =>
      new _InstancesIterable(_graph, _cid);

  _SnapshotClass(this._graph, this._cid, this.name, this.libName, this.libUri);
}

abstract class SnapshotGraph {
  int get shallowSize;
  int get externalSize;
  int get size;
  int get capacity;

  SnapshotObject get root;
  MergedObjectVertex get mergedRoot;
  Iterable<SnapshotClass> get classes;
  Iterable<SnapshotObject> get objects;

  factory SnapshotGraph(Uint8List encoded) => new _SnapshotGraph(encoded);
  Stream<String> process();
}

const kNoData = 0;
const kNullData = 1;
const kBoolData = 2;
const kIntData = 3;
const kDoubleData = 4;
const kLatin1Data = 5;
const kUtf16Data = 6;
const kLengthData = 7;
const kNameData = 8;

const kSentinelName = "<omitted-object>";
const kRootName = "Root";
const kUnknownFieldName = "<unknown>";

class _SnapshotGraph implements SnapshotGraph {
  _SnapshotGraph(Uint8List encoded) : this._encoded = encoded;

  int get size => _liveShallowSize + _liveExternalSize;
  int get shallowSize => _liveShallowSize;
  int get externalSize => _liveExternalSize;
  int get capacity => _capacity;

  SnapshotObject get root => new _SnapshotObject._(ROOT, this, "Root");
  MergedObjectVertex get mergedRoot => new MergedObjectVertex._(ROOT, this);
  Iterable<SnapshotObject> get objects => new _VerticesIterable(this);

  String _describeObject(int oid) {
    if (oid == SENTINEL) {
      return kSentinelName;
    }
    if (oid == ROOT) {
      return kRootName;
    }
    var cls = _className(oid);
    var data = _nonReferenceData[oid];
    if (data == null) {
      return cls;
    } else {
      return "$cls($data)";
    }
  }

  String _className(int oid) {
    var cid = _cids[oid];
    var cls = _classes[cid];
    if (cls == null) {
      return "Class$cid";
    }
    return cls.name;
  }

  String _edgeName(int cid, int index) {
    var c = _classes[cid];
    if (c == null) {
      return kUnknownFieldName;
    }
    var n = c.fields[index];
    if (n == null) {
      return kUnknownFieldName;
    }
    return n;
  }

  List<SnapshotClass> get classes {
    var result = new List<SnapshotClass>();
    for (var c in _classes) {
      if (c != null) {
        result.add(c);
      }
    }
    return result;
  }

  Stream<String> process() {
    final controller = new StreamController<String>.broadcast();
    (() async {
      // We build futures here instead of marking the steps as async to avoid the
      // heavy lifting being inside a transformed method.
      var stream = new _ReadStream(_encoded);
      _encoded = null;

      controller.add("Loading classes...");
      await new Future(() => _readClasses(stream));

      controller.add("Loading objects...");
      await new Future(() => _readObjects(stream));

      controller.add("Loading external properties...");
      await new Future(() => _readExternalProperties(stream));
      stream = null;

      controller.add("Compute class table...");
      await new Future(() => _computeClassTable());

      controller.add("Finding depth-first order...");
      await new Future(() => _dfs());

      controller.add("Finding predecessors...");
      await new Future(() => _buildPredecessors());

      controller.add("Finding dominators...");
      await new Future(() => _buildDominators());

      _semi = null;
      _parent = null;

      controller.add("Finding in-degree(1) groups...");
      await new Future(() => _buildOwnedSizes());

      _firstPreds = null;
      _preds = null;

      controller.add("Finding retained sizes...");
      await new Future(() => _calculateRetainedSizes());

      _vertex = null;

      controller.add("Linking dominator tree children...");
      await new Future(() => _linkDominatorChildren());

      controller.add("Sorting dominator tree children...");
      await new Future(() => _sortDominatorChildren());

      controller.add("Merging dominator tree siblings...");
      await new Future(() => _mergeDominatorSiblings());

      controller.add("Loaded");
      controller.close();
    }());
    return controller.stream;
  }

  Uint8List _encoded;

  int _kStackCid;
  int _kFieldCid;
  int _numCids;
  int _N; // Objects in the snapshot.
  int _Nconnected; // Objects reachable from root.
  int _E; // References in the snapshot.

  int _capacity;
  int _liveShallowSize;
  int _liveExternalSize;
  int _totalShallowSize;
  int _totalExternalSize;

  List<_SnapshotClass> _classes;

  // Indexed by node id, with id 0 representing invalid/uninitialized.
  // From snapshot.
  List _nonReferenceData;
  Uint16List _cids;
  Uint32List _shallowSizes;
  Uint32List _externalSizes;
  Uint32List _firstSuccs;
  Uint32List _succs;

  // Intermediates.
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

  void _readClasses(_ReadStream stream) {
    for (var i = 0; i < 8; i++) {
      stream.readByte(); // Magic value.
    }
    stream.readUnsigned(); // Flags
    stream.readUtf8(); // Name

    _totalShallowSize = stream.readUnsigned();
    _capacity = stream.readUnsigned();
    _totalExternalSize = stream.readUnsigned();

    var K = stream.readUnsigned();
    var classes = new List<_SnapshotClass>(K + 1);
    classes[0] = new _SnapshotClass(this, 0, "Root", "", "");

    for (var cid = 1; cid <= K; cid++) {
      int flags = stream.readUnsigned();
      String name = stream.readUtf8();
      String libName = stream.readUtf8();
      String libUri = stream.readUtf8();
      String reserved = stream.readUtf8();
      final cls = new _SnapshotClass(this, cid, name, libName, libUri);
      int edgeCount = stream.readUnsigned();
      for (int i = 0; i < edgeCount; i++) {
        int flags = stream.readUnsigned();
        int index = stream.readUnsigned();
        String fieldName = stream.readUtf8();
        String reserved = stream.readUtf8();
        cls.fields[index] = fieldName;
      }
      classes[cid] = cls;
    }

    _numCids = K;
    _classes = classes;
  }

  void _readObjects(_ReadStream stream) {
    var E = stream.readUnsigned();
    var N = stream.readUnsigned();

    _N = N;
    _E = E;

    var shallowSizes = new Uint32List(N + 1);
    var cids = new Uint16List(N + 1);
    var nonReferenceData = new List(N + 1);
    var firstSuccs = new Uint32List(N + 2);
    var succs = new Uint32List(E);
    var eid = 0;
    for (var oid = 1; oid <= N; oid++) {
      var cid = stream.readUnsigned();
      cids[oid] = cid;

      var shallowSize = stream.readUnsigned();
      shallowSizes[oid] = shallowSize;

      var nonReferenceDataTag = stream.readUnsigned();
      switch (nonReferenceDataTag) {
        case kNoData:
          break;
        case kNullData:
          nonReferenceData[oid] = "null";
          break;
        case kBoolData:
          nonReferenceData[oid] = stream.readByte() != 0;
          break;
        case kIntData:
          nonReferenceData[oid] = stream.readSigned();
          break;
        case kDoubleData:
          nonReferenceData[oid] = stream.readFloat64();
          break;
        case kLatin1Data:
          var len = stream.readUnsigned();
          var str = stream.readLatin1();
          if (str.length < len) {
            nonReferenceData[oid] = '$str...';
          } else {
            nonReferenceData[oid] = str;
          }
          break;
        case kUtf16Data:
          int len = stream.readUnsigned();
          var str = stream.readUtf16();
          if (str.length < len) {
            nonReferenceData[oid] = '$str...';
          } else {
            nonReferenceData[oid] = str;
          }
          break;
        case kLengthData:
          nonReferenceData[oid] = stream.readUnsigned(); // Length
          break;
        case kNameData:
          nonReferenceData[oid] = stream.readUtf8(); // Name
          break;
        default:
          throw "Unknown tag $nonReferenceDataTag";
      }

      firstSuccs[oid] = eid;
      var referenceCount = stream.readUnsigned();
      while (referenceCount > 0) {
        var childOid = stream.readUnsigned();
        succs[eid] = childOid;
        eid++;
        referenceCount--;
      }
    }
    firstSuccs[N + 1] = eid;

    assert(eid <= E);
    _E = eid;
    _shallowSizes = shallowSizes;
    _cids = cids;
    _nonReferenceData = nonReferenceData;
    _firstSuccs = firstSuccs;
    _succs = succs;
  }

  void _readExternalProperties(_ReadStream stream) {
    var N = _N;
    var externalPropertyCount = stream.readUnsigned();

    var externalSizes = new Uint32List(N + 1);
    for (var i = 0; i < externalPropertyCount; i++) {
      var oid = stream.readUnsigned();
      var externalSize = stream.readUnsigned();
      var name = stream.readUtf8();
      externalSizes[oid] += externalSize;
    }

    _externalSizes = externalSizes;
  }

  void _computeClassTable() {
    var N = _N;
    var classes = _classes;
    var cids = _cids;
    var shallowSizes = _shallowSizes;
    var externalSizes = _externalSizes;
    var totalShallowSize = 0;
    var totalExternalSize = 0;

    for (var oid = 1; oid <= N; oid++) {
      var shallowSize = shallowSizes[oid];
      totalShallowSize += shallowSize;

      var externalSize = externalSizes[oid];
      totalExternalSize += externalSize;

      var cls = classes[cids[oid]];
      cls.totalShallowSize += shallowSize;
      cls.totalExternalSize += externalSize;
      cls.totalInstanceCount++;
    }

    _totalShallowSize = totalShallowSize;
    _totalExternalSize = totalExternalSize;
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

        if (childId == SENTINEL) {
          // Omitted target.
        } else if (semi[childId] == 0) {
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
      Logger.root.warning(
          'Heap snapshot contains ${N - dfsNumber} unreachable nodes.');
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
    }());

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

  // Fold the size of any object with in-degree(1) into its parent.
  // Requires the DFS numbering and predecessor lists.
  void _buildOwnedSizes() {
    var N = _N;
    var Nconnected = _Nconnected;
    var kStackCid = _kStackCid;
    var kFieldCid = _kFieldCid;

    var cids = _cids;
    var shallowSizes = _shallowSizes;
    var externalSizes = _externalSizes;
    var vertex = _vertex;
    var firstPreds = _firstPreds;
    var preds = _preds;

    var ownedSizes = new Uint32List(N + 1);
    for (var i = 1; i <= Nconnected; i++) {
      var v = vertex[i];
      ownedSizes[v] = shallowSizes[v] + externalSizes[v];
    }

    for (var i = Nconnected; i > 1; i--) {
      var w = vertex[i];
      assert(w != ROOT);

      var onlyPred = SENTINEL;

      var startPred = firstPreds[w];
      var limitPred = firstPreds[w + 1];
      for (var predIndex = startPred; predIndex < limitPred; predIndex++) {
        var v = preds[predIndex];
        if (v == w) {
          // Ignore self-predecessor.
        } else if (onlyPred == SENTINEL) {
          onlyPred = v;
        } else if (onlyPred == v) {
          // Repeated predecessor.
        } else {
          // Multiple-predecessors.
          onlyPred = SENTINEL;
          break;
        }
      }

      // If this object has a single precessor which is not a Field, Stack or
      // the root, blame its size against the precessor.
      if ((onlyPred != SENTINEL) &&
          (onlyPred != ROOT) &&
          (cids[onlyPred] != kStackCid) &&
          (cids[onlyPred] != kFieldCid)) {
        assert(onlyPred != w);
        ownedSizes[onlyPred] += ownedSizes[w];
        ownedSizes[w] = 0;
      }
    }

    // TODO(rmacnak): Maybe keep the per-objects sizes to be able to provide
    // examples of large owners for each class.
    var classes = _classes;
    for (var i = 1; i <= Nconnected; i++) {
      var v = vertex[i];
      var cid = cids[v];
      var cls = classes[cid];
      cls.ownedSize += ownedSizes[v];
    }
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
    var N = _N;
    var Nconnected = _Nconnected;

    var liveShallowSize = 0;
    var liveExternalSize = 0;
    var classes = _classes;
    var cids = _cids;
    var shallowSizes = _shallowSizes;
    var externalSizes = _externalSizes;
    var vertex = _vertex;
    var doms = _doms;

    // Sum internal and external sizes.
    for (var i = 1; i <= Nconnected; i++) {
      var v = vertex[i];
      var shallowSize = shallowSizes[v];
      var externalSize = externalSizes[v];
      liveShallowSize += shallowSize;
      liveExternalSize += externalSize;

      var cls = classes[cids[v]];
      cls.liveShallowSize += shallowSize;
      cls.liveExternalSize += externalSize;
      cls.liveInstanceCount++;
    }

    // Start with retained size as shallow size + external size.
    var retainedSizes = new Uint32List(N + 1);
    for (var i = 0; i < N + 1; i++) {
      retainedSizes[i] = shallowSizes[i] + externalSizes[i];
    }

    // In post order (bottom up), add retained size to dominator's retained
    // size, skipping root.
    for (var i = Nconnected; i > 1; i--) {
      var v = vertex[i];
      assert(v != ROOT);
      retainedSizes[doms[v]] += retainedSizes[v];
    }

    // Root retains everything.
    assert(retainedSizes[ROOT] == (liveShallowSize + liveExternalSize));

    _retainedSizes = retainedSizes;
    _liveShallowSize = liveShallowSize;
    _liveExternalSize = liveExternalSize;

    Logger.root
        .info("internal-garbage: ${_totalShallowSize - _liveShallowSize}");
    Logger.root
        .info("external-garbage: ${_totalExternalSize - _liveExternalSize}");
    Logger.root.info("fragmentation: ${_capacity - _totalShallowSize}");
    assert(_liveShallowSize <= _totalShallowSize);
    assert(_totalShallowSize <= _capacity);
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

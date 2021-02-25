// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_graph;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Decodes and analyzes heap snapshots produced by the Dart VM.
abstract class SnapshotReader {
  factory SnapshotReader() => _SnapshotReader._new();

  void add(Uint8List chunk);
  Future<SnapshotGraph> close();

  Future<SnapshotGraph> get done;
  Stream<String> get onProgress;
}

class _SnapshotReader implements SnapshotReader {
  bool _closed = false;
  List<Uint8List>? _chunks = <Uint8List>[];
  final _onProgress = new StreamController<String>.broadcast();
  final _done = new Completer<SnapshotGraph>();

  _SnapshotReader._new();

  void add(Uint8List chunk) {
    if (_closed) {
      throw new StateError("Stream is closed");
    }
    _chunks!.add(chunk);
    _onProgress.add("Receiving snapshot chunk ${_chunks!.length}...");

    // TODO(rmacnak): Incremental loading.
  }

  Future<SnapshotGraph> close() {
    if (_closed) {
      throw new StateError("Stream is closed");
    }
    _closed = true;

    var graph = new _SnapshotGraph._new();
    var chunks = _chunks!;
    _chunks = null; // Let the binary chunks be GCable.
    _done.complete(graph._load(chunks, _onProgress));
    return _done.future;
  }

  Future<SnapshotGraph> get done => _done.future;
  Stream<String> get onProgress => _onProgress.stream;
}

Uint8List _newUint8Array(int size) {
  try {
    return new Uint8List(size);
  } on ArgumentError catch (e) {
    // JS throws a misleading invalid argument error. Convert to a more user-friendly message.
    throw new Exception(
        "OutOfMemoryError: Not enough memory available to analyze the snapshot.");
  }
}

Uint16List _newUint16Array(int size) {
  try {
    return new Uint16List(size);
  } on ArgumentError catch (e) {
    // JS throws a misleading invalid argument error. Convert to a more user-friendly message.
    throw new Exception(
        "OutOfMemoryError: Not enough memory available to analyze the snapshot.");
  }
}

Uint32List _newUint32Array(int size) {
  try {
    return new Uint32List(size);
  } on ArgumentError catch (e) {
    // JS throws a misleading invalid argument error. Convert to a more user-friendly message.
    throw new Exception(
        "OutOfMemoryError: Not enough memory available to analyze the snapshot.");
  }
}

class _ReadStream {
  final List<Uint8List> _buffers;
  Uint8List _currentBuffer = Uint8List(0);
  int _bufferIndex = 0;
  int _byteIndex = 0;

  _ReadStream._new(this._buffers);

  bool atEnd() {
    return _bufferIndex >= _buffers.length &&
        _byteIndex >= _currentBuffer.length;
  }

  int readByte() {
    int i = _byteIndex;
    Uint8List b = _currentBuffer;
    if (i < b.length) {
      int r = b[i];
      _byteIndex = i + 1;
      return r;
    }

    return _readByteSlowPath();
  }

  int _readByteSlowPath() {
    int i = _byteIndex;
    Uint8List b = _currentBuffer;
    while (i >= b.length) {
      if (_bufferIndex >= _buffers.length) {
        throw new StateError("Attempt to read past the end of a stream");
      }
      b = _currentBuffer = _buffers[_bufferIndex++];
      i = 0;
    }
    int r = b[i];
    _byteIndex = i + 1;
    return r;
  }

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
    final bytes = _newUint8Array(8);
    for (var i = 0; i < 8; i++) {
      bytes[i] = readByte();
    }
    return new Float64List.view(bytes.buffer)[0];
  }

  String readUtf8() {
    final len = readUnsigned();
    final bytes = _newUint8Array(len);
    for (var i = 0; i < len; i++) {
      bytes[i] = readByte();
    }
    return new Utf8Codec(allowMalformed: true).decode(bytes);
  }

  String readLatin1() {
    final len = readUnsigned();
    final codeUnits = _newUint8Array(len);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = readByte();
    }
    return new String.fromCharCodes(codeUnits);
  }

  String readUtf16() {
    final len = readUnsigned();
    final codeUnits = _newUint16Array(len);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = readByte() | (readByte() << 8);
    }
    return new String.fromCharCodes(codeUnits);
  }
}

// Node indices for the root and sentinel nodes. Note that using 0 as the
// sentinel means a newly allocated typed array comes initialized with all
// elements as the sentinel.
const _ROOT = 1;
const _SENTINEL = 0;

/// An object in a heap snapshot.
abstract class SnapshotObject {
  // If this object has been obtained from [successors] or [predecessors], the
  // name of slot. Otherwise, the empty string.
  String get label;

  // The value for primitives. Otherwise, the class name.
  String get description;

  /// [internalSize] + [externalSize].
  int get shallowSize;

  /// The number of bytes in the Dart heap occupied by this object. May be 0
  /// for objects that are in another heap but referenced from the heap of
  /// interest. May also be 0 for synthetic objects such as the root.
  int get internalSize;

  /// The sum of all external allocations associated with this object.
  /// See Dart_NewFinalizableHandle and Dart_NewWeakPersistentHandle.
  int get externalSize;

  /// The [shallowSize] of this object, plus the retainedSize of all its
  /// children in the dominator tree. This is the amount of memory that would
  /// be freed if the last reference to this object was erased.
  int get retainedSize;

  SnapshotClass get klass;

  /// The objects directly referenced by this object. The [SnapshotObject]s
  /// returned by this iterable have their [label] set to name of the slot
  /// if it is available.
  Iterable<SnapshotObject> get successors;

  /// The objects directly referencing this object. The [SnapshotObject]s
  /// returned by this iterable have their [label] set to name of the slot
  /// if it is available.
  Iterable<SnapshotObject> get predecessors;

  /// The immediate dominator of this object. For the root object, returns self.
  ///
  /// See https://en.wikipedia.org/wiki/Dominator_(graph_theory).
  SnapshotObject get parent;

  /// The objects for which this object is the immediate dominator.
  ///
  /// See https://en.wikipedia.org/wiki/Dominator_(graph_theory).
  Iterable<SnapshotObject> get children;

  /// An iterable containing only this object. For polymorphism with
  /// SnapshotMergedDominators.
  Iterable<SnapshotObject> get objects;
}

class _SnapshotObject implements SnapshotObject {
  final int _id;
  final _SnapshotGraph _graph;
  final String label;

  _SnapshotObject._new(this._id, this._graph, this.label);

  bool operator ==(Object other) {
    if (other is _SnapshotObject) {
      return _id == other._id && _graph == other._graph;
    }
    return false;
  }

  int get hashCode => _id ^ _graph.hashCode;

  int get shallowSize => internalSize + externalSize;
  int get internalSize => _graph._internalSizes![_id];
  int get externalSize => _graph._externalSizes![_id];
  int get retainedSize => _graph._retainedSizes![_id];

  String get description => _graph._describeObject(_id);
  SnapshotClass get klass => _graph._classes![_graph._cids![_id]]!;

  Iterable<SnapshotObject> get successors sync* {
    final id = _id;
    final cid = _graph._cids![id];
    final startSuccIndex = _graph._firstSuccs![id];
    final limitSuccIndex = _graph._firstSuccs![id + 1];
    for (var nextSuccIndex = startSuccIndex;
        nextSuccIndex < limitSuccIndex;
        nextSuccIndex++) {
      final index = nextSuccIndex - startSuccIndex;
      final succId = _graph._succs![nextSuccIndex];
      final name = _graph._edgeName(cid, index);
      yield _SnapshotObject._new(succId, _graph, name);
    }
  }

  Iterable<SnapshotObject> get predecessors sync* {
    var firstSuccs = _graph._firstSuccs!;
    var succs = _graph._succs!;
    var id = _id;
    var N = _graph._N!;
    for (var predId = 1; predId <= N; predId++) {
      var base = firstSuccs[predId];
      var limit = firstSuccs[predId + 1];
      for (var i = base; i < limit; i++) {
        if (succs[i] == id) {
          var cid = _graph._cids![predId];
          var name = _graph._edgeName(cid, i - base);
          yield _SnapshotObject._new(predId, _graph, name);
        }
      }
    }
  }

  SnapshotObject get parent {
    if (_id == _ROOT) {
      return this;
    }
    return _SnapshotObject._new(_graph._doms![_id], _graph, "");
  }

  Iterable<SnapshotObject> get children sync* {
    var N = _graph._N!;
    var doms = _graph._doms!;
    var parentId = _id;
    for (var childId = _ROOT; childId <= N; childId++) {
      if (doms[childId] == parentId) {
        yield _SnapshotObject._new(childId, _graph, "");
      }
    }
  }

  Iterable<SnapshotObject> get objects sync* {
    yield this;
  }
}

class _SyntheticSnapshotObject implements SnapshotObject {
  late String _description;
  late SnapshotClass _klass;
  late int _internalSize;
  late int _externalSize;
  late int _retainedSize;
  late List<SnapshotObject> _successors;
  late List<SnapshotObject> _predecessors;
  late SnapshotObject _parent;
  late List<SnapshotObject> _children;

  String get label => "";
  String get description => _description;
  SnapshotClass get klass => _klass;

  int get shallowSize => internalSize + externalSize;
  int get internalSize => _internalSize;
  int get externalSize => _externalSize;
  int get retainedSize => _retainedSize;

  Iterable<SnapshotObject> get successors => _successors;
  Iterable<SnapshotObject> get predecessors => _predecessors;
  SnapshotObject get parent => _parent;
  Iterable<SnapshotObject> get children => _children;

  Iterable<SnapshotObject> get objects sync* {
    yield this;
  }
}

/// A set of sibling objects in the graph's dominator tree that have the same
/// class.
abstract class SnapshotMergedDominator {
  SnapshotClass get klass;

  /// "n instances of Class".
  String get description;

  /// [internalSize] + [externalSize].
  int get shallowSize;

  /// The sum of [internalSize] for all objects in this set.
  int get internalSize;

  /// The sum of [externalSize] for all objects in this set.
  int get externalSize;

  /// The sum of [externalSize] for all objects in this set.
  /// This is the amount of memory that would be freed if all references to
  /// objects in this set were erased.
  int get retainedSize;

  /// The number of objects in this set. Polymorphic with
  /// [SnapshotClass.instanceCount].
  int get instanceCount;

  SnapshotMergedDominator get parent;
  Iterable<SnapshotMergedDominator> get children;

  Iterable<SnapshotObject> get objects;
}

// A node in the dominator tree where siblings with the same class are merged.
// That is, a set of objects with the same cid whose parent chains in the
// dominator tree have the same cids at each level. [id_] is the representative
// object of this set. The other members of the set are found by walking the
// mergedDomNext links until finding the sentinel node or a node with a
// different class.
class _SnapshotMergedDominator implements SnapshotMergedDominator {
  final int _id;
  final _SnapshotGraph _graph;
  final _SnapshotMergedDominator? _parent;

  _SnapshotMergedDominator._new(this._id, this._graph, this._parent);

  bool operator ==(Object other) {
    if (other is _SnapshotMergedDominator) {
      return _id == other._id && _graph == other._graph;
    }
    return false;
  }

  int get hashCode => _id ^ _graph.hashCode;

  String get description {
    return _id == _ROOT
        ? "Live Objects + External"
        : "$instanceCount instances of ${klass.name}";
  }

  SnapshotClass get klass => _graph._classes![_graph._cids![_id]]!;

  int get shallowSize => internalSize + externalSize;

  int get internalSize {
    var cids = _graph._cids!;
    var internalSizes = _graph._internalSizes!;
    var mergedDomNext = _graph._mergedDomNext!;
    var size = 0;
    var sibling = _id;
    while (sibling != _SENTINEL && cids[sibling] == cids[_id]) {
      size += internalSizes[sibling];
      sibling = mergedDomNext[sibling];
    }
    return size;
  }

  int get externalSize {
    var cids = _graph._cids!;
    var externalSizes = _graph._externalSizes!;
    var mergedDomNext = _graph._mergedDomNext!;
    var size = 0;
    var sibling = _id;
    while (sibling != _SENTINEL && cids[sibling] == cids[_id]) {
      size += externalSizes[sibling];
      sibling = mergedDomNext[sibling];
    }
    return size;
  }

  int get retainedSize {
    var cids = _graph._cids!;
    var retainedSizes = _graph._retainedSizes!;
    var mergedDomNext = _graph._mergedDomNext!;
    var size = 0;
    var sibling = _id;
    while (sibling != _SENTINEL && cids[sibling] == cids[_id]) {
      size += retainedSizes[sibling];
      sibling = mergedDomNext[sibling];
    }
    return size;
  }

  int get instanceCount {
    var cids = _graph._cids!;
    var mergedDomNext = _graph._mergedDomNext!;
    var count = 0;
    var sibling = _id;
    while (sibling != _SENTINEL && cids[sibling] == cids[_id]) {
      count++;
      sibling = mergedDomNext[sibling];
    }
    return count;
  }

  Iterable<SnapshotObject> get objects sync* {
    var cids = _graph._cids!;
    var mergedDomNext = _graph._mergedDomNext!;
    var sibling = _id;
    while (sibling != _SENTINEL && cids[sibling] == cids[_id]) {
      yield _SnapshotObject._new(sibling, _graph, "");
      sibling = mergedDomNext[sibling];
    }
  }

  SnapshotMergedDominator get parent => _parent ?? this;

  Iterable<SnapshotMergedDominator> get children sync* {
    var next = _graph._mergedDomNext!;
    var cids = _graph._cids!;
    var prev = _SENTINEL;
    var child = _graph._mergedDomHead![_id];
    // Walk the list of children and look for the representative objects, i.e.
    // the first sibling of each cid.
    while (child != _SENTINEL) {
      if (prev == _SENTINEL || cids[prev] != cids[child]) {
        yield _SnapshotMergedDominator._new(child, _graph, this);
      }
      prev = child;
      child = next[child];
    }
  }
}

class _SyntheticSnapshotMergedDominator implements SnapshotMergedDominator {
  late String _description;
  late SnapshotClass _klass;
  late int _internalSize;
  late int _externalSize;
  late int _retainedSize;
  late List<SnapshotObject> _objects;
  late SnapshotMergedDominator _parent;
  late List<SnapshotMergedDominator> _children;

  SnapshotClass get klass => _klass;
  String get description => _description;
  int get shallowSize => internalSize + externalSize;
  int get internalSize => _internalSize;
  int get externalSize => _externalSize;
  int get retainedSize => _retainedSize;
  int get instanceCount => _objects.length;
  SnapshotMergedDominator get parent => _parent;
  Iterable<SnapshotMergedDominator> get children => _children;
  Iterable<SnapshotObject> get objects => _objects;
}

/// A class in a heap snapshot.
abstract class SnapshotClass {
  String get name;
  String get qualifiedName;

  int get shallowSize;
  int get externalSize;
  int get internalSize;
  int get ownedSize;

  int get instanceCount;
  Iterable<SnapshotObject> get instances;
}

class _SnapshotClass implements SnapshotClass {
  final _SnapshotGraph _graph;
  final int _cid;
  final String name;
  String get qualifiedName => "$libUri $name";
  final String libName;
  final String libUri;
  final Map<int, String> fields = new Map<int, String>();

  int totalExternalSize = 0;
  int totalInternalSize = 0;
  int totalInstanceCount = 0;

  int ownedSize = 0;

  int liveExternalSize = 0;
  int liveInternalSize = 0;
  int liveInstanceCount = 0;

  int get shallowSize => internalSize + externalSize;
  int get internalSize => liveInternalSize;
  int get externalSize => liveExternalSize;
  int get instanceCount => liveInstanceCount;

  Iterable<SnapshotObject> get instances sync* {
    final N = _graph._N!;
    final cids = _graph._cids!;
    final retainedSizes = _graph._retainedSizes!;
    for (var id = 1; id <= N; id++) {
      if (cids[id] == _cid && retainedSizes[id] > 0) {
        yield _SnapshotObject._new(id, _graph, "");
      }
    }
  }

  _SnapshotClass._new(
      this._graph, this._cid, this.name, this.libName, this.libUri);
}

/// The analyzed graph from a heap snapshot.
abstract class SnapshotGraph {
  String get description;

  int get internalSize;
  int get externalSize;
  // [internalSize] + [externalSize]
  int get size;

  // The amount of memory reserved for the heap. [internalSize] will always be
  // less than or equal to [capacity].
  int get capacity;

  Iterable<SnapshotClass> get classes;
  Iterable<SnapshotObject> get objects;

  SnapshotObject get root;
  SnapshotObject get extendedRoot;
  SnapshotMergedDominator get mergedRoot;
  SnapshotMergedDominator get extendedMergedRoot;

  // TODO: Insist that the client remember the chunks if needed? Always keeping
  // this increasing the peak memory usage during analysis.
  List<Uint8List> get chunks;
}

const _tagNone = 0;
const _tagNull = 1;
const _tagBool = 2;
const _tagInt = 3;
const _tagDouble = 4;
const _tagLatin1 = 5;
const _tagUtf16 = 6;
const _tagLength = 7;
const _tagName = 8;

const _kSentinelName = "<omitted-object>";
const _kRootName = "Live Objects + External";
const _kUnknownFieldName = "<unknown>";

class _SnapshotGraph implements SnapshotGraph {
  List<Uint8List>? _chunks;
  List<Uint8List> get chunks => _chunks!;

  _SnapshotGraph._new();

  String get description => _description!;

  int get size => _liveInternalSize! + _liveExternalSize!;
  int get internalSize => _liveInternalSize!;
  int get externalSize => _liveExternalSize!;
  int get capacity => _capacity!;

  SnapshotObject get root => _SnapshotObject._new(_ROOT, this, "Root");
  SnapshotMergedDominator get mergedRoot =>
      _SnapshotMergedDominator._new(_ROOT, this, null);

  SnapshotObject? _extendedRoot;
  SnapshotObject get extendedRoot {
    if (_extendedRoot == null) {
      _createExtended();
    }
    return _extendedRoot!;
  }

  SnapshotMergedDominator? _extendedMergedRoot;
  SnapshotMergedDominator get extendedMergedRoot {
    if (_extendedMergedRoot == null) {
      _createExtended();
    }
    return _extendedMergedRoot!;
  }

  void _createExtended() {
    var capacity = new _SyntheticSnapshotObject();
    var uncollected = new _SyntheticSnapshotObject();
    var fragmentation = new _SyntheticSnapshotObject();
    var live = root;
    var mcapacity = new _SyntheticSnapshotMergedDominator();
    var muncollected = new _SyntheticSnapshotMergedDominator();
    var mfragmentation = new _SyntheticSnapshotMergedDominator();
    var mlive = mergedRoot;

    capacity._description = "Capacity + External";
    capacity._klass = live.klass;
    capacity._internalSize = _capacity!;
    capacity._externalSize = _totalExternalSize!;
    capacity._retainedSize = capacity._internalSize + capacity._externalSize;
    capacity._successors = <SnapshotObject>[live, uncollected, fragmentation];
    capacity._predecessors = <SnapshotObject>[];
    capacity._children = <SnapshotObject>[live, uncollected, fragmentation];

    mcapacity._description = "Capacity + External";
    mcapacity._klass = mlive.klass;
    mcapacity._internalSize = _capacity!;
    mcapacity._externalSize = _totalExternalSize!;
    mcapacity._retainedSize = mcapacity._internalSize + mcapacity._externalSize;
    mcapacity._children = <SnapshotMergedDominator>[
      mlive,
      muncollected,
      mfragmentation
    ];
    mcapacity._objects = <SnapshotObject>[capacity];

    uncollected._description = "Uncollected Garbage";
    uncollected._klass = live.klass;
    uncollected._internalSize = _totalInternalSize! - _liveInternalSize!;
    uncollected._externalSize = _totalExternalSize! - _liveExternalSize!;
    uncollected._retainedSize =
        uncollected._internalSize + uncollected._externalSize;
    uncollected._successors = <SnapshotObject>[];
    uncollected._predecessors = <SnapshotObject>[capacity];
    uncollected._parent = capacity;
    uncollected._children = <SnapshotObject>[];

    muncollected._description = "Uncollected Garbage";
    muncollected._klass = mlive.klass;
    muncollected._internalSize = _totalInternalSize! - _liveInternalSize!;
    muncollected._externalSize = _totalExternalSize! - _liveExternalSize!;
    muncollected._retainedSize =
        muncollected._internalSize + muncollected._externalSize;
    muncollected._parent = mcapacity;
    muncollected._children = <SnapshotMergedDominator>[];
    muncollected._objects = <SnapshotObject>[uncollected];

    fragmentation._description = "Free";
    fragmentation._klass = live.klass;
    fragmentation._internalSize = _capacity! - _totalInternalSize!;
    fragmentation._externalSize = 0;
    fragmentation._retainedSize = fragmentation._internalSize;
    fragmentation._successors = <SnapshotObject>[];
    fragmentation._predecessors = <SnapshotObject>[capacity];
    fragmentation._parent = capacity;
    fragmentation._children = <SnapshotObject>[];

    mfragmentation._description = "Free";
    mfragmentation._klass = mlive.klass;
    mfragmentation._internalSize = _capacity! - _totalInternalSize!;
    mfragmentation._externalSize = 0;
    mfragmentation._retainedSize = mfragmentation._internalSize;
    mfragmentation._parent = mcapacity;
    mfragmentation._children = <SnapshotMergedDominator>[];
    mfragmentation._objects = <SnapshotObject>[fragmentation];

    _extendedRoot = capacity;
    _extendedMergedRoot = mcapacity;
  }

  Iterable<SnapshotObject> get objects sync* {
    final N = _N!;
    final retainedSizes = _retainedSizes!;
    for (var id = 1; id <= N; id++) {
      if (retainedSizes[id] > 0) {
        yield _SnapshotObject._new(id, this, "");
      }
    }
  }

  String _describeObject(int oid) {
    if (oid == _SENTINEL) {
      return _kSentinelName;
    }
    if (oid == _ROOT) {
      return _kRootName;
    }
    var cls = _className(oid);
    var data = _nonReferenceData![oid];
    if (data == null) {
      return cls;
    } else {
      return "$cls($data)";
    }
  }

  String _className(int oid) {
    var cid = _cids![oid];
    var cls = _classes![cid];
    if (cls == null) {
      return "Class$cid";
    }
    return cls.name;
  }

  String _edgeName(int cid, int index) {
    var c = _classes![cid];
    if (c == null) {
      return _kUnknownFieldName;
    }
    var n = c.fields[index];
    if (n == null) {
      return _kUnknownFieldName;
    }
    return n;
  }

  Iterable<SnapshotClass> get classes sync* {
    for (final c in _classes!) {
      // Not all CIDs are occupied.
      if (c != null) {
        yield c;
      }
    }
  }

  Future<SnapshotGraph> _load(
      List<Uint8List>? chunks, StreamController<String> onProgress) async {
    _chunks = chunks;
    _ReadStream? stream = _ReadStream._new(chunks!);
    chunks = null;

    // The phases of loading are placed in explicit `new Future(compuation)` so
    // they will be deferred to the message loop. Ordinary async-await will only
    // defer to the microtask loop.

    onProgress.add("Loading classes...");
    await new Future(() => _readClasses(stream!));

    onProgress.add("Loading objects...");
    await new Future(() => _readObjects(stream!));

    onProgress.add("Loading external properties...");
    await new Future(() => _readExternalProperties(stream!));

    stream = null;

    onProgress.add("Compute class table...");
    await new Future(() => _computeClassTable());

    onProgress.add("Finding depth-first order...");
    await new Future(() => _dfs());

    onProgress.add("Finding predecessors...");
    await new Future(() => _buildPredecessors());

    onProgress.add("Finding dominators...");
    await new Future(() => _buildDominators());

    _semi = null;
    _parent = null;

    onProgress.add("Finding in-degree(1) groups...");
    await new Future(() => _buildOwnedSizes());

    _firstPreds = null;
    _preds = null;

    onProgress.add("Finding retained sizes...");
    await new Future(() => _calculateRetainedSizes());

    _vertex = null;

    onProgress.add("Linking dominator tree children...");
    await new Future(() => _linkDominatorChildren());

    onProgress.add("Sorting dominator tree children...");
    await new Future(() => _sortDominatorChildren());

    onProgress.add("Merging dominator tree siblings...");
    await new Future(() => _mergeDominatorSiblings());

    onProgress.add("Loaded");
    // We await here so SnapshotReader clients see all progress events before
    // seeing the done future as completed.
    await onProgress.close();

    return this;
  }

  Uint8List? _encoded;

  String? _description;

  int? _kStackCid;
  int? _kFieldCid;
  int? _numCids;
  int? _N; // Objects in the snapshot.
  int? _Nconnected; // Objects reachable from root.
  int? _E; // References in the snapshot.

  int? _capacity;
  int? _liveInternalSize;
  int? _liveExternalSize;
  int? _totalInternalSize;
  int? _totalExternalSize;

  List<_SnapshotClass?>? _classes;

  // Indexed by node id, with id 0 representing invalid/uninitialized.
  // From snapshot.
  List? _nonReferenceData;
  Uint16List? _cids;
  Uint32List? _internalSizes;
  Uint32List? _externalSizes;
  Uint32List? _firstSuccs;
  Uint32List? _succs;

  // Intermediates.
  Uint32List? _vertex;
  Uint32List? _parent;
  Uint32List? _semi;
  Uint32List? _firstPreds; // Offset into preds.
  Uint32List? _preds;

  // Outputs.
  Uint32List? _doms;
  Uint32List? _retainedSizes;
  Uint32List? _mergedDomHead;
  Uint32List? _mergedDomNext;

  void _readClasses(_ReadStream stream) {
    for (var i = 0; i < 8; i++) {
      stream.readByte(); // Magic value.
    }
    stream.readUnsigned(); // Flags
    _description = stream.readUtf8();

    _totalInternalSize = stream.readUnsigned();
    _capacity = stream.readUnsigned();
    _totalExternalSize = stream.readUnsigned();

    var K = stream.readUnsigned();
    var classes = new List<_SnapshotClass?>.filled(K + 1, null);
    classes[0] = _SnapshotClass._new(this, 0, "Root", "", "");

    for (var cid = 1; cid <= K; cid++) {
      int flags = stream.readUnsigned();
      String name = stream.readUtf8();
      String libName = stream.readUtf8();
      String libUri = stream.readUtf8();
      String reserved = stream.readUtf8();
      final cls = _SnapshotClass._new(this, cid, name, libName, libUri);
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
    final E = stream.readUnsigned();
    final N = stream.readUnsigned();

    // The negative check accounts for int64 overflow in readUnsigned.
    const maxUint32 = 0xFFFFFFFF;
    if (N < 0 || N + 2 >= maxUint32) {
      throw new Exception("Snapshot contains too many objects: $N");
    }
    if (E < 0 || E + 2 >= maxUint32) {
      throw new Exception("Snapshot contains too many references: $E");
    }

    _N = N;
    _E = E;

    var internalSizes = _newUint32Array(N + 1);
    var cids = _newUint16Array(N + 1);
    var nonReferenceData = new List<dynamic>.filled(N + 1, null);
    var firstSuccs = _newUint32Array(N + 2);
    var succs = _newUint32Array(E);
    var eid = 0;
    for (var oid = 1; oid <= N; oid++) {
      var cid = stream.readUnsigned();
      cids[oid] = cid;

      var internalSize = stream.readUnsigned();
      internalSizes[oid] = internalSize;

      var nonReferenceDataTag = stream.readUnsigned();
      switch (nonReferenceDataTag) {
        case _tagNone:
          break;
        case _tagNull:
          nonReferenceData[oid] = "null";
          break;
        case _tagBool:
          nonReferenceData[oid] = stream.readByte() != 0;
          break;
        case _tagInt:
          nonReferenceData[oid] = stream.readSigned();
          break;
        case _tagDouble:
          nonReferenceData[oid] = stream.readFloat64();
          break;
        case _tagLatin1:
          var len = stream.readUnsigned();
          var str = stream.readLatin1();
          if (str.length < len) {
            nonReferenceData[oid] = '$str...';
          } else {
            nonReferenceData[oid] = str;
          }
          break;
        case _tagUtf16:
          int len = stream.readUnsigned();
          var str = stream.readUtf16();
          if (str.length < len) {
            nonReferenceData[oid] = '$str...';
          } else {
            nonReferenceData[oid] = str;
          }
          break;
        case _tagLength:
          nonReferenceData[oid] = stream.readUnsigned(); // Length
          break;
        case _tagName:
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
    _internalSizes = internalSizes;
    _cids = cids;
    _nonReferenceData = nonReferenceData;
    _firstSuccs = firstSuccs;
    _succs = succs;
  }

  void _readExternalProperties(_ReadStream stream) {
    final N = _N!;
    final externalPropertyCount = stream.readUnsigned();

    final externalSizes = _newUint32Array(N + 1);
    for (var i = 0; i < externalPropertyCount; i++) {
      final oid = stream.readUnsigned();
      final externalSize = stream.readUnsigned();
      final name = stream.readUtf8();
      externalSizes[oid] += externalSize;
    }

    _externalSizes = externalSizes;
  }

  void _computeClassTable() {
    final N = _N!;
    final classes = _classes!;
    final cids = _cids!;
    final internalSizes = _internalSizes!;
    final externalSizes = _externalSizes!;
    var totalInternalSize = 0;
    var totalExternalSize = 0;

    for (var oid = 1; oid <= N; oid++) {
      var internalSize = internalSizes[oid];
      totalInternalSize += internalSize;

      var externalSize = externalSizes[oid];
      totalExternalSize += externalSize;

      var cls = classes[cids[oid]]!;
      cls.totalInternalSize += internalSize;
      cls.totalExternalSize += externalSize;
      cls.totalInstanceCount++;
    }

    _totalInternalSize = totalInternalSize;
    _totalExternalSize = totalExternalSize;
  }

  void _dfs() {
    final N = _N!;
    final firstSuccs = _firstSuccs!;
    final succs = _succs!;

    final stackNodes = _newUint32Array(N);
    final stackCurrentEdgePos = _newUint32Array(N);

    final vertex = _newUint32Array(N + 1);
    final semi = _newUint32Array(N + 1);
    final parent = _newUint32Array(N + 1);
    var dfsNumber = 0;

    var stackTop = 0;

    // Push root.
    stackNodes[0] = _ROOT;
    stackCurrentEdgePos[0] = firstSuccs[_ROOT];

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

        if (childId == _SENTINEL) {
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
      print('Heap snapshot contains ${N - dfsNumber} unreachable nodes.');
    }

    assert(() {
      for (var i = 1; i <= dfsNumber; i++) {
        var v = vertex[i];
        assert(semi[v] != _SENTINEL);
      }
      assert(parent[1] == _SENTINEL);
      for (var i = 2; i <= dfsNumber; i++) {
        var v = vertex[i];
        assert(parent[v] != _SENTINEL);
      }
      return true;
    }());

    if (dfsNumber != N) {
      // Remove successors of unconnected nodes
      for (var i = _ROOT + 1; i <= N; i++) {
        if (parent[i] == _SENTINEL) {
          var startSuccIndex = firstSuccs[i];
          var limitSuccIndex = firstSuccs[i + 1];
          for (var succIndex = startSuccIndex;
              succIndex < limitSuccIndex;
              succIndex++) {
            succs[succIndex] = _SENTINEL;
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
    final N = _N!;
    final Nconnected = _Nconnected!;
    final E = _E!;
    final firstSuccs = _firstSuccs!;
    final succs = _succs!;

    // This is first filled with the predecessor counts, then reused to hold the
    // offset to the first predecessor (see alias below).
    // + 1 because 0 is a sentinel
    // + 1 so the number of predecessors can be found from the difference with
    // the next node's offset.
    final numPreds = _newUint32Array(N + 2);
    final preds = _newUint32Array(E);

    // Count predecessors of each node.
    for (var succIndex = 0; succIndex < E; succIndex++) {
      final succId = succs[succIndex];
      if (succId != _SENTINEL) {
        numPreds[succId]++;
      }
    }

    // Assign indices into predecessors array.
    final firstPreds = numPreds; // Alias.
    final nextPreds = _newUint32Array(N + 1);
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
        if (succId != _SENTINEL) {
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
    final N = _N!;
    final Nconnected = _Nconnected!;
    final kStackCid = _kStackCid;
    final kFieldCid = _kFieldCid;

    final cids = _cids!;
    final internalSizes = _internalSizes!;
    final externalSizes = _externalSizes!;
    final vertex = _vertex!;
    final firstPreds = _firstPreds!;
    final preds = _preds!;

    final ownedSizes = _newUint32Array(N + 1);
    for (var i = 1; i <= Nconnected; i++) {
      final v = vertex[i];
      ownedSizes[v] = internalSizes[v] + externalSizes[v];
    }

    for (var i = Nconnected; i > 1; i--) {
      var w = vertex[i];
      assert(w != _ROOT);

      var onlyPred = _SENTINEL;

      var startPred = firstPreds[w];
      var limitPred = firstPreds[w + 1];
      for (var predIndex = startPred; predIndex < limitPred; predIndex++) {
        var v = preds[predIndex];
        if (v == w) {
          // Ignore self-predecessor.
        } else if (onlyPred == _SENTINEL) {
          onlyPred = v;
        } else if (onlyPred == v) {
          // Repeated predecessor.
        } else {
          // Multiple-predecessors.
          onlyPred = _SENTINEL;
          break;
        }
      }

      // If this object has a single precessor which is not a Field, Stack or
      // the root, blame its size against the precessor.
      if ((onlyPred != _SENTINEL) &&
          (onlyPred != _ROOT) &&
          (cids[onlyPred] != kStackCid) &&
          (cids[onlyPred] != kFieldCid)) {
        assert(onlyPred != w);
        ownedSizes[onlyPred] += ownedSizes[w];
        ownedSizes[w] = 0;
      }
    }

    // TODO(rmacnak): Maybe keep the per-objects sizes to be able to provide
    // examples of large owners for each class.
    final classes = _classes!;
    for (var i = 1; i <= Nconnected; i++) {
      final v = vertex[i];
      final cid = cids[v];
      final cls = classes[cid]!;
      cls.ownedSize += ownedSizes[v];
    }
  }

  static int _eval(int v, Uint32List ancestor, Uint32List semi,
      Uint32List label, Uint32List stackNode, Uint8List stackState) {
    if (ancestor[v] == _SENTINEL) {
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
    final N = _N!;
    final Nconnected = _Nconnected!;

    final vertex = _vertex!;
    final semi = _semi!;
    final parent = _parent!;
    final firstPreds = _firstPreds!;
    final preds = _preds!;

    final dom = _newUint32Array(N + 1);

    final ancestor = _newUint32Array(N + 1);
    final label = _newUint32Array(N + 1);
    for (var i = 1; i <= N; i++) {
      label[i] = i;
    }
    final buckets = new List<dynamic>.filled(N + 1, null);
    final child = _newUint32Array(N + 1);
    final size = _newUint32Array(N + 1);
    for (var i = 1; i <= N; i++) {
      size[i] = 1;
    }
    final stackNode = _newUint32Array(N + 1);
    final stackState = _newUint8Array(N + 1);

    for (var i = Nconnected; i > 1; i--) {
      var w = vertex[i];
      assert(w != _ROOT);

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
        buckets[tmp] = [];
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
    for (var i = _ROOT; i <= N; i++) {
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
    final N = _N!;
    final Nconnected = _Nconnected!;

    var liveInternalSize = 0;
    var liveExternalSize = 0;
    final classes = _classes!;
    final cids = _cids!;
    final internalSizes = _internalSizes!;
    final externalSizes = _externalSizes!;
    final vertex = _vertex!;
    final doms = _doms!;

    // Sum internal and external sizes.
    for (var i = 1; i <= Nconnected; i++) {
      var v = vertex[i];
      var internalSize = internalSizes[v];
      var externalSize = externalSizes[v];
      liveInternalSize += internalSize;
      liveExternalSize += externalSize;

      var cls = classes[cids[v]]!;
      cls.liveInternalSize += internalSize;
      cls.liveExternalSize += externalSize;
      cls.liveInstanceCount++;
    }

    // Start with retained size as shallow size + external size. For reachable
    // objects only; leave unreachable objects with a retained size of 0 so
    // they can be filtered during graph iterations.
    var retainedSizes = new Uint32List(N + 1);
    assert(Nconnected <= N);
    for (var i = 0; i <= Nconnected; i++) {
      var v = vertex[i];
      retainedSizes[v] = internalSizes[v] + externalSizes[v];
    }

    // In post order (bottom up), add retained size to dominator's retained
    // size, skipping root.
    for (var i = Nconnected; i > 1; i--) {
      var v = vertex[i];
      assert(v != _ROOT);
      retainedSizes[doms[v]] += retainedSizes[v];
    }

    // Root retains everything.
    assert(retainedSizes[_ROOT] == (liveInternalSize + liveExternalSize));

    _retainedSizes = retainedSizes;
    _liveInternalSize = liveInternalSize;
    _liveExternalSize = liveExternalSize;

    print("internal-garbage: ${_totalInternalSize! - _liveInternalSize!}");
    print("external-garbage: ${_totalExternalSize! - _liveExternalSize!}");
    print("fragmentation: ${_capacity! - _totalInternalSize!}");
    assert(_liveInternalSize! <= _totalInternalSize!);
    assert(_liveExternalSize! <= _totalExternalSize!);
    assert(_totalInternalSize! <= _capacity!);
  }

  // Build linked lists of the children for each node in the dominator tree.
  void _linkDominatorChildren() {
    final N = _N!;
    final doms = _doms!;
    final head = _newUint32Array(N + 1);
    final next = _newUint32Array(N + 1);

    for (var child = _ROOT; child <= N; child++) {
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
    var beforeInsert = _SENTINEL;
    var afterInsert = head1;
    var startInsert = head2;

    while (startInsert != _SENTINEL) {
      while ((afterInsert != _SENTINEL) &&
          (key[afterInsert] <= key[startInsert])) {
        beforeInsert = afterInsert;
        afterInsert = next[beforeInsert];
      }

      var endInsert = startInsert;
      var peek = next[endInsert];

      while ((peek != _SENTINEL) && (key[peek] < key[afterInsert])) {
        endInsert = peek;
        peek = next[endInsert];
      }
      assert(endInsert != _SENTINEL);

      if (beforeInsert == _SENTINEL) {
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
    final N = _N!;
    final cids = _cids!;
    final head = _mergedDomHead!;
    final next = _mergedDomNext!;

    // Returns the new head of the sorted list.
    int sort(int head) {
      if (head == _SENTINEL) return _SENTINEL;
      if (next[head] == _SENTINEL) return head;

      // Find the middle of the list.
      int head1 = head;
      int slow = head;
      int fast = head;
      while (next[fast] != _SENTINEL && next[next[fast]] != _SENTINEL) {
        slow = next[slow];
        fast = next[next[fast]];
      }

      // Split the list in half.
      int head2 = next[slow];
      next[slow] = _SENTINEL;

      // Recursively sort the sublists and merge.
      assert(head1 != head2);
      int newHead1 = sort(head1);
      int newHead2 = sort(head2);
      return _mergeSorted(newHead1, newHead2, next, cids);
    }

    // Sort all list of dominator tree children by cid.
    for (var parent = _ROOT; parent <= N; parent++) {
      head[parent] = sort(head[parent]);
    }
  }

  void _mergeDominatorSiblings() {
    var N = _N!;
    var cids = _cids!;
    var head = _mergedDomHead!;
    var next = _mergedDomNext!;
    var workStack = _newUint32Array(N);
    var workStackTop = 0;

    mergeChildrenAndSort(var parent1, var end) {
      assert(parent1 != _SENTINEL);
      if (next[parent1] == end) return;

      // Find the middle of the list.
      int slow = parent1;
      int fast = parent1;
      while (next[fast] != end && next[next[fast]] != end) {
        slow = next[slow];
        fast = next[next[fast]];
      }

      int parent2 = next[slow];

      assert(parent2 != _SENTINEL);
      assert(parent1 != parent2);
      assert(cids[parent1] == cids[parent2]);

      // Recursively sort the sublists.
      mergeChildrenAndSort(parent1, parent2);
      mergeChildrenAndSort(parent2, end);

      // Merge sorted sublists.
      head[parent1] = _mergeSorted(head[parent1], head[parent2], next, cids);

      // Children moved to parent1.
      head[parent2] = _SENTINEL;
    }

    // Push root.
    workStack[workStackTop++] = _ROOT;

    while (workStackTop > 0) {
      var parent = workStack[--workStackTop];

      var child = head[parent];
      while (child != _SENTINEL) {
        // Push child.
        workStack[workStackTop++] = child;

        // Find next sibling with a different cid.
        var after = child;
        while (after != _SENTINEL && cids[after] == cids[child]) {
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

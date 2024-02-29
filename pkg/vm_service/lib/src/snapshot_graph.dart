// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import '_stream_helpers.dart';
import 'vm_service.dart';

/// A representation of a field captured in a memory snapshot.
class HeapSnapshotField {
  /// An index into [HeapSnapshotObject.references].
  int get index => _index;

  /// The name of the field.
  String get name => _name;

  int _index = -1;
  String _name = '';

  HeapSnapshotField._read(ReadStream reader) {
    // flags (reserved)
    reader.readInteger();

    _index = reader.readInteger();
    _name = reader.readUtf8();

    // reserved
    reader.readUtf8();
  }

  void _write(WriteStream writer) {
    // flags (reserved)
    writer.writeInteger(0);

    writer.writeInteger(_index);
    writer.writeUtf8(_name);

    // reserved
    writer.writeUtf8('');
  }
}

/// A representation of a class type captured in a memory snapshot.
class HeapSnapshotClass {
  /// The class ID representing this type.
  int get classId => _classId;

  /// The simple (not qualified) name of the class.
  String get name => _name;

  /// The name of the class's library.
  String get libraryName => _libraryName;

  /// The [Uri] of the class's library.
  Uri get libraryUri => _libraryUri;

  /// The list of fields in the class.
  List<HeapSnapshotField> get fields => _fields;

  final int _classId;
  String _name = '';
  String _libraryName = '';
  late final Uri _libraryUri;
  final List<HeapSnapshotField> _fields = <HeapSnapshotField>[];

  HeapSnapshotClass._read(this._classId, ReadStream reader) {
    // flags (reserved).
    reader.readInteger();

    _name = reader.readUtf8();
    _libraryName = reader.readUtf8();
    _libraryUri = Uri.parse(reader.readUtf8());

    // reserved
    reader.readUtf8();

    _readFields(reader);
  }

  void _write(WriteStream writer) {
    // flags (reserved).
    writer.writeInteger(0);

    writer.writeUtf8(_name);
    writer.writeUtf8(_libraryName);
    writer.writeUtf8(_libraryUri.toString());

    // something reserved
    writer.writeInteger(0);

    _writeFields(writer);
  }

  HeapSnapshotClass._root()
      : _classId = 0,
        _name = 'Root',
        _libraryName = '',
        _libraryUri = Uri();

  HeapSnapshotClass._sentinel()
      : _classId = 0,
        _name = 'Sentinel',
        _libraryName = '',
        _libraryUri = Uri();

  void _readFields(ReadStream reader) {
    final fieldCount = reader.readInteger();
    for (int i = 0; i < fieldCount; ++i) {
      _fields.add(HeapSnapshotField._read(reader));
    }
  }

  void _writeFields(WriteStream writer) {
    writer.writeInteger(_fields.length);
    for (int i = 0; i < _fields.length; ++i) {
      _fields[i]._write(writer);
    }
  }
}

/// A representation of an object instance captured in a memory snapshot.
class HeapSnapshotObject {
  /// The class ID representing the type of this object.
  int get classId => _classId;

  /// The class representing the type of this object.
  HeapSnapshotClass get klass {
    if (_classId <= 0) {
      return HeapSnapshotClass._sentinel();
    }
    return _graph._classes[_classId];
  }

  /// The space used by this object in bytes.
  int get shallowSize => _shallowSize;

  /// Data associated with this object.
  dynamic get data => _data;

  /// A list of indices into [HeapSnapshotGraph.objects].
  Uint32List get references => Uint32List.sublistView(_graph._successors,
      _graph._firstSuccessors[_oid], _graph._firstSuccessors[_oid + 1]);

  /// A list of indices into [HeapSnapshotGraph.objects].
  Uint32List get referrers {
    final referrers = _graph._referrers;
    final firstReferrers = _graph._firstReferrers;

    if (referrers == null || firstReferrers == null) {
      throw StateError('Referrers are not available in this snapshot. Pass'
          ' `calculateReferrers: true` when taking snapshot to calculate referrers.');
    }

    return Uint32List.sublistView(
        referrers, firstReferrers[_oid], firstReferrers[_oid + 1]);
  }

  /// The identity hash code of this object.
  ///
  /// If `identityHashCode` is 0, either the snapshot did not contain the list
  /// of identity hash codes or this object cannot be compared across
  /// snapshots.
  int get identityHashCode => _identityHashCode;

  Iterable<HeapSnapshotObject> get successors sync* {
    final startSuccessorIndex = _graph._firstSuccessors[_oid];
    final limitSuccessorIndex = _graph._firstSuccessors[_oid + 1];

    for (int nextSuccessorIndex = startSuccessorIndex;
        nextSuccessorIndex < limitSuccessorIndex;
        ++nextSuccessorIndex) {
      final successorId = _graph._successors[nextSuccessorIndex];
      yield _graph.objects[successorId];
    }
  }

  final HeapSnapshotGraph _graph;
  final int _oid;
  int _classId = 0;
  int _shallowSize = -1;
  int _identityHashCode = 0;
  late final dynamic _data;

  HeapSnapshotObject._sentinel(this._graph)
      : _oid = 0,
        _data = HeapSnapshotObjectNoData() {
    _graph._firstSuccessors[_oid] = _graph._nextSuccessor;
  }

  HeapSnapshotObject._read(
    this._graph,
    this._oid,
    ReadStream reader, {
    required bool decodeObjectData,
  }) {
    _classId = reader.readInteger();
    _shallowSize = reader.readInteger();
    final data = _getNonReferenceData(reader);
    _data = decodeObjectData ? data : HeapSnapshotObjectNoData();
    _readReferences(reader);
  }

  void _write(WriteStream writer) {
    writer.writeInteger(_classId);
    writer.writeInteger(_shallowSize);
    _writeNonReferenceData(writer, _data);
    _writeReferences(writer);
  }

  void _readReferences(ReadStream reader) {
    _graph._firstSuccessors[_oid] = _graph._nextSuccessor;
    final referencesCount = reader.readInteger();
    for (int i = 0; i < referencesCount; ++i) {
      final currentOid = _graph._nextSuccessor++;
      final childOid = reader.readInteger();
      _graph._successors[currentOid] = childOid;
      _graph._referrerCounts[childOid]++;
    }
  }

  void _writeReferences(WriteStream writer) {
    final refStart = _graph._firstSuccessors[_oid];
    final refEnd = _oid + 1 < _graph._firstSuccessors.length
        ? _graph._firstSuccessors[_oid + 1]
        : _graph._nextSuccessor;
    final referencesCount = refEnd - refStart;

    writer.writeInteger(referencesCount);
    for (int i = refStart; i < refEnd; ++i) {
      final childOid = _graph._successors[i];
      writer.writeInteger(childOid);
    }
  }
}

/// A representation of an external property captured in a memory snapshot.
class HeapSnapshotExternalProperty {
  /// An index into [HeapSnapshotGraph.objects].
  final int object;

  /// The amount of external memory used.
  final int externalSize;

  /// The name of the external property.
  final String name;

  HeapSnapshotExternalProperty._read(ReadStream reader)
      : object = reader.readInteger(),
        externalSize = reader.readInteger(),
        name = reader.readUtf8();

  void _write(WriteStream writer) {
    writer.writeInteger(object);
    writer.writeInteger(externalSize);
    writer.writeUtf8(name);
  }
}

/// A graph representation of a heap snapshot.
class HeapSnapshotGraph {
  /// The name of the isolate represented by this heap snapshot.
  String get name => _name;

  int get flags => _flags;

  /// The sum of shallow sizes of all objects in this graph in bytes.
  int get shallowSize => _shallowSize;

  /// The amount of memory reserved for this heap in bytes.
  ///
  /// At least as large as [shallowSize].
  int get capacity => _capacity;

  /// The sum of sizes of all external properties in this graph in bytes.
  int get externalSize => _externalSize;

  /// The list of classes found in this snapshot.
  List<HeapSnapshotClass> get classes => _classes;

  /// At least as big as the sum of all [HeapSnapshotObject.references].
  int get referenceCount => _referenceCount;

  /// The list of objects found in this snapshot.
  List<HeapSnapshotObject> get objects => _objects;

  /// The list of external properties found in this snapshot.
  List<HeapSnapshotExternalProperty> get externalProperties =>
      _externalProperties;

  String _name = '';
  int _flags = -1;
  int _shallowSize = -1;
  int _capacity = -1;
  int _externalSize = -1;
  final List<HeapSnapshotClass> _classes = <HeapSnapshotClass>[];
  int _referenceCount = -1;
  final List<HeapSnapshotObject> _objects = <HeapSnapshotObject>[];
  final List<HeapSnapshotExternalProperty> _externalProperties =
      <HeapSnapshotExternalProperty>[];

  /// Contains the successors (references) of each object.
  ///
  /// The array consists of blocks of successors, one block for each object.
  /// [_firstSuccessors] contains the start indexes of each block.
  ///
  /// Cells, not used yet start at index [_nextSuccessor].
  late final Uint32List _successors;

  /// See [_successors].
  late final Uint32List _firstSuccessors;

  /// See [_successors].
  int _nextSuccessor = 0;

  late Uint32List _referrerCounts;
  Uint32List? _firstReferrers;
  Uint32List? _referrers;

  /// Requests a heap snapshot for a given isolate and builds a
  /// [HeapSnapshotGraph].
  ///
  /// Note: this method calls [VmService.streamListen] and
  /// [VmService.streamCancel] on [EventStreams.kHeapSnapshot].
  ///
  /// Set flags to false to save processing time and memory footprint
  /// by skipping decoding or calculation of certain data:
  ///
  /// - [calculateReferrers] for [HeapSnapshotObject.referrers]
  /// - [decodeObjectData] for [HeapSnapshotObject.data]
  /// - [decodeExternalProperties] for [HeapSnapshotGraph.externalProperties]
  /// - [decodeIdentityHashCodes] for [HeapSnapshotObject.identityHashCode]
  static Future<HeapSnapshotGraph> getSnapshot(
    VmService service,
    IsolateRef isolate, {
    bool calculateReferrers = true,
    bool decodeObjectData = true,
    bool decodeExternalProperties = true,
    bool decodeIdentityHashCodes = true,
  }) async {
    await service.streamListen(EventStreams.kHeapSnapshot);

    final completer = Completer<HeapSnapshotGraph>();
    final chunks = <ByteData>[];
    late StreamSubscription streamSubscription;
    streamSubscription = service.onHeapSnapshotEvent.listen((e) async {
      chunks.add(e.data!);
      if (e.last!) {
        await service.streamCancel(EventStreams.kHeapSnapshot);
        await streamSubscription.cancel();
        completer.complete(HeapSnapshotGraph.fromChunks(
          chunks,
          calculateReferrers: calculateReferrers,
          decodeObjectData: decodeObjectData,
          decodeExternalProperties: decodeExternalProperties,
          decodeIdentityHashCodes: decodeIdentityHashCodes,
        ));
      }
    });

    await service.requestHeapSnapshot(isolate.id!);
    return completer.future;
  }

  static const _magicHeader = 'dartheap';

  /// Populates the [HeapSnapshotGraph] by parsing the events from the
  /// `HeapSnapshot` stream.
  ///
  /// Set flags to false to save processing time and memory footprint
  /// by skipping decoding or calculation of certain data:
  ///
  /// - [calculateReferrers] for [HeapSnapshotObject.referrers]
  /// - [decodeObjectData] for [HeapSnapshotObject.data]
  /// - [decodeExternalProperties] for [HeapSnapshotGraph.externalProperties]
  /// - [decodeIdentityHashCodes] for [HeapSnapshotObject.identityHashCode]
  HeapSnapshotGraph.fromChunks(
    List<ByteData> chunks, {
    bool calculateReferrers = true,
    bool decodeObjectData = true,
    bool decodeExternalProperties = true,
    bool decodeIdentityHashCodes = true,
  }) {
    final reader = ReadStream(chunks);

    // Skip magic header
    for (int i = 0; i < _magicHeader.length; ++i) {
      reader.readByte();
    }

    _flags = reader.readInteger();

    _name = reader.readUtf8();
    _shallowSize = reader.readInteger();
    _capacity = reader.readInteger();
    _externalSize = reader.readInteger();

    _readClasses(reader);
    _readObjects(reader, decodeObjectData: decodeObjectData);

    if (decodeExternalProperties || decodeIdentityHashCodes) {
      _readExternalProperties(
        reader,
        decodeExternalProperties: decodeExternalProperties,
      );
    }

    if (decodeIdentityHashCodes) {
      _readIdentityHashCodes(reader);
    }

    if (calculateReferrers) _calculateReferrers();
  }

  List<ByteData> toChunks() {
    final writer = WriteStream();

    for (int i = 0; i < _magicHeader.length; ++i) {
      writer.writeByte(_magicHeader.codeUnitAt(i));
    }

    writer.writeInteger(_flags);
    writer.writeUtf8(_name);
    writer.writeInteger(_shallowSize);
    writer.writeInteger(_capacity);
    writer.writeInteger(_externalSize);

    _writeClasses(writer);
    _writeObjects(writer);
    _writeExternalProperties(writer);
    _writeIdentityHashCodes(writer);

    return writer.chunks;
  }

  void _readClasses(ReadStream reader) {
    final classCount = reader.readInteger();
    _classes.add(HeapSnapshotClass._root());
    for (int i = 1; i <= classCount; ++i) {
      final klass = HeapSnapshotClass._read(i, reader);
      _classes.add(klass);
    }
  }

  void _writeClasses(WriteStream writer) {
    writer.writeInteger(_classes.length - 1);
    for (int i = 1; i < _classes.length; ++i) {
      _classes[i]._write(writer);
    }
  }

  void _readObjects(ReadStream reader, {required bool decodeObjectData}) {
    _referenceCount = reader.readInteger();
    final objectCount = reader.readInteger();

    _firstSuccessors = _newUint32Array(objectCount + 2);
    _successors = _newUint32Array(_referenceCount);
    _referrerCounts = _newUint32Array(objectCount + 2);
    _objects.add(HeapSnapshotObject._sentinel(this));
    for (int i = 1; i <= objectCount; ++i) {
      _objects.add(HeapSnapshotObject._read(
        this,
        i,
        reader,
        decodeObjectData: decodeObjectData,
      ));
    }
    _firstSuccessors[objectCount + 1] = _nextSuccessor;
  }

  void _writeObjects(WriteStream writer) {
    writer.writeInteger(_referenceCount);
    writer.writeInteger(_objects.length - 1);

    for (int i = 1; i < _objects.length; ++i) {
      _objects[i]._write(writer);
    }
  }

  void _calculateReferrers() {
    final objectCount = _objects.length - 1;

    _firstReferrers = _newUint32Array(objectCount + 2);
    _referrers = _newUint32Array(_referenceCount);

    _firstReferrers![objectCount + 1] = _nextSuccessor;

    // We reuse the [_predecessorCounts] array and turn it into the
    // write cursor array.
    final predecessorCounts = _referrerCounts;
    _referrerCounts = Uint32List(0);
    int sum = 0;
    int totalCount = _referenceCount;
    for (int i = objectCount; i >= 0; --i) {
      sum += predecessorCounts[i];
      final firstPredecessor = totalCount - sum;
      _firstReferrers![i] = predecessorCounts[i] = firstPredecessor;
    }

    final predecessorWriteCursor = predecessorCounts;
    for (int i = 1; i <= objectCount; ++i) {
      final from = _firstSuccessors[i];
      final to = _firstSuccessors[i + 1];
      for (int j = from; j < to; ++j) {
        final cursor = predecessorWriteCursor[_successors[j]]++;
        _referrers![cursor] = i;
      }
    }
  }

  void _readExternalProperties(
    ReadStream reader, {
    required bool decodeExternalProperties,
  }) {
    final propertiesCount = reader.readInteger();
    for (int i = 0; i < propertiesCount; ++i) {
      final property = HeapSnapshotExternalProperty._read(reader);
      if (decodeExternalProperties) {
        _externalProperties.add(property);
      }
    }
  }

  void _writeExternalProperties(WriteStream writer) {
    writer.writeInteger(_externalProperties.length);
    for (int i = 0; i < _externalProperties.length; ++i) {
      _externalProperties[i]._write(writer);
    }
  }

  void _readIdentityHashCodes(ReadStream reader) {
    if (reader.atEnd) {
      // Older VMs don't include identity hash codes.
      return;
    }
    final objectCount = _objects.length;
    for (int i = 1; i < objectCount; ++i) {
      _objects[i]._identityHashCode = reader.readInteger();
    }
  }

  void _writeIdentityHashCodes(WriteStream writer) {
    for (int i = 1; i < _objects.length; ++i) {
      writer.writeInteger(_objects[i]._identityHashCode);
    }
  }

  Uint32List _newUint32Array(int size) {
    try {
      return Uint32List(size);
    } on ArgumentError {
      // JS throws a misleading invalid argument error. Convert to a more
      // user-friendly message.
      throw Exception(
        'OutOfMemoryError: Not enough memory available to analyze the snapshot.',
      );
    }
  }
}

const _kNoData = 0;
const _kNullData = 1;
const _kBoolData = 2;
const _kIntData = 3;
const _kDoubleData = 4;
const _kLatin1Data = 5;
const _kUtf16Data = 6;
const _kLengthData = 7;
const _kNameData = 8;

void _writeNonReferenceData(WriteStream writer, dynamic data) {
  if (data is HeapSnapshotObjectNoData) {
    writer.writeInteger(_kNoData);
    return;
  }
  if (data is HeapSnapshotObjectNullData) {
    writer.writeInteger(_kNullData);
    return;
  }
  if (data is bool) {
    writer.writeInteger(_kBoolData);
    writer.writeByte(data ? 1 : 0);
    return;
  }
  if (data is int) {
    writer.writeInteger(_kIntData);
    writer.writeInteger(data);
    return;
  }
  if (data is double) {
    writer.writeInteger(_kDoubleData);
    writer.writeFloat64(data);
    return;
  }
  if (data is HeapSnapshotObjectLengthData) {
    writer.writeInteger(_kLengthData);
    writer.writeInteger(data.length);
    return;
  }
  if (data is String) {
    // We use _kNameData for any string, because long strings are already cut with `...`.
    writer.writeInteger(_kNameData);
    writer.writeUtf8(data);
    return;
  }
  throw 'Not expected type: ${data.runtimeType}';
}

dynamic _getNonReferenceData(ReadStream reader) {
  final tag = reader.readInteger();
  switch (tag) {
    case _kNoData:
      return const HeapSnapshotObjectNoData();
    case _kNullData:
      return const HeapSnapshotObjectNullData();
    case _kBoolData:
      return (reader.readByte() == 1);
    case _kIntData:
      return reader.readInteger();
    case _kDoubleData:
      return reader.readFloat64();
    case _kLatin1Data:
      final len = reader.readInteger();
      final str = reader.readLatin1();
      return (str.length < len) ? '$str...' : str;
    case _kUtf16Data:
      final len = reader.readInteger();
      final str = reader.readUtf16();
      return (str.length < len) ? '$str...' : str;
    case _kLengthData:
      return HeapSnapshotObjectLengthData(reader.readInteger());
    case _kNameData:
      return reader.readUtf8();
    default:
      throw 'Invalid tag: $tag';
  }
}

/// Represents that no data is associated with an object.
class HeapSnapshotObjectNoData {
  const HeapSnapshotObjectNoData();
}

/// Represents that the data associated with an object is null.
class HeapSnapshotObjectNullData {
  const HeapSnapshotObjectNullData();
}

/// Represents the length of an object.
class HeapSnapshotObjectLengthData {
  final int length;
  HeapSnapshotObjectLengthData(this.length);
}

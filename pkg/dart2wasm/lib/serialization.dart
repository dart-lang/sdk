// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:kernel/ast.dart';

import 'dynamic_module_kernel_metadata.dart';
import 'reference_extensions.dart';

class _EntityToIdMapper {
  final Component component;
  final Map<TreeNode, int> _ids;

  _EntityToIdMapper(this.component)
      : _ids =
            (component.metadata[DynamicModuleGlobalIdRepository.repositoryTag]
                    as DynamicModuleGlobalIdRepository)
                .mapping;

  int idForClass(Class cls) {
    return _ids[cls]!;
  }

  int idForMember(Member member) {
    return _ids[member]!;
  }

  (int, int) idForReference(Reference reference) {
    return (idForMember(reference.asMember), _flagForReference(reference));
  }

  static int _flagForReference(Reference reference) {
    if (reference.isImplicitGetter) return 0;
    if (reference.isImplicitSetter) return 1;
    if (reference.isTearOffReference) return 2;
    if (reference.isConstructorBodyReference) return 3;
    if (reference.isInitializerReference) return 4;
    if (reference.isTypeCheckerReference) return 5;
    if (reference.isCheckedEntryReference) return 6;
    if (reference.isUncheckedEntryReference) return 7;
    if (reference.isBodyReference) return 8;
    assert(reference == reference.asMember.reference);
    return 9;
  }
}

class _IdToEntityMapper {
  final Component component;
  final Map<int, TreeNode> _mapping;

  static Map<int, TreeNode> _makeIdsMap(Component component) {
    final mapping =
        (component.metadata[DynamicModuleGlobalIdRepository.repositoryTag]
                as DynamicModuleGlobalIdRepository)
            .mapping;
    final inverse = <int, TreeNode>{};
    mapping.forEach((node, id) {
      inverse[id] = node;
    });
    return inverse;
  }

  _IdToEntityMapper(this.component) : _mapping = _makeIdsMap(component);

  Class classForId(int id) {
    return _mapping[id] as Class;
  }

  Member memberForId(int id) {
    return _mapping[id] as Member;
  }

  Reference referenceForId(int memberId, int flag) {
    final member = _mapping[memberId] as Member;
    return _referenceForFlag(member, flag);
  }

  static Reference _referenceForFlag(Member member, int flag) {
    if (flag == 0) return (member as Field).getterReference;
    if (flag == 1) return (member as Field).setterReference!;
    if (flag == 2) return (member as Procedure).tearOffReference;
    if (flag == 3) return (member as Constructor).constructorBodyReference;
    if (flag == 4) return (member as Constructor).initializerReference;
    if (flag == 5) return member.typeCheckerReference;
    if (flag == 6) return member.checkedEntryReference;
    if (flag == 7) return member.uncheckedEntryReference;
    if (flag == 8) return member.bodyReference;
    assert(flag == 9);
    return member.reference;
  }
}

class DataSerializer {
  final _BinaryDataSink _sink = _BinaryDataSink();
  final _EntityToIdMapper _mapper;
  final Map<String, int> _stringIndexer = {};

  DataSerializer(Component component) : _mapper = _EntityToIdMapper(component);

  void writeNullable<T>(T? value, void Function(T value) write) {
    if (value != null) {
      _sink.writeBool(true);
      write(value);
    } else {
      _sink.writeBool(false);
    }
  }

  void writeString(String value) {
    int? index = _stringIndexer[value];
    if (index == null) {
      index = _stringIndexer[value] = _stringIndexer.length;
      _sink.writeInt(index);
      _sink.writeString(value);
    } else {
      _sink.writeInt(index);
    }
  }

  void writeInt(int value) {
    _sink.writeInt(value);
  }

  void writeBool(bool value) {
    _sink.writeByte(value ? 1 : 0);
  }

  void writeBoolList(List<bool> values) {
    _sink.writeInt(values.length);
    int index = 0;
    for (final value in values) {
      index = (index << 1) | (value ? 1 : 0);
    }
    _sink.writeInt(index);
  }

  void writeEnum<E extends Enum>(E value) {
    writeInt(value.index);
  }

  void writeClass(Class cls) {
    writeInt(_mapper.idForClass(cls));
  }

  void writeMember(Member member) {
    final memberId = _mapper.idForMember(member);
    writeInt(memberId);
  }

  void writeReference(Reference reference) {
    final (memberId, referenceFlag) = _mapper.idForReference(reference);
    writeInt(memberId);
    writeInt(referenceFlag);
  }

  void writeMap<K, V>(Map<K, V> map, void Function(K key) writeKey,
      void Function(V value) writeValue) {
    writeInt(map.length);
    map.forEach((key, value) {
      writeKey(key);
      writeValue(value);
    });
  }

  void writeList<E>(Iterable<E> list, void Function(E value) writeValue) {
    writeInt(list.length);
    for (final value in list) {
      writeValue(value);
    }
  }

  Uint8List takeBytes() {
    return _sink.takeBytes();
  }
}

class DataDeserializer {
  final Component component;
  final _BinaryDataSource _source;
  final _IdToEntityMapper _mapper;
  final List<String> _stringIndexer = [];

  DataDeserializer(Uint8List bytes, this.component)
      : _source = _BinaryDataSource(bytes),
        _mapper = _IdToEntityMapper(component);

  T? readNullable<T>(T Function() read) {
    return _source.readBool() ? read() : null;
  }

  String readString() {
    final index = _source.readInt();
    if (index < _stringIndexer.length) return _stringIndexer[index];
    final value = _source.readString();
    assert(index == _stringIndexer.length);
    _stringIndexer.add(value);
    return value;
  }

  int readInt() {
    return _source.readInt();
  }

  bool readBool() {
    return _source.readInt() == 1;
  }

  List<bool> readBoolList() {
    final length = _source.readInt();
    final values = _source.readInt();
    return List.generate(length, (i) => (values >> (length - i - 1)) & 1 == 1);
  }

  E readEnum<E extends Enum>(List<E> values) {
    int index = _source.readInt();
    assert(
        0 <= index && index < values.length,
        "Invalid data kind index. "
        "Expected one of $values, found index $index.");
    return values[index];
  }

  Class readClass() {
    return _mapper.classForId(_source.readInt());
  }

  Member readMember() {
    return _mapper.memberForId(_source.readInt());
  }

  Reference readReference() {
    final memberId = _source.readInt();
    final flag = _source.readInt();
    return _mapper.referenceForId(memberId, flag);
  }

  Map<K, V> readMap<K, V>(K Function() readKey, V Function() readValue) {
    final length = _source.readInt();
    final map = <K, V>{};
    for (int i = 0; i < length; i++) {
      final key = readKey();
      final value = readValue();
      map[key] = value;
    }
    return map;
  }

  List<E> readList<E>(E Function() readValue) {
    final length = _source.readInt();
    final list = <E>[];
    for (int i = 0; i < length; i++) {
      list.add(readValue());
    }
    return list;
  }
}

class _BinaryDataSink {
  static const int _initSinkSize = 50 * 1024;

  Uint8List _data = Uint8List(_initSinkSize);
  int _length = 0;

  _BinaryDataSink();

  int get length => _length;

  void _ensure(int size) {
    // Ensure space for at least `size` additional bytes.
    if (_data.length < _length + size) {
      int newLength = _data.length * 2;
      while (newLength < _length + size) {
        newLength *= 2;
      }
      _data = Uint8List(newLength)..setRange(0, _data.length, _data);
    }
  }

  void writeByte(int byte) {
    assert(byte == byte & 0xFF);
    _ensure(1);
    _data[_length++] = byte;
  }

  void writeBytes(Uint8List bytes) {
    _ensure(bytes.length);
    _data.setRange(_length, _length += bytes.length, bytes);
  }

  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeInt(bytes.length);
    writeBytes(bytes);
  }

  void writeBool(bool value) {
    writeByte(value ? 1 : 0);
  }

  void writeInt(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      writeByte(value);
    } else if (value < 0x4000) {
      writeByte((value >> 8) | 0x80);
      writeByte(value & 0xFF);
    } else {
      writeByte((value >> 24) | 0xC0);
      writeByte((value >> 16) & 0xFF);
      writeByte((value >> 8) & 0xFF);
      writeByte(value & 0xFF);
    }
  }

  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_data, 0, _length);
    // Free the reference to the large data list so it can potentially be
    // tree-shaken.
    _data = Uint8List(0);
    return result;
  }
}

class _BinaryDataSource {
  int _byteOffset = 0;
  final Uint8List _bytes;

  _BinaryDataSource(this._bytes);

  void begin(String tag) {}

  void end(String tag) {}

  int _readByte() => _bytes[_byteOffset++];

  String readString() {
    int length = readInt();
    return utf8.decode(
        Uint8List.sublistView(_bytes, _byteOffset, _byteOffset += length));
  }

  bool readBool() {
    return _readByte() != 0;
  }

  int readInt() {
    var byte = _readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | _readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (_readByte() << 16) |
          (_readByte() << 8) |
          _readByte();
    }
  }

  int get length => _bytes.length;
  int get currentOffset => _byteOffset;
}

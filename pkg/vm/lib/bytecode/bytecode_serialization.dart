// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.bytecode_serialization;

import 'dart:io' show BytesBuilder;
import 'dart:typed_data' show Uint8List, Uint16List;

abstract class StringWriter {
  int put(String string);
}

abstract class StringReader {
  String get(int ref);
}

abstract class BytecodeObject {}

abstract class ObjectWriter {
  void writeObject(BytecodeObject object, BufferedWriter writer);
}

abstract class ObjectReader {
  BytecodeObject readObject(BufferedReader reader);
}

class BufferedWriter {
  final int formatVersion;
  final StringWriter stringWriter;
  final ObjectWriter objectWriter;
  final BytesBuilder bytes = new BytesBuilder();
  final int baseOffset;

  BufferedWriter(this.formatVersion, this.stringWriter, this.objectWriter,
      {this.baseOffset: 0});

  factory BufferedWriter.fromWriter(BufferedWriter writer) =>
      new BufferedWriter(
          writer.formatVersion, writer.stringWriter, writer.objectWriter);

  List<int> takeBytes() => bytes.takeBytes();

  int get offset => bytes.length;

  void writeByte(int value) {
    assert((value >> 8) == 0);
    bytes.addByte(value);
  }

  void writeBytes(List<int> values) {
    bytes.add(values);
  }

  void writeUInt32(int value) {
    if ((value >> 32) != 0) {
      throw 'Unable to write $value as 32-bit unsigned integer';
    }
    // TODO(alexmarkov): consider using native byte order
    bytes.addByte((value >> 24) & 0xFF);
    bytes.addByte((value >> 16) & 0xFF);
    bytes.addByte((value >> 8) & 0xFF);
    bytes.addByte(value & 0xFF);
  }

  void writePackedUInt30(int value) {
    if ((value >> 30) != 0) {
      throw 'Unable to write $value as 30-bit unsigned integer';
    }
    if (value < 0x80) {
      bytes.addByte(value);
    } else if (value < 0x4000) {
      bytes.addByte((value >> 8) | 0x80);
      bytes.addByte(value & 0xFF);
    } else {
      bytes.addByte((value >> 24) | 0xC0);
      bytes.addByte((value >> 16) & 0xFF);
      bytes.addByte((value >> 8) & 0xFF);
      bytes.addByte(value & 0xFF);
    }
  }

  void writeSLEB128(int value) {
    bool last = false;
    do {
      int part = value & 0x7f;
      value >>= 7;
      if ((value == 0 && (part & 0x40) == 0) ||
          (value == -1 && (part & 0x40) != 0)) {
        last = true;
      } else {
        part |= 0x80;
      }
      bytes.addByte(part);
    } while (!last);
  }

  void writePackedStringReference(String value) {
    writePackedUInt30(stringWriter.put(value));
  }

  void writePackedObject(BytecodeObject object) {
    objectWriter.writeObject(object, this);
  }

  void writePackedList(List<BytecodeObject> objects) {
    writePackedUInt30(objects.length);
    for (var obj in objects) {
      writePackedObject(obj);
    }
  }

  void align(int alignment) {
    assert(alignment & (alignment - 1) == 0);
    int offs = baseOffset + offset;
    int padding = ((offs + alignment - 1) & -alignment) - offs;
    for (int i = 0; i < padding; ++i) {
      bytes.addByte(0);
    }
  }
}

class BufferedReader {
  int formatVersion;
  StringReader stringReader;
  ObjectReader objectReader;
  final List<int> bytes;
  final int baseOffset;

  /// Position within [bytes], already includes [baseOffset].
  int _pos;

  BufferedReader(
      this.formatVersion, this.stringReader, this.objectReader, this.bytes,
      {this.baseOffset: 0})
      : _pos = baseOffset {
    assert((0 <= _pos) && (_pos <= bytes.length));
  }

  int get offset => _pos - baseOffset;

  set offset(int offs) {
    _pos = baseOffset + offs;
    assert((0 <= _pos) && (_pos <= bytes.length));
  }

  int readByte() => bytes[_pos++];

  int readUInt32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  int readPackedUInt30() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  int readSLEB128() {
    int value = 0;
    int shift = 0;
    int part = 0;
    do {
      part = readByte();
      value |= (part & 0x7f) << shift;
      shift += 7;
    } while ((part & 0x80) != 0);
    const int kBitsPerInt = 64;
    if ((shift < kBitsPerInt) && ((part & 0x40) != 0)) {
      value |= (-1) << shift;
    }
    return value;
  }

  String readPackedStringReference() {
    return stringReader.get(readPackedUInt30());
  }

  BytecodeObject readPackedObject() {
    return objectReader.readObject(this);
  }

  List<T> readPackedList<T extends BytecodeObject>() {
    final int len = readPackedUInt30();
    final list = new List<T>(len);
    for (int i = 0; i < len; ++i) {
      list[i] = readPackedObject();
    }
    return list;
  }

  Uint8List readBytesAsUint8List(int count) {
    final Uint8List result = new Uint8List(count);
    result.setRange(0, result.length, bytes, _pos);
    _pos += count;
    return result;
  }

  Uint16List readBytesAsUint16List(int count) {
    final Uint16List result = new Uint16List(count);
    int pos = _pos;
    for (int i = 0; i < count; ++i) {
      result[i] = bytes[pos] | (bytes[pos + 1] << 8);
      pos += 2;
    }
    _pos += count << 1;
    return result;
  }

  void align(int alignment) {
    assert(alignment & (alignment - 1) == 0);
    _pos = ((_pos + alignment - 1) & -alignment);
  }
}

class StringTable implements StringWriter, StringReader {
  // Bit 0 in string reference is set for two-byte strings.
  static const int flagTwoByteString = 1;

  Map<String, int> _map = <String, int>{};
  List<String> _oneByteStrings = <String>[];
  List<String> _twoByteStrings = <String>[];
  bool _written = false;

  StringTable();

  @override
  int put(String string) {
    int ref = _map[string];
    if (ref == null) {
      if (_written) {
        throw 'Unable to add a string to string table after it was written';
      }
      if (isOneByteString(string)) {
        ref = (_oneByteStrings.length << 1);
        _oneByteStrings.add(string);
      } else {
        ref = (_twoByteStrings.length << 1) | flagTwoByteString;
        _twoByteStrings.add(string);
      }
      _map[string] = ref;
    }
    return ref;
  }

  @override
  String get(int ref) {
    if ((ref & flagTwoByteString) == 0) {
      return _oneByteStrings[ref >> 1];
    } else {
      return _twoByteStrings[ref >> 1];
    }
  }

  bool isOneByteString(String value) {
    const int maxLatin1 = 0xff;
    for (int i = 0; i < value.length; ++i) {
      if (value.codeUnitAt(i) > maxLatin1) {
        return false;
      }
    }
    return true;
  }

  void write(BufferedWriter writer) {
    final start = writer.offset;
    writer.writeUInt32(_oneByteStrings.length);
    writer.writeUInt32(_twoByteStrings.length);
    int endOffset = 0;
    for (var str in _oneByteStrings) {
      endOffset += str.length;
      writer.writeUInt32(endOffset);
    }
    for (var str in _twoByteStrings) {
      endOffset += str.length << 1;
      writer.writeUInt32(endOffset);
    }
    for (var str in _oneByteStrings) {
      for (int i = 0; i < str.length; ++i) {
        writer.writeByte(str.codeUnitAt(i));
      }
    }
    for (var str in _twoByteStrings) {
      for (int i = 0; i < str.length; ++i) {
        int utf16codeUnit = str.codeUnitAt(i);
        writer.writeByte(utf16codeUnit & 0xFF);
        writer.writeByte(utf16codeUnit >> 8);
      }
    }
    _written = true;
    BytecodeSizeStatistics.stringTableSize += (writer.offset - start);
  }

  StringTable.read(BufferedReader reader) {
    final int numOneByteStrings = reader.readUInt32();
    final int numTwoByteStrings = reader.readUInt32();
    final List<int> oneByteEndOffsets = new List<int>(numOneByteStrings);
    for (int i = 0; i < oneByteEndOffsets.length; ++i) {
      oneByteEndOffsets[i] = reader.readUInt32();
    }
    List<int> twoByteEndOffsets = new List<int>(numTwoByteStrings);
    for (int i = 0; i < twoByteEndOffsets.length; ++i) {
      twoByteEndOffsets[i] = reader.readUInt32();
    }
    int start = 0;
    if (numOneByteStrings > 0) {
      _oneByteStrings = new List<String>(numOneByteStrings);
      final charCodes = reader.readBytesAsUint8List(oneByteEndOffsets.last);
      for (int i = 0; i < _oneByteStrings.length; ++i) {
        final end = oneByteEndOffsets[i];
        final str = new String.fromCharCodes(charCodes, start, end);
        _oneByteStrings[i] = str;
        _map[str] = i << 1;
        start = end;
      }
    }
    final int twoByteBaseOffset = start;
    if (numTwoByteStrings > 0) {
      int start = 0;
      _twoByteStrings = new List<String>(numTwoByteStrings);
      final charCodes = reader.readBytesAsUint16List(
          (twoByteEndOffsets.last - twoByteBaseOffset) >> 1);
      for (int i = 0; i < _twoByteStrings.length; ++i) {
        final end = (twoByteEndOffsets[i] - twoByteBaseOffset) >> 1;
        final str = new String.fromCharCodes(charCodes, start, end);
        _twoByteStrings[i] = str;
        _map[str] = (i << 1) | flagTwoByteString;
        start = end;
      }
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln('StringTable {');
    sb.writeln('  // One Byte Strings');
    for (String str in _oneByteStrings) {
      sb.writeln('  "$str"');
    }
    sb.writeln('  // Two Byte Strings');
    for (String str in _twoByteStrings) {
      sb.writeln('  "$str"');
    }
    sb.writeln('}');
    return sb.toString();
  }
}

class ConstantPoolEntryStatistics {
  final String name;
  int size = 0;
  int count = 0;

  ConstantPoolEntryStatistics(this.name);
}

class BytecodeSizeStatistics {
  static int componentSize = 0;
  static int objectTableSize = 0;
  static int stringTableSize = 0;
  static int membersSize = 0;
  static int constantPoolSize = 0;
  static int instructionsSize = 0;
  static List<ConstantPoolEntryStatistics> constantPoolStats =
      <ConstantPoolEntryStatistics>[];

  static void reset() {
    componentSize = 0;
    objectTableSize = 0;
    stringTableSize = 0;
    membersSize = 0;
    constantPoolSize = 0;
    instructionsSize = 0;
    constantPoolStats = <ConstantPoolEntryStatistics>[];
  }

  static void dump() {
    print("Bytecode size statistics:");
    print("  Bytecode component:  $componentSize");
    print("   - object table:     $objectTableSize");
    print("   - string table:     $stringTableSize");
    print("  Bytecode members:    $membersSize");
    print("   - constant pool:    $constantPoolSize");
    for (var cpStat in constantPoolStats) {
      final name = cpStat.name.padRight(40);
      final size = cpStat.size.toString().padLeft(10);
      final count = cpStat.count.toString().padLeft(8);
      print("       - $name:    $size  (count: $count)");
    }
    print("   - instructions:     $instructionsSize");
  }
}

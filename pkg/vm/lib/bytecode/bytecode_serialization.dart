// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.bytecode_serialization;

import 'package:kernel/ast.dart' show BinarySink;
import 'dart:typed_data' show ByteData, Endian, Uint8List, Uint16List;

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
  /// Initial size of the buffer in BufferedWriter.
  static const int initialSize = 1024;

  /// Lists less than this size are copied into the buffer.
  /// Larger lists are appended without copying.
  static const int avoidCopyingSize = 1024;

  /// Keep buffers with this remaining bytes or more, instead of
  /// creating a new buffer.
  static const int minRemainderToKeep = 256;

  final int formatVersion;
  final StringWriter stringWriter;
  final ObjectWriter objectWriter;
  final LinkWriter linkWriter;

  // Prefix of the data stored in this writer.
  // List of pairs Uint8List buffer, int length.
  List<dynamic> _buffers;
  // Total length of data in [_buffers].
  int _buffersLength = 0;

  Uint8List _currentBuffer = new Uint8List(initialSize);
  int _currentLength = 0;
  int _nextBufferSize = initialSize << 1;

  BufferedWriter(this.formatVersion, this.stringWriter, this.objectWriter,
      this.linkWriter);

  factory BufferedWriter.fromWriter(BufferedWriter writer) =>
      new BufferedWriter(writer.formatVersion, writer.stringWriter,
          writer.objectWriter, writer.linkWriter);

  Uint8List getContents() {
    if (_buffers == null) {
      return new Uint8List.view(
          _currentBuffer.buffer, _currentBuffer.offsetInBytes, _currentLength);
    }
    final Uint8List result = new Uint8List(_buffersLength + _currentLength);
    int position = 0;
    for (int i = 0; i < _buffers.length; i += 2) {
      final Uint8List buf = _buffers[i];
      final int len = _buffers[i + 1];
      result.setRange(position, position + len, buf);
      position += len;
    }
    assert(position == _buffersLength);
    result.setRange(position, position + _currentLength, _currentBuffer);
    return result;
  }

  void writeContentsToBinarySink(BinarySink sink) {
    if (_buffers != null) {
      for (int i = 0; i < _buffers.length; i += 2) {
        Uint8List buf = _buffers[i];
        final int len = _buffers[i + 1];
        if (len != buf.length) {
          buf = new Uint8List.view(buf.buffer, buf.offsetInBytes, len);
        }
        sink.writeBytes(buf);
      }
    }
    Uint8List buf = _currentBuffer;
    if (_currentLength != buf.length) {
      buf = new Uint8List.view(buf.buffer, buf.offsetInBytes, _currentLength);
    }
    sink.writeBytes(buf);
  }

  int get offset => _buffersLength + _currentLength;

  @pragma('vm:prefer-inline')
  void _addByte(int value) {
    assert((value >> 8) == 0);
    _currentBuffer[_currentLength] = value;
    ++_currentLength;
  }

  void _flushBuffer(Uint8List buf, int len) {
    _buffers ??= <dynamic>[];
    _buffers.add(buf);
    _buffers.add(len);
    _buffersLength += len;
  }

  void _flushCurrentBuffer() {
    _flushBuffer(_currentBuffer, _currentLength);
    _currentBuffer = null;
    _currentLength = 0;
  }

  @pragma('vm:never-inline')
  void _grow() {
    _flushCurrentBuffer();
    // Callers of _grow() expect up to avoidCopyingSize bytes to be available.
    assert(_nextBufferSize >= avoidCopyingSize);
    _currentBuffer = new Uint8List(_nextBufferSize);
    _nextBufferSize = _nextBufferSize << 1;
  }

  @pragma('vm:prefer-inline')
  void writeByte(int value) {
    if (_currentLength == _currentBuffer.length) {
      _grow();
    }
    _addByte(value);
  }

  void appendUint8List(Uint8List src) {
    if (src.length < avoidCopyingSize) {
      if (_currentLength > _currentBuffer.length - src.length) {
        _grow();
      }
      _currentBuffer.setRange(_currentLength, _currentLength + src.length, src);
      _currentLength += src.length;
    } else {
      final int remainingBytes = _currentBuffer.length - _currentLength;
      if (remainingBytes >= minRemainderToKeep) {
        final Uint8List remainder = new Uint8List.view(_currentBuffer.buffer,
            _currentBuffer.offsetInBytes + _currentLength, remainingBytes);
        _flushCurrentBuffer();
        _flushBuffer(src, src.length);
        _currentBuffer = remainder;
        _currentLength = 0;
      } else {
        _flushCurrentBuffer();
        _currentBuffer = src;
        _currentLength = src.length;
      }
    }
  }

  void appendWriter(BufferedWriter other) {
    final int remainingBytes = _currentBuffer.length - _currentLength;
    Uint8List remainder;
    if (remainingBytes >= minRemainderToKeep &&
        remainingBytes > (other._currentBuffer.length - other._currentLength)) {
      remainder = new Uint8List.view(_currentBuffer.buffer,
          _currentBuffer.offsetInBytes + _currentLength, remainingBytes);
    }
    _flushCurrentBuffer();
    if (other._buffers != null) {
      _buffers.addAll(other._buffers);
      _buffersLength += other._buffersLength;
    }
    if (remainder != null) {
      _flushBuffer(other._currentBuffer, other._currentLength);
      _currentBuffer = remainder;
      _currentLength = 0;
    } else {
      _currentBuffer = other._currentBuffer;
      _currentLength = other._currentLength;
    }
    // Reset [other] to make sure it is no longer used.
    other._buffers = null;
    other._buffersLength = 0;
    other._currentBuffer = null;
    other._currentLength = 0;
  }

  @pragma('vm:prefer-inline')
  void writeUInt32(int value) {
    if ((value >> 32) != 0) {
      throw 'Unable to write $value as 32-bit unsigned integer';
    }
    if (_currentLength > _currentBuffer.length - 4) {
      _grow();
    }
    // TODO(alexmarkov): consider using native byte order
    _addByte((value >> 24) & 0xFF);
    _addByte((value >> 16) & 0xFF);
    _addByte((value >> 8) & 0xFF);
    _addByte(value & 0xFF);
  }

  @pragma('vm:prefer-inline')
  void writePackedUInt30(int value) {
    if ((value >> 30) != 0) {
      throw 'Unable to write $value as 30-bit unsigned integer';
    }
    if (value < 0x80) {
      writeByte(value);
    } else if (value < 0x4000) {
      if (_currentLength > _currentBuffer.length - 2) {
        _grow();
      }
      _addByte((value >> 8) | 0x80);
      _addByte(value & 0xFF);
    } else {
      if (_currentLength > _currentBuffer.length - 4) {
        _grow();
      }
      _addByte((value >> 24) | 0xC0);
      _addByte((value >> 16) & 0xFF);
      _addByte((value >> 8) & 0xFF);
      _addByte(value & 0xFF);
    }
  }

  @pragma('vm:prefer-inline')
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
      writeByte(part);
    } while (!last);
  }

  @pragma('vm:prefer-inline')
  void writePackedStringReference(String value) {
    writePackedUInt30(stringWriter.put(value));
  }

  @pragma('vm:prefer-inline')
  void writePackedObject(BytecodeObject object) {
    objectWriter.writeObject(object, this);
  }

  @pragma('vm:prefer-inline')
  void writePackedList(List<BytecodeObject> objects) {
    writePackedUInt30(objects.length);
    for (var obj in objects) {
      writePackedObject(obj);
    }
  }

  @pragma('vm:prefer-inline')
  void writeLinkOffset(Object target) {
    final offset = linkWriter.getOffset(target);
    writePackedUInt30(offset);
  }
}

class BufferedReader {
  int formatVersion;
  StringReader stringReader;
  ObjectReader objectReader;
  LinkReader linkReader;
  final List<int> bytes;
  final int baseOffset;

  /// Position within [bytes], already includes [baseOffset].
  int _pos;

  BufferedReader(this.formatVersion, this.stringReader, this.objectReader,
      this.linkReader, this.bytes,
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

  T readLinkOffset<T extends BytecodeDeclaration>() {
    final offset = readPackedUInt30();
    return linkReader.get<T>(offset);
  }

  ForwardReference<T>
      readLinkOffsetAsForwardReference<T extends BytecodeDeclaration>() {
    final offset = readPackedUInt30();
    return new ForwardReference<T>(offset, linkReader);
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

int doubleToIntBits(double value) {
  final buf = new ByteData(8);
  buf.setFloat64(0, value, Endian.little);
  return buf.getInt64(0, Endian.little);
}

double intBitsToDouble(int bits) {
  final buf = new ByteData(8);
  buf.setInt64(0, bits, Endian.little);
  return buf.getFloat64(0, Endian.little);
}

class PackedUInt30DeltaEncoder {
  int _last = 0;

  void write(BufferedWriter write, int value) {
    write.writePackedUInt30(value - _last);
    _last = value;
  }
}

class PackedUInt30DeltaDecoder {
  int _last = 0;

  int read(BufferedReader reader) {
    int value = reader.readPackedUInt30() + _last;
    _last = value;
    return value;
  }
}

class SLEB128DeltaEncoder {
  int _last = 0;

  void write(BufferedWriter writer, int value) {
    writer.writeSLEB128(value - _last);
    _last = value;
  }
}

class SLEB128DeltaDecoder {
  int _last = 0;

  int read(BufferedReader reader) {
    int value = reader.readSLEB128() + _last;
    _last = value;
    return value;
  }
}

class BytecodeDeclaration {
  int _offset;
}

class LinkWriter {
  void put(BytecodeDeclaration target, int offset) {
    target._offset = offset;
  }

  int getOffset(BytecodeDeclaration target) {
    return target._offset ??
        (throw 'Offset of ${target.runtimeType} $target is not set');
  }
}

class LinkReader {
  final _map = <Type, Map<int, BytecodeDeclaration>>{};

  void setOffset<T extends BytecodeDeclaration>(T target, int offset) {
    final offsetToObject = (_map[T] ??= <int, BytecodeDeclaration>{});
    final previous = offsetToObject[offset];
    if (previous != null) {
      throw 'Unable to associate offset $T/$offset with ${target.runtimeType} $target.'
          ' It is already associated with ${previous.runtimeType} $previous';
    }
    offsetToObject[offset] = target;
  }

  T get<T extends BytecodeDeclaration>(int offset) {
    return _map[T][offset] ?? (throw 'No object at offset $T/$offset');
  }
}

// Placeholder for an object which will be read in future.
class ForwardReference<T extends BytecodeDeclaration> {
  final int offset;
  final LinkReader linkReader;

  ForwardReference(this.offset, this.linkReader);

  T get() => linkReader.get<T>(offset);
}

class NamedEntryStatistics {
  final String name;
  int size = 0;
  int count = 0;

  NamedEntryStatistics(this.name);

  String toString() => "${name.padRight(40)}:    ${size.toString().padLeft(10)}"
      "  (count: ${count.toString().padLeft(8)})";
}

class BytecodeSizeStatistics {
  static int componentSize = 0;
  static int objectTableSize = 0;
  static int objectTableEntriesCount = 0;
  static int stringTableSize = 0;
  static int librariesSize = 0;
  static int classesSize = 0;
  static int membersSize = 0;
  static int codeSize = 0;
  static int sourcePositionsSize = 0;
  static int sourceFilesSize = 0;
  static int lineStartsSize = 0;
  static int localVariablesSize = 0;
  static int annotationsSize = 0;
  static int constantPoolSize = 0;
  static int instructionsSize = 0;
  static List<NamedEntryStatistics> constantPoolStats =
      <NamedEntryStatistics>[];
  static List<NamedEntryStatistics> objectTableStats = <NamedEntryStatistics>[];

  static void reset() {
    componentSize = 0;
    objectTableSize = 0;
    objectTableEntriesCount = 0;
    stringTableSize = 0;
    librariesSize = 0;
    classesSize = 0;
    membersSize = 0;
    codeSize = 0;
    sourcePositionsSize = 0;
    sourceFilesSize = 0;
    lineStartsSize = 0;
    localVariablesSize = 0;
    annotationsSize = 0;
    constantPoolSize = 0;
    instructionsSize = 0;
    constantPoolStats = <NamedEntryStatistics>[];
    objectTableStats = <NamedEntryStatistics>[];
  }

  static void dump() {
    print("Bytecode size statistics:");
    print("  Bytecode component:  $componentSize");
    print(
        "   - object table:     $objectTableSize   (count: $objectTableEntriesCount)");
    for (var entry in objectTableStats) {
      print("       - $entry");
    }
    print("   - string table:     $stringTableSize");
    print("  Libraries:           $librariesSize");
    print("  Classes:             $classesSize");
    print("  Members:             $membersSize");
    print("  Source positions:    $sourcePositionsSize");
    print("  Source files:        $sourceFilesSize");
    print("  Line starts:         $lineStartsSize");
    print("  Local variables:     $localVariablesSize");
    print("  Annotations:         $annotationsSize");
    print("  Code:                $codeSize");
    print("   - constant pool:    $constantPoolSize");
    for (var entry in constantPoolStats) {
      print("       - $entry");
    }
    print("   - instructions:     $instructionsSize");
  }
}

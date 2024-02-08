// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Note that these values MUST match the arguments to -add_empty_section in
// runtime/BUILD.gn.
const String reservedSegmentName = '__CUSTOM';
const String reservedSectionName = '__space_for_note';

// Note that this value MUST match runtime/bin/snapshot_utils.cc, which looks
// specifically for the snapshot in this note.
const String snapshotNoteName = '__dart_app_snap';

/// The page size for aligning segments in MachO files. X64 MacOS uses 4k pages,
/// and ARM64 MacOS uses 16k pages, so we use 16k here.
const int segmentAlignmentLog2 = 14;
const int segmentAlignment = 1 << segmentAlignmentLog2;

/// Pads the given size so that it is a multiple of the given alignment.
int align(int size, int alignment) {
  final unpadded = size % alignment;
  return size + (unpadded != 0 ? alignment - unpadded : 0);
}

/// A reader utility class that wraps a stream to include endian information
/// and whether or not the architecture for the MachO file uses 64-bit pointers.
class MachOReader {
  final RandomAccessFile _stream;
  final Endian _endian;

  /// Used to determine whether to read 4 or 8 bytes for the `lc_str` union
  /// type, which depends on the `__LP64__` define (e.g., is the target
  /// architecture using 64-bit pointers). May be null if no `lc_str` values
  /// will be read by this reader.
  final bool? _arch64BitPointers;

  MachOReader(this._stream, this._endian, [this._arch64BitPointers]);

  /// Reads a 16-bit unsigned integer from the contained stream.
  int readUint16() =>
      ByteData.sublistView(_stream.readSync(2)).getUint16(0, _endian);

  /// Reads a 32-bit unsigned integer from the contained stream.
  int readUint32() =>
      ByteData.sublistView(_stream.readSync(4)).getUint32(0, _endian);

  /// Reads a 64-bit unsigned integer from the contained stream.
  int readUint64() =>
      ByteData.sublistView(_stream.readSync(8)).getUint64(0, _endian);

  /// Reads a 32-bit signed integer from the contained stream.
  int readInt32() =>
      ByteData.sublistView(_stream.readSync(4)).getInt32(0, _endian);

  /// Reads an unsigned integer of the given word size from the contained
  /// stream. Throws an [ArgumentError] for if [wordSize] is not 4 or 8.
  int readUword(int wordSize) => switch (wordSize) {
        4 => readUint32(),
        8 => readUint64(),
        _ => throw ArgumentError('Unexpected word size: $wordSize', 'wordSize'),
      };

  /// Reads a fixed length string from the contained stream. The string may be
  /// null terminated, in which case the returned string may contain less
  /// code points than the provided size.
  String readFixedLengthNullTerminatedString(int size) {
    final buffer = _stream.readSync(size);
    return String.fromCharCodes(buffer.takeWhile((value) => value != 0));
  }

  /// Reads an `lc_str` value from the contained stream. For 32-bit
  /// architectures, or 64-bit architectures using 32-bit pointers, this is
  /// 32 bits. On 64-bit architectures using 64-bit pointers, this is 64 bits.
  int readLCString() => _arch64BitPointers! ? readUint64() : readUint32();

  /// Reads [size] bytes from the contained stream.
  Uint8List readBytes(int size) => _stream.readSync(size);
}

/// A writer utility class that wraps a stream to include endian information
/// and whether or not the architecture for the MachO file uses 64-bit pointers.
class MachOWriter {
  final RandomAccessFile _stream;
  final Endian _endian;

  /// Used to determine whether to write 4 or 8 bytes for the `lc_str` union
  /// type, which depends on the `__LP64__` define (e.g., is the target
  /// architecture using 64-bit pointers). May be null if no `lc_str` values
  /// will be written by this reader.
  final bool? _arch64BitPointers;

  MachOWriter(this._stream, this._endian, [this._arch64BitPointers]);

  /// Writes a 16-bit unsigned integer to the contained stream. Throws
  /// a [FormatException] if the value is negative or does not fit in 16 bits.
  void writeUint16(int value) {
    if (value < 0) {
      throw FormatException('Attempted to write a negative value $value');
    }
    if ((value >> 16) != 0) {
      throw FormatException("Attempted to write an unsigned value that doesn't "
          'fit in 16 bits: $value');
    }
    final buffer = ByteData(2)..setUint16(0, value, _endian);
    _stream.writeFromSync(Uint8List.sublistView(buffer));
  }

  /// Writes a 32-bit unsigned integer to the contained stream. Throws
  /// a [FormatException] if the value is negative or does not fit in 32 bits.
  void writeUint32(int value) {
    if (value < 0) {
      throw FormatException('Attempted to write a negative value $value');
    }
    if ((value >> 32) != 0) {
      throw FormatException("Attempted to write an unsigned value that doesn't "
          'fit in 32 bits: $value');
    }
    final buffer = ByteData(4)..setUint32(0, value, _endian);
    _stream.writeFromSync(Uint8List.sublistView(buffer));
  }

  /// Writes a 64-bit unsigned integer to the contained stream.
  void writeUint64(int value) {
    final buffer = ByteData(8)..setUint64(0, value, _endian);
    _stream.writeFromSync(Uint8List.sublistView(buffer));
  }

  /// Writes a 32-bit unsigned integer to the contained stream. Throws
  /// a [FormatException] if the signed value does not fit in 32 bits.
  void writeInt32(int value) {
    if (((value < 0 ? ~value : value) >> 31) != 0) {
      throw FormatException("Attempted to write a signed value that doesn't "
          'fit in 32 bits: $value');
    }
    final buffer = ByteData(4)..setInt32(0, value, _endian);
    _stream.writeFromSync(Uint8List.sublistView(buffer));
  }

  /// Writes an unsigned integer with a given word size to the contained
  /// stream. Throws an [ArgumentError] for if [wordSize] is not 4 or 8.
  void writeUword(int value, int wordSize) => switch (wordSize) {
        4 => writeUint32(value),
        8 => writeUint64(value),
        _ => throw ArgumentError('Unexpected word size: $wordSize', 'wordSize'),
      };

  /// Writes the given string as an ASCII-encoded null terminated string
  /// with a given fixed length. Throws a format exception if the ASCII
  /// character length of the string is longer than the given length.
  /// If the ASCII character length of the string is the same as the given
  /// length, there will be no null terminator in the written data.
  void writeFixedLengthNullTerminatedString(String s, int length) {
    final buffer = Uint8List(length);
    final encoded = ascii.encode(s);
    if (encoded.length > length) {
      throw FormatException('Attempted to write a string longer than $length '
          'characters: "$s"');
    }
    buffer.setRange(0, encoded.length, encoded);
    _stream.writeFromSync(buffer);
  }

  /// Writes an `lc_str` value to the contained stream. For 32-bit
  /// architectures, or 64-bit architectures using 32-bit pointers, this is
  /// 32 bits. On 64-bit architectures using 64-bit pointers, this is 64 bits.
  void writeLCString(int value) =>
      _arch64BitPointers! ? writeUint64(value) : writeUint32(value);

  /// Writes the given bytes to the contained stream.
  void writeBytes(Uint8List bytes) => _stream.writeFromSync(bytes);
}

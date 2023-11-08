// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

int align(int size, int base) {
  final int over = size % base;
  if (over != 0) {
    return size + (base - over);
  }
  return size;
}

class BytesBacked {
  ByteData data;

  BytesBacked(this.data);

  int get size => data.lengthInBytes;

  Future<void> write(RandomAccessFile output) async {
    await output.writeFrom(Uint8List.sublistView(data));
  }
}

class CoffFileHeader extends BytesBacked {
  CoffFileHeader._(super.data);

  static const _fileHeaderSize = 20;
  static const _sectionCountOffset = 2;
  static const _optionalHeaderSizeOffset = 16;

  static CoffFileHeader fromTypedData(TypedData source, int offset) {
    if (source.lengthInBytes < offset + _fileHeaderSize) {
      throw 'File is truncated within the COFF file header';
    }
    final buffer = Uint8List(_fileHeaderSize);
    buffer.setAll(
        0, Uint8List.sublistView(source, offset, offset + _fileHeaderSize));
    return CoffFileHeader._(ByteData.sublistView(buffer));
  }

  int get sectionCount => data.getUint16(_sectionCountOffset, Endian.little);
  set sectionCount(int value) =>
      data.setUint16(_sectionCountOffset, value, Endian.little);

  int get optionalHeaderSize =>
      data.getUint16(_optionalHeaderSizeOffset, Endian.little);
}

class CoffOptionalHeader extends BytesBacked {
  CoffOptionalHeader._(super.data);

  static const _pe32Magic = 0x10b;
  static const _pe32PlusMagic = 0x20b;

  static const _magicOffset = 0;
  static const _sectionAlignmentOffset = 32;
  static const _fileAlignmentOffset = 36;
  static const _imageSizeOffset = 56;
  static const _headersSizeOffset = 60;

  static CoffOptionalHeader fromTypedData(
      TypedData source, int offset, int size) {
    if (source.lengthInBytes < offset + size) {
      throw 'File is truncated within the COFF optional header';
    }
    final buffer = Uint8List(size);
    buffer.setAll(0, Uint8List.sublistView(source, offset, offset + size));
    final data = ByteData.sublistView(buffer);
    final magic = data.getUint16(_magicOffset, Endian.little);
    if (magic != _pe32Magic && magic != _pe32PlusMagic) {
      throw 'Not a PE32 or PE32+ image file';
    }
    return CoffOptionalHeader._(data);
  }

  // The alignment used for virtual addresses of sections, _not_ file offsets.
  int get sectionAlignment =>
      data.getUint32(_sectionAlignmentOffset, Endian.little);

  // The alignment used for file offsets of section data and other contents.
  int get fileAlignment => data.getUint32(_fileAlignmentOffset, Endian.little);

  int get headersSize => data.getUint32(_headersSizeOffset, Endian.little);
  set headersSize(int value) =>
      data.setUint32(_headersSizeOffset, value, Endian.little);

  int get imageSize => data.getUint32(_imageSizeOffset, Endian.little);
  set imageSize(int value) =>
      data.setUint32(_imageSizeOffset, value, Endian.little);
}

class CoffSectionHeader extends BytesBacked {
  CoffSectionHeader._(super.data);

  static const _virtualSizeOffset = 8;
  static const _virtualAddressOffset = 12;
  static const _fileSizeOffset = 16;
  static const _fileOffsetOffset = 20;
  static const _characteristicsOffset = 36;

  static const _discardableFlag = 0x02000000;

  String get name => String.fromCharCodes(Uint8List.sublistView(data, 0, 8));
  set name(String name) {
    // Each section header has only eight bytes for the section name.
    // First reset it to zeroes, then copy over the UTF-8 encoded version.
    final buffer = Uint8List.sublistView(data, 0, 8);
    buffer.fillRange(0, 8, 0);
    buffer.setAll(0, utf8.encode(name));
  }

  int get virtualAddress =>
      data.getUint32(_virtualAddressOffset, Endian.little);
  set virtualAddress(int offset) =>
      data.setUint32(_virtualAddressOffset, offset, Endian.little);

  int get virtualSize => data.getUint32(_virtualSizeOffset, Endian.little);
  set virtualSize(int offset) =>
      data.setUint32(_virtualSizeOffset, offset, Endian.little);

  int get fileOffset => data.getUint32(_fileOffsetOffset, Endian.little);
  set fileOffset(int offset) =>
      data.setUint32(_fileOffsetOffset, offset, Endian.little);

  int get fileSize => data.getUint32(_fileSizeOffset, Endian.little);
  set fileSize(int offset) =>
      data.setUint32(_fileSizeOffset, offset, Endian.little);

  int get characteristics =>
      data.getUint32(_characteristicsOffset, Endian.little);
  set characteristics(int value) =>
      data.setUint32(_characteristicsOffset, value, Endian.little);

  bool get isDiscardable => characteristics & _discardableFlag != 0;
  set isDiscardable(bool value) {
    if (value) {
      characteristics |= _discardableFlag;
    } else {
      characteristics &= ~_discardableFlag;
    }
  }
}

class CoffSectionTable extends BytesBacked {
  CoffSectionTable._(super.data);

  static const _entrySize = 40;

  static CoffSectionTable fromTypedData(
      TypedData source, int offset, int sections) {
    final size = sections * _entrySize;
    if (source.lengthInBytes < offset + size) {
      throw 'File is truncated within the COFF section table';
    }
    final buffer = Uint8List(size);
    buffer.setAll(0, Uint8List.sublistView(source, offset, offset + size));
    return CoffSectionTable._(ByteData.sublistView(buffer));
  }

  Iterable<CoffSectionHeader> get entries sync* {
    for (int i = 0; i < size; i += _entrySize) {
      yield CoffSectionHeader._(ByteData.sublistView(data, i, i + _entrySize));
    }
  }

  int get addressEnd => entries.fold(
      0, (i, entry) => max(i, entry.virtualAddress + entry.virtualSize));
  int get offsetEnd =>
      entries.fold(0, (i, entry) => max(i, entry.fileOffset + entry.fileSize));

  CoffSectionHeader allocateNewSectionHeader() {
    final newBuffer = Uint8List(size + _entrySize);
    newBuffer.setAll(0, Uint8List.sublistView(data));
    data = ByteData.sublistView(newBuffer);
    return CoffSectionHeader._(
        ByteData.sublistView(data, size - _entrySize, size));
  }
}

class CoffHeaders {
  final int _coffOffset;
  final CoffFileHeader fileHeader;
  final CoffOptionalHeader optionalHeader;
  final CoffSectionTable sectionTable;

  CoffHeaders._(this._coffOffset, this.fileHeader, this.optionalHeader,
      this.sectionTable);

  static CoffHeaders fromTypedData(TypedData source, int offset) {
    final fileHeader = CoffFileHeader.fromTypedData(source, offset);
    final optionalHeader = CoffOptionalHeader.fromTypedData(
        source, offset + fileHeader.size, fileHeader.optionalHeaderSize);
    final sectionTable = CoffSectionTable.fromTypedData(
        source,
        offset + fileHeader.size + optionalHeader.size,
        fileHeader.sectionCount);
    return CoffHeaders._(offset, fileHeader, optionalHeader, sectionTable);
  }

  // Keep in sync with kSnapshotSectionName in snapshot_utils.cc.
  static const _snapshotSectionName = "snapshot";

  int get size => optionalHeader.headersSize;

  void addSnapshotSectionHeader(int length) {
    final oldHeadersSize = optionalHeader.headersSize;
    final address =
        align(sectionTable.addressEnd, optionalHeader.sectionAlignment);
    final offset = align(sectionTable.offsetEnd, optionalHeader.fileAlignment);

    // Create and fill the new section header entry.
    final newHeader = sectionTable.allocateNewSectionHeader();
    newHeader.name = _snapshotSectionName;
    newHeader.virtualAddress = address;
    newHeader.virtualSize = length;
    newHeader.fileOffset = offset;
    newHeader.fileSize = align(length, optionalHeader.fileAlignment);
    newHeader.isDiscardable = true;
    // Leave the rest of the header fields with zero values.

    // Increment the number of sections in the file header.
    fileHeader.sectionCount += 1;

    // Adjust the header size stored in the optional header, which must be
    // a multiple of fileAlignment.
    optionalHeader.headersSize = align(
        _coffOffset + fileHeader.size + optionalHeader.size + sectionTable.size,
        optionalHeader.fileAlignment);

    // If the size of the headers changed, we'll need to adjust the section
    // offsets.
    final headersSizeDiff = optionalHeader.headersSize - oldHeadersSize;
    if (headersSizeDiff > 0) {
      // Safety check that section virtual addresses need not be adjusted, as
      // that requires rewriting much more of the fields and section contents.
      // (Generally, the size of the headers is much smaller than the section
      // alignment and so this is not expected to happen.)
      if (size ~/ optionalHeader.sectionAlignment !=
          oldHeadersSize ~/ optionalHeader.sectionAlignment) {
        throw 'Adding the snapshot would require adjusting virtual addresses';
      }
      assert(headersSizeDiff % optionalHeader.fileAlignment == 0);
      for (final entry in sectionTable.entries) {
        entry.fileOffset += headersSizeDiff;
      }
    }

    // Adjust the image size stored in the optional header, which must be a
    // multiple of section alignment (as it is the size in memory, not on disk).
    optionalHeader.imageSize = align(
        newHeader.virtualAddress + newHeader.virtualSize,
        optionalHeader.sectionAlignment);
  }

  Future<void> write(RandomAccessFile output) async {
    await fileHeader.write(output);
    await optionalHeader.write(output);
    await sectionTable.write(output);
    // Pad to the recorded headers size, which includes the MS-DOS stub.
    final written = await output.position();
    await output.writeFrom(Uint8List(size - written));
  }
}

class PortableExecutable {
  final Uint8List source;
  final CoffHeaders headers;
  final int sourceFileHeaderOffset;
  final int sourceSectionContentsOffset;

  PortableExecutable._(this.source, this.headers, this.sourceFileHeaderOffset,
      this.sourceSectionContentsOffset);

  static const _expectedPESignature = <int>[80, 69, 0, 0];
  static const _offsetForPEOffset = 0x3c;

  static Future<PortableExecutable> fromFile(File file) async {
    final source = await file.readAsBytes();
    final byteData = ByteData.sublistView(source);
    final peOffset = byteData.getUint32(_offsetForPEOffset, Endian.little);
    for (int i = 0; i < _expectedPESignature.length; i++) {
      if (byteData.getUint8(peOffset + i) != _expectedPESignature[i]) {
        throw 'Not a Portable Executable file';
      }
    }
    final fileHeaderOffset = peOffset + _expectedPESignature.length;
    final headers = CoffHeaders.fromTypedData(source, fileHeaderOffset);
    final sectionContentsOffset = headers.size;
    return PortableExecutable._(
        source, headers, fileHeaderOffset, sectionContentsOffset);
  }

  Future<void> _fileAlignSectionEnd(RandomAccessFile output) async {
    final current = await output.position();
    final padding =
        align(current, headers.optionalHeader.fileAlignment) - current;
    await output.writeFrom(Uint8List(padding));
  }

  Future<void> appendSnapshotAndWrite(File output, File snapshot) async {
    final stream = await output.open(mode: FileMode.write);
    // Write MS-DOS stub.
    await stream.writeFrom(source, 0, sourceFileHeaderOffset);
    // Write headers with additional snapshot section.
    final snapshotBytes = await snapshot.readAsBytes();
    headers.addSnapshotSectionHeader(snapshotBytes.length);
    await headers.write(stream);
    // Write original section contents with alignment padding.
    await stream.writeFrom(source, sourceSectionContentsOffset);
    await _fileAlignSectionEnd(stream);
    // Write snapshot with alignment padding.
    await stream.writeFrom(snapshotBytes);
    await _fileAlignSectionEnd(stream);
    await stream.close();
  }
}

// Writes an "appended" dart runtime + script snapshot file in a format
// compatible with Portable Executable files.
Future writeAppendedPortableExecutable(
    String dartaotruntimePath, String payloadPath, String outputPath) async {
  File originalExecutableFile = File(dartaotruntimePath);
  File newSegmentFile = File(payloadPath);
  File outputFile = File(outputPath);

  final pe = await PortableExecutable.fromFile(originalExecutableFile);
  await pe.appendSnapshotAndWrite(outputFile, newSegmentFile);
}

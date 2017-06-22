// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

class Asset {
  final String name;
  final Uint8List data;

  Asset(this.name, this.data);

  String get mimeType {
    var extensionStart = name.lastIndexOf('.');
    var extension = name.substring(extensionStart + 1);
    switch (extension) {
      case 'html':
        return 'text/html; charset=UTF-8';
      case 'dart':
        return 'application/dart; charset=UTF-8';
      case 'js':
        return 'application/javascript; charset=UTF-8';
      case 'css':
        return 'text/css; charset=UTF-8';
      case 'gif':
        return 'image/gif';
      case 'png':
        return 'image/png';
      case 'jpg':
        return 'image/jpeg';
      case 'jpeg':
        return 'image/jpeg';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'text/plain';
    }
  }

  static HashMap<String, Asset> request() {
    Uint8List tarBytes = _requestAssets();
    if (tarBytes == null) {
      return null;
    }
    List assetList = _decodeAssets(tarBytes);
    HashMap<String, Asset> assets = new HashMap<String, Asset>();
    for (int i = 0; i < assetList.length; i += 2) {
      var a = new Asset(assetList[i], assetList[i + 1]);
      assets[a.name] = a;
    }
    return assets;
  }

  String toString() => '$name ($mimeType)';
}

List _decodeAssets(Uint8List data) native "VMService_DecodeAssets";

HashMap<String, Asset> _assets;
HashMap<String, Asset> get assets {
  if (_assets == null) {
    try {
      _assets = Asset.request();
    } catch (e) {
      print('Could not load Observatory assets: $e');
    }
  }
  return _assets;
}

class _ByteStream {
  final Uint8List bytes;
  final int offset;
  int get length => bytes.length - offset;
  int _cursor = 0;

  _ByteStream(this.bytes, [this.offset = 0]);

  void reset() {
    _cursor = 0;
  }

  int peekByte([int index = 0]) => bytes[offset + _cursor + index];

  int readByte() {
    int r = peekByte();
    _advance(1);
    return r;
  }

  void skip(int bytes) => _advance(bytes);

  void seekToNextBlock(int blockSize) {
    int remainder = blockSize - (_cursor % blockSize);
    _advance(remainder);
  }

  void _advance(int bytes) {
    _cursor += bytes;
    if (_cursor > length) {
      _cursor = length;
    }
  }

  int get remaining => length - _cursor;
  bool get hasMore => remaining > 0;
  int get cursor => _cursor;
  void set cursor(int cursor) {
    _cursor = cursor;
    if (_cursor > length) {
      _cursor = length;
    }
  }
}

class _TarArchive {
  static const List<int> tarMagic = const [0x75, 0x73, 0x74, 0x61, 0x72, 0];
  static const List<int> tarVersion = const [0x30, 0x30];
  static const int tarHeaderSize = 512;
  static const int tarHeaderFilenameSize = 100;
  static const int tarHeaderFilenameOffset = 0;
  static const int tarHeaderSizeSize = 12;
  static const int tarHeaderSizeOffset = 124;
  static const int tarHeaderTypeSize = 1;
  static const int tarHeaderTypeOffset = 156;
  static const int tarHeaderFileType = 0x30;

  static String _readCString(_ByteStream bs, int length) {
    StringBuffer sb = new StringBuffer();
    int count = 0;
    while (bs.hasMore && count < length) {
      if (bs.peekByte() == 0) {
        // Null character.
        break;
      }
      sb.writeCharCode(bs.readByte());
      count++;
    }
    return sb.toString();
  }

  static String _readFilename(_ByteStream bs) {
    String filename = _readCString(bs, tarHeaderFilenameSize);
    if (filename.startsWith('/')) {
      return filename;
    }
    return '/' + filename;
  }

  static Uint8List _readContents(_ByteStream bs, int size) {
    Uint8List result = new Uint8List(size);
    int i = 0;
    while (bs.hasMore && i < size) {
      result[i] = bs.readByte();
      i++;
    }
    bs.seekToNextBlock(tarHeaderSize);
    return result;
  }

  static void _skipContents(_ByteStream bs, int size) {
    bs.skip(size);
    bs.seekToNextBlock(tarHeaderSize);
  }

  static int _readSize(_ByteStream bs) {
    String octalSize = _readCString(bs, tarHeaderSizeSize);
    return int.parse(octalSize, radix: 8, onError: (_) => 0);
  }

  static int _readType(_ByteStream bs) {
    return bs.readByte();
  }

  static bool _endOfArchive(_ByteStream bs) {
    if (bs.remaining < (tarHeaderSize * 2)) {
      return true;
    }
    for (int i = 0; i < (tarHeaderSize * 2); i++) {
      if (bs.peekByte(i) != 0) {
        return false;
      }
    }
    return true;
  }

  final _ByteStream _bs;

  _TarArchive(Uint8List bytes) : _bs = new _ByteStream(bytes);

  bool hasNext() {
    return !_endOfArchive(_bs);
  }

  Asset next() {
    int startOfBlock = _bs.cursor;
    String filename = _readFilename(_bs);
    _bs.cursor = startOfBlock + tarHeaderSizeOffset;
    int size = _readSize(_bs);
    _bs.cursor = startOfBlock + tarHeaderTypeOffset;
    int type = _readType(_bs);
    _bs.seekToNextBlock(tarHeaderSize);
    if (type != tarHeaderFileType) {
      _skipContents(_bs, size);
      return null;
    }
    Uint8List bytes = _readContents(_bs, size);
    return new Asset(filename, bytes);
  }
}

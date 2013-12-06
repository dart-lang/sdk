// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.internal_asset;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'asset.dart';
import 'asset_id.dart';
import 'file_pool.dart';
import 'serialize.dart';
import 'stream_replayer.dart';
import 'utils.dart';

/// Serialize an asset to a form that's safe to send across isolates.
Map serializeAsset(Asset asset) {
  var id = serializeId(asset.id);
  if (asset is BinaryAsset) {
    return {
      'type': 'binary',
      'id': id,
      'contents': asset._contents
    };
  } else if (asset is FileAsset) {
    return {
      'type': 'file',
      'id': id,
      'path': asset._path
    };
  } else if (asset is StringAsset) {
    return {
      'type': 'string',
      'id': id,
      'contents': asset._contents
    };
  } else {
    // [asset] is probably a [StreamAsset], but it's possible that the user has
    // created a custom subclass, in which case we just serialize the stream
    // anyway.
    return {
      'type': 'stream',
      'id': id,
      'stream': serializeStream(asset.read())
    };
  }
}

/// Deserialize an asset from the form returned by [serialize].
Asset deserializeAsset(Map asset) {
  var id = deserializeId(asset['id']);
  switch (asset['type']) {
    case 'binary': return new BinaryAsset(id, asset['contents']);
    case 'file': return new FileAsset(id, asset['path']);
    case 'string': return new StringAsset(id, asset['contents']);
    case 'stream':
      return new StreamAsset(id, deserializeStream(asset['stream']));
    default:
      throw new FormatException('Unknown asset type "${asset['type']}".');
  }
}

/// An asset whose data is stored in a list of bytes.
class BinaryAsset implements Asset {
  final AssetId id;

  final Uint8List _contents;

  BinaryAsset(this.id, List<int> contents)
      : _contents = toUint8List(contents);

  Future<String> readAsString({Encoding encoding}) {
    if (encoding == null) encoding = UTF8;

    return new Future.value(encoding.decode(_contents));
  }

  Stream<List<int>> read() => new Future<List<int>>.value(_contents).asStream();

  String toString() {
    var buffer = new StringBuffer();
    buffer.write("Bytes [");

    // Don't show the whole list if it's long.
    if (_contents.length > 11) {
      for (var i = 0; i < 5; i++) {
        buffer.write(byteToHex(_contents[i]));
        buffer.write(" ");
      }

      buffer.write("...");

      for (var i = _contents.length - 5; i < _contents.length; i++) {
        buffer.write(" ");
        buffer.write(byteToHex(_contents[i]));
      }
    } else {
      for (var i = 0; i < _contents.length; i++) {
        if (i > 0) buffer.write(" ");
        buffer.write(byteToHex(_contents[i]));
      }
    }

    buffer.write("]");
    return buffer.toString();
  }
}

/// An asset backed by a file on the local file system.
class FileAsset implements Asset {
  final AssetId id;

  /// Use a [FilePool] to handle reads so we can try to cope with running out
  /// of file descriptors more gracefully.
  static final _pool = new FilePool();

  final String _path;
  FileAsset(this.id, this._path);

  Future<String> readAsString({Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return _pool.readAsString(_path, encoding);
  }

  Stream<List<int>> read() => _pool.openRead(_path);

  String toString() => 'File "${_path}"';
}

/// An asset whose data is stored in a string.
class StringAsset implements Asset {
  final AssetId id;

  final String _contents;

  StringAsset(this.id, this._contents);

  Future<String> readAsString({Encoding encoding}) =>
      new Future.value(_contents);

  Stream<List<int>> read() =>
      new Future<List<int>>.value(UTF8.encode(_contents)).asStream();

  String toString() {
    // Don't show the whole string if it's long.
    var contents = _contents;
    if (contents.length > 40) {
      contents = contents.substring(0, 20) + " ... " +
                 contents.substring(contents.length - 20);
    }

    contents = _escape(contents);
    return 'String "$contents"';
  }

  String _escape(String string) {
    return string
        .replaceAll("\"", r'\"')
        .replaceAll("\n", r"\n")
        .replaceAll("\r", r"\r")
        .replaceAll("\t", r"\t");
  }
}

/// An asset whose data is available from a stream.
class StreamAsset implements Asset {
  final AssetId id;

  /// A stream replayer that records and replays the contents of the input
  /// stream.
  final StreamReplayer<List<int>> _replayer;

  StreamAsset(this.id, Stream<List<int>> stream)
      : _replayer = new StreamReplayer(stream);

  Future<String> readAsString({Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return _replayer.getReplay().toList()
        .then((chunks) => encoding.decode(flatten(chunks)));
  }

  Stream<List<int>> read() => _replayer.getReplay();

  String toString() => "Stream";
}

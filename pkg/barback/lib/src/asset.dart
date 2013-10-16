// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'asset_id.dart';
import 'file_pool.dart';
import 'stream_replayer.dart';
import 'utils.dart';

/// A blob of content.
///
/// Assets may come from the file system, or as the output of a [Transformer].
/// They are identified by [AssetId].
abstract class Asset {
  /// The ID for this asset.
  final AssetId id;

  Asset(this.id);

  factory Asset.fromBytes(AssetId id, List<int> bytes) =>
      new _BinaryAsset(id, bytes);

  factory Asset.fromFile(AssetId id, File file) =>
      new _FileAsset(id, file);

  factory Asset.fromString(AssetId id, String content) =>
      new _StringAsset(id, content);

  factory Asset.fromPath(AssetId id, String path) =>
      new _FileAsset(id, new File(path));

  /// Creates an asset from a stream.
  ///
  /// This immediately starts draining [stream].
  factory Asset.fromStream(AssetId id, Stream<List<int>> stream) =>
      new _StreamAsset(id, stream);

  /// Returns the contents of the asset as a string.
  ///
  /// If the asset was created from a [String] the original string is always
  /// returned and [encoding] is ignored. Otherwise, the binary data of the
  /// asset is decoded using [encoding], which defaults to [UTF8].
  Future<String> readAsString({Encoding encoding});

  /// Streams the binary contents of the asset.
  ///
  /// If the asset was created from a [String], this returns its UTF-8 encoding.
  Stream<List<int>> read();
}

/// An asset whose data is stored in a list of bytes.
class _BinaryAsset extends Asset {
  final List<int> _contents;

  _BinaryAsset(AssetId id, this._contents)
      : super(id);

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
class _FileAsset extends Asset {
  /// Use a [FilePool] to handle reads so we can try to cope with running out
  /// of file descriptors more gracefully.
  static final _pool = new FilePool();

  final File _file;
  _FileAsset(AssetId id, this._file)
      : super(id);

  Future<String> readAsString({Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return _pool.readAsString(_file, encoding);
  }

  Stream<List<int>> read() => _pool.openRead(_file);

  String toString() => 'File "${_file.path}"';
}

/// An asset whose data is stored in a string.
class _StringAsset extends Asset {
  final String _contents;

  _StringAsset(AssetId id, this._contents)
      : super(id);

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
class _StreamAsset extends Asset {
  /// A stream replayer that records and replays the contents of the input
  /// stream.
  final StreamReplayer<List<int>> _replayer;

  _StreamAsset(AssetId id, Stream<List<int>> stream)
      : _replayer = new StreamReplayer(stream),
        super(id);

  Future<String> readAsString({Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return _replayer.getReplay().toList()
        .then((chunks) => encoding.decode(flatten(chunks)));
  }

  Stream<List<int>> read() => _replayer.getReplay();

  String toString() => "Stream";
}

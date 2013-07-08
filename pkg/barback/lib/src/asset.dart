// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset;

import 'dart:async';
import 'dart:io';

import 'asset_id.dart';

/// A blob of content.
///
/// Assets may come from the file system, or as the output of a [Transformer].
/// They are identified by [AssetId].
abstract class Asset {
  /// The ID for this asset.
  final AssetId id;

  Asset(this.id);

  factory Asset.fromFile(AssetId id, File file) {
    return new _FileAsset(id, file);
  }

  factory Asset.fromString(AssetId id, String content) {
    return new _StringAsset(id, content);
  }

  factory Asset.fromPath(AssetId id, String path) {
    return new _FileAsset(id, new File(path));
  }

  // TODO(rnystrom): This prevents users from defining their own
  // implementations of Asset. Use serialization package instead.
  factory Asset.deserialize(data) {
    // TODO(rnystrom): Handle errors.
    var id = new AssetId.parse(data[1]);
    switch (data[0]) {
      case "file": return new _FileAsset(id, new File(data[2])); break;
      case "string": return new _StringAsset(id, data[2]); break;
    }
  }

  /// Returns the contents of the asset as a string.
  // TODO(rnystrom): Figure out how binary assets should be handled.
  Future<String> readAsString();

  /// Streams the contents of the asset.
  Stream<List<int>> read();

  /// Serializes this [Asset] to an object that can be sent across isolates
  /// and passed to [deserialize].
  Object serialize();
}

/// An asset backed by a file on the local file system.
class _FileAsset extends Asset {
  final File _file;
  _FileAsset(AssetId id, this._file)
      : super(id);

  Future<String> readAsString() => _file.readAsString();
  Stream<List<int>> read() => _file.openRead();

  String toString() => 'File "${_file.path}"';

  Object serialize() => ["file", id.serialize(), _file.path];
}

/// An asset whose data is stored in a string.
// TODO(rnystrom): Have something similar for in-memory binary assets.
class _StringAsset extends Asset {
  final String _contents;

  _StringAsset(AssetId id, this._contents)
      : super(id);

  Future<String> readAsString() => new Future.value(_contents);

  // TODO(rnystrom): Implement this and handle encoding.
  Stream<List<int>> read() => throw new UnimplementedError();

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

  Object serialize() => ["string", id.serialize(), _contents];

  String _escape(String string) {
    return string
        .replaceAll("\"", r'\"')
        .replaceAll("\n", r"\n")
        .replaceAll("\r", r"\r")
        .replaceAll("\t", r"\t");
  }
}

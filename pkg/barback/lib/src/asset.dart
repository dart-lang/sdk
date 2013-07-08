// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset;

import 'dart:async';
import 'dart:io';

/// A blob of content.
///
/// Assets may come from the file system, or as the output of a [Transformer].
/// They are identified by [AssetId].
abstract class Asset {
  factory Asset.fromFile(File file) {
    return new _FileAsset(file);
  }

  factory Asset.fromString(String content) {
    return new _StringAsset(content);
  }

  factory Asset.fromPath(String path) {
    return new _FileAsset(new File(path));
  }

  // TODO(rnystrom): This prevents users from defining their own
  // implementations of Asset. Use serialization package instead.
  factory Asset.deserialize(data) {
    // TODO(rnystrom): Handle errors.
    switch (data[0]) {
      case "file": return new _FileAsset(new File(data[1])); break;
      case "string": return new _StringAsset(data[1]); break;
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
class _FileAsset implements Asset {
  final File _file;
  _FileAsset(this._file);

  Future<String> readAsString() => _file.readAsString();
  Stream<List<int>> read() => _file.openRead();

  String toString() => 'File "${_file.path}"';

  Object serialize() => ["file", _file.path];
}

/// An asset whose data is stored in a string.
// TODO(rnystrom): Have something similar for in-memory binary assets.
class _StringAsset implements Asset {
  final String _contents;

  _StringAsset(this._contents);

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

  Object serialize() => ["string", _contents];

  String _escape(String string) {
    return string
        .replaceAll("\"", r'\"')
        .replaceAll("\n", r"\n")
        .replaceAll("\r", r"\r")
        .replaceAll("\t", r"\t");
  }
}

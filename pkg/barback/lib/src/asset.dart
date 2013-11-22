// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'asset_id.dart';
import 'internal_asset.dart';

/// A blob of content.
///
/// Assets may come from the file system, or as the output of a [Transformer].
/// They are identified by [AssetId].
///
/// Custom implementations of [Asset] are not currently supported.
abstract class Asset {
  /// The ID for this asset.
  final AssetId id;

  factory Asset.fromBytes(AssetId id, List<int> bytes) =>
      new BinaryAsset(id, bytes);

  factory Asset.fromFile(AssetId id, File file) =>
      new FileAsset(id, file.path);

  factory Asset.fromString(AssetId id, String content) =>
      new StringAsset(id, content);

  factory Asset.fromPath(AssetId id, String path) =>
      new FileAsset(id, path);

  factory Asset.fromStream(AssetId id, Stream<List<int>> stream) =>
      new StreamAsset(id, stream);

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

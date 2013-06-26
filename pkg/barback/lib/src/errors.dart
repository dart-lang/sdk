// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.errors;

import 'dart:async';
import 'dart:io';

import 'asset_id.dart';

/// Error thrown when an asset with [id] cannot be found.
class AssetNotFoundException implements Exception {
  final AssetId id;

  AssetNotFoundException(this.id);

  String toString() => "Could not find asset $id.";
}

/// Error thrown when two transformers both output an asset with [id].
class AssetCollisionException implements Exception {
  final AssetId id;

  AssetCollisionException(this.id);

  String toString() => "Got collision on asset $id.";
}

/// Error thrown when a transformer requests an input [id] which cannot be
/// found.
class MissingInputException implements Exception {
  final AssetId id;

  MissingInputException(this.id);

  String toString() => "Missing input $id.";
}

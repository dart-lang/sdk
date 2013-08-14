// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.errors;

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'asset_id.dart';
import 'transformer.dart';

/// Error thrown when an asset with [id] cannot be found.
class AssetNotFoundException implements Exception {
  final AssetId id;

  AssetNotFoundException(this.id);

  String toString() => "Could not find asset $id.";
}

/// The interface for exceptions from the barback graph or its transformers.
///
/// These exceptions are never produced by programming errors in barback.
abstract class BarbackException implements Exception {}

/// Error thrown when two or more transformers both output an asset with [id].
class AssetCollisionException implements BarbackException {
  /// All the transforms that output an asset with [id].
  final Set<TransformInfo> transforms;
  final AssetId id;

  AssetCollisionException(Iterable<TransformInfo> transforms, this.id)
      : transforms = new Set.from(transforms);

  String toString() => "Transforms $transforms all emitted asset $id.";
}

/// Error thrown when a transformer requests an input [id] which cannot be
/// found.
class MissingInputException implements BarbackException {
  /// The transform that requested [id].
  final TransformInfo transform;
  final AssetId id;

  MissingInputException(this.transform, this.id);

  String toString() => "Transform $transform tried to load missing input $id.";
}

/// Error thrown when a transformer outputs an asset to a different package than
/// the primary input's.
class InvalidOutputException implements BarbackException {
  /// The transform that output the asset.
  final TransformInfo transform;
  final AssetId id;

  InvalidOutputException(this.transform, this.id);

  String toString() => "Transform $transform emitted $id, which wasn't in the "
      "same package (${transform.primaryId.package}).";
}

/// Error wrapping an exception thrown by a transform.
class TransformerException implements BarbackException {
  /// The transform that threw the exception.
  final TransformInfo transform;

  /// The wrapped exception.
  final error;

  TransformerException(this.transform, this.error);

  String toString() => "Transform $transform threw error: $error\n" +
    new Trace.from(getAttachedStackTrace(error)).terse.toString();
}

/// Error thrown when a source asset [id] fails to load.
///
/// This can be thrown either because the source asset was expected to exist and
/// did not or because reading it failed somehow.
class AssetLoadException implements BarbackException {
  final AssetId id;

  /// The wrapped exception.
  final error;

  AssetLoadException(this.id, this.error);

  String toString() => "Failed to load source asset $id: $error\n"
      "${new Trace.from(getAttachedStackTrace(error)).terse}";
}

/// Information about a single transform in the barback graph.
///
/// Identifies a single transformation in the barback graph.
///
/// A transformation is uniquely identified by the ID of its primary input, and
/// the transformer that is applied to it.
class TransformInfo {
  /// The transformer that's run for this transform.
  final Transformer transformer;

  /// The id of this transform's primary asset.
  final AssetId primaryId;

  TransformInfo(this.transformer, this.primaryId);

  bool operator==(other) =>
      other is TransformInfo &&
      other.transformer == transformer &&
      other.primaryId == primaryId;

  int get hashCode => transformer.hashCode ^ primaryId.hashCode;

  String toString() => "$transformer on $primaryId";
}

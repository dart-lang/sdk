// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.errors;

import 'package:stack_trace/stack_trace.dart';

import 'asset_id.dart';
import 'transformer.dart';
import 'utils.dart';

/// Error thrown when an asset with [id] cannot be found.
class AssetNotFoundException implements Exception {
  final AssetId id;

  AssetNotFoundException(this.id);

  String toString() => "Could not find asset $id.";
}

/// Replaces any occurrences of [AggregateException] in [errors] with the list
/// of errors it contains.
Iterable<BarbackException> flattenAggregateExceptions(
    Iterable<BarbackException> errors) {
  return errors.expand((error) {
    if (error is! AggregateException) return [error];
    return error.errors;
  });
}

/// The interface for exceptions from the barback graph or its transformers.
///
/// These exceptions are never produced by programming errors in barback.
abstract class BarbackException implements Exception {
  /// Takes a collection of [BarbackExceptions] and returns a single exception
  /// that contains them all.
  ///
  /// If [errors] is empty, returns `null`. If it only has one error, that
  /// error is returned. Otherwise, an [AggregateException] is returned.
  static BarbackException aggregate(Iterable<BarbackException> errors) {
    if (errors.isEmpty) return null;
    if (errors.length == 1) return errors.single;
    return new AggregateException(errors);
  }
}

/// An error that wraps a collection of other [BarbackException]s.
///
/// It implicitly flattens any [AggregateException]s that occur in the list of
/// exceptions it wraps.
class AggregateException implements BarbackException {
  final Set<BarbackException> errors;

  AggregateException(Iterable<BarbackException> errors)
      : errors = flattenAggregateExceptions(errors).toSet();

  String toString() {
    var buffer = new StringBuffer();
    buffer.writeln("Multiple errors occurred:\n");

    for (var error in errors) {
      buffer.writeln(prefixLines(error.toString(),
                                 prefix: "  ", firstPrefix: "- "));
    }

    return buffer.toString();
  }
}

/// Error thrown when two or more transformers both output an asset with [id].
class AssetCollisionException implements BarbackException {
  /// All the transforms that output an asset with [id].
  ///
  /// If this only contains a single transform, that indicates that a
  /// transformer produced an output that collides with a source asset or an
  /// asset from a previous phase.
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

/// Base class for an error that wraps another.
abstract class _WrappedException implements BarbackException {
  /// The wrapped exception.
  final error;
  final Chain stackTrace;

  _WrappedException(error, StackTrace stackTrace)
      : this.error = error,
        this.stackTrace = _getChain(error, stackTrace);

  String get _message;

  String toString() {
    var result = "$_message: $error";
    if (stackTrace != null) result = "$result\n${stackTrace.terse}";
    return result;
  }
}

/// Returns the stack chain for [error] and [stackTrace].
Chain _getChain(error, StackTrace stackTrace) {
  if (error is Error && stackTrace == null) stackTrace = error.stackTrace;
  if (stackTrace != null) return new Chain.forTrace(stackTrace);
  return null;
}

/// Error wrapping an exception thrown by a transform.
class TransformerException extends _WrappedException {
  /// The transform that threw the exception.
  final TransformInfo transform;

  TransformerException(this.transform, error, StackTrace stackTrace)
      : super(error, stackTrace);

  String get _message => "Transform $transform threw error";
}

/// Error thrown when a source asset [id] fails to load.
///
/// This can be thrown either because the source asset was expected to exist and
/// did not or because reading it failed somehow.
class AssetLoadException extends _WrappedException {
  final AssetId id;

  AssetLoadException(this.id, error, [StackTrace stackTrace])
      : super(error, stackTrace);

  String get _message => "Failed to load source asset $id";
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

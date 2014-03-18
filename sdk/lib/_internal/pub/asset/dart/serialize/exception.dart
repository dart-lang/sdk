// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.exception;

import 'package:barback/barback.dart';
import 'package:stack_trace/stack_trace.dart';

import '../utils.dart';

/// An exception that was originally raised in another isolate.
///
/// Exception objects can't cross isolate boundaries in general, so this class
/// wraps as much information as can be consistently serialized.
class CrossIsolateException implements Exception {
  /// The name of the type of exception thrown.
  ///
  /// This is the return value of [error.runtimeType.toString()]. Keep in mind
  /// that objects in different libraries may have the same type name.
  final String type;

  /// The exception's message, or its [toString] if it didn't expose a `message`
  /// property.
  final String message;

  /// The exception's stack chain, or `null` if no stack chain was available.
  final Chain stackTrace;

  /// Loads a [CrossIsolateException] from a serialized representation.
  ///
  /// [error] should be the result of [CrossIsolateException.serialize].
  CrossIsolateException.deserialize(Map error)
      : type = error['type'],
        message = error['message'],
        stackTrace = error['stack'] == null ? null :
            new Chain.parse(error['stack']);

  /// Serializes [error] to an object that can safely be passed across isolate
  /// boundaries.
  static Map serialize(error, [StackTrace stack]) {
    if (stack == null && error is Error) stack = error.stackTrace;
    return {
      'type': error.runtimeType.toString(),
      'message': getErrorMessage(error),
      'stack': stack == null ? null : new Chain.forTrace(stack).toString()
    };
  }

  String toString() => "$message\n$stackTrace";
}

/// An [AssetNotFoundException] that was originally raised in another isolate. 
class _CrossIsolateAssetNotFoundException extends CrossIsolateException
    implements AssetNotFoundException {
  final AssetId id;

  String get message => "Could not find asset $id.";

  /// Loads a [_CrossIsolateAssetNotFoundException] from a serialized
  /// representation.
  ///
  /// [error] should be the result of
  /// [_CrossIsolateAssetNotFoundException.serialize].
  _CrossIsolateAssetNotFoundException.deserialize(Map error)
      : id = new AssetId(error['package'], error['path']),
        super.deserialize(error);

  /// Serializes [error] to an object that can safely be passed across isolate
  /// boundaries.
  static Map serialize(AssetNotFoundException error, [StackTrace stack]) {
    var map = CrossIsolateException.serialize(error);
    map['package'] = error.id.package;
    map['path'] = error.id.path;
    return map;
  }
}

/// Serializes [error] to an object that can safely be passed across isolate
/// boundaries.
///
/// This handles [AssetNotFoundException]s specially, ensuring that their
/// metadata is preserved.
Map serializeException(error, [StackTrace stack]) {
  if (error is AssetNotFoundException) {
    return _CrossIsolateAssetNotFoundException.serialize(error, stack);
  } else {
    return CrossIsolateException.serialize(error, stack);
  }
}

/// Loads an exception from a serialized representation.
///
/// This handles [AssetNotFoundException]s specially, ensuring that their
/// metadata is preserved.
CrossIsolateException deserializeException(Map error) {
  if (error['type'] == 'AssetNotFoundException') {
    return new _CrossIsolateAssetNotFoundException.deserialize(error);
  } else {
    return new CrossIsolateException.deserialize(error);
  }
}

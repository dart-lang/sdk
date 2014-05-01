// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.cascade;

import 'handler.dart';
import 'response.dart';
import 'util.dart';

/// A typedef for [Cascade._shouldCascade].
typedef bool _ShouldCascade(Response response);

/// A helper that calls several handlers in sequence and returns the first
/// acceptable response.
///
/// By default, a response is considered acceptable if it has a status other
/// than 404 or 405; other statuses indicate that the handler understood the
/// request.
///
/// If all handlers return unacceptable responses, the final response will be
/// returned.
///
///     var handler = new Cascade()
///         .add(webSocketHandler)
///         .add(staticFileHandler)
///         .add(application)
///         .handler;
class Cascade {
  /// The function used to determine whether the cascade should continue on to
  /// the next handler.
  final _ShouldCascade _shouldCascade;

  final Cascade _parent;
  final Handler _handler;

  /// Creates a new, empty cascade.
  ///
  /// If [statusCodes] is passed, responses with those status codes are
  /// considered unacceptable. If [shouldCascade] is passed, responses for which
  /// it returns `true` are considered unacceptale. [statusCode] and
  /// [shouldCascade] may not both be passed.
  Cascade({Iterable<int> statusCodes, bool shouldCascade(Response response)})
      : _shouldCascade = _computeShouldCascade(statusCodes, shouldCascade),
        _parent = null,
        _handler = null {
    if (statusCodes != null && shouldCascade != null) {
      throw new ArgumentError("statusCodes and shouldCascade may not both be "
          "passed.");
    }
  }

  Cascade._(this._parent, this._handler, this._shouldCascade);

  /// Returns a new cascade with [handler] added to the end.
  ///
  /// [handler] will only be called if all previous handlers in the cascade
  /// return unacceptable responses.
  Cascade add(Handler handler) => new Cascade._(this, handler, _shouldCascade);

  /// Exposes this cascade as a single handler.
  ///
  /// This handler will call each inner handler in the cascade until one returns
  /// an acceptable response, and return that. If no inner handlers return an
  /// acceptable response, this will return the final response.
  Handler get handler {
    if (_handler == null) {
      throw new StateError("Can't get a handler for a cascade with no inner "
          "handlers.");
    }

    return (request) {
      if (_parent._handler == null) return _handler(request);
      return syncFuture(() => _parent.handler(request)).then((response) {
        if (_shouldCascade(response)) return _handler(request);
        return response;
      });
    };
  }
}

/// Computes the [Cascade._shouldCascade] function based on the user's
/// parameters.
Function _computeShouldCascade(Iterable<int> statusCodes,
    Function shouldCascade) {
  if (shouldCascade != null) return shouldCascade;
  if (statusCodes == null) statusCodes = [404, 405];
  statusCodes = statusCodes.toSet();
  return (response) => statusCodes.contains(response.statusCode);
}

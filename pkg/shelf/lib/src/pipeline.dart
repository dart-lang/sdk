// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.pipeline;

import 'handler.dart';
import 'middleware.dart';

/// A helper that makes it easy to compose a set of [Middleware] and a
/// [Handler].
///
///     var handler = const Pipeline()
///         .addMiddleware(loggingMiddleware)
///         .addMiddleware(cachingMiddleware)
///         .addHandler(application);
class Pipeline {
  final Pipeline _parent;
  final Middleware _middleware;

  const Pipeline()
      : _middleware = null,
        _parent = null;

  Pipeline._(this._middleware, this._parent);

  /// Returns a new [Pipeline] with [middleware] added to the existing set of
  /// [Middleware].
  ///
  /// [middleware] will be the last [Middleware] to process a request and
  /// the first to process a response.
  Pipeline addMiddleware(Middleware middleware) =>
      new Pipeline._(middleware, this);

  /// Returns a new [Handler] with [handler] as the final processor of a
  /// [Request] if all of the middleware in the pipeline have passed the request
  /// through.
  Handler addHandler(Handler handler) {
    if (_middleware == null) return handler;
    return _parent.addHandler(_middleware(handler));
  }

  /// Exposes this pipeline of [Middleware] as a single middleware instance.
  Middleware get middleware => addHandler;
}

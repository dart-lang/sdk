// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

_invokeErrorHandler(
    Function errorHandler, Object error, StackTrace stackTrace) {
  var handler = errorHandler; // Rename to avoid promotion.
  if (handler is ZoneBinaryCallback<dynamic, Never, Never>) {
    // Dynamic invocation because we don't know the actual type of the
    // first argument or the error object, but we should successfully call
    // the handler if they match up.
    return errorHandler(error, stackTrace);
  } else {
    return errorHandler(error);
  }
}

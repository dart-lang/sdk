// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

class LateInitializationErrorImpl extends Error
    implements LateInitializationError {
  final String? _message;

  LateInitializationErrorImpl([this._message]);

  String toString() {
    var message = _message;
    return (message != null)
        ? "LateInitializationError: $message"
        : "LateInitializationError";
  }
}

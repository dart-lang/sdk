// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

class LateError extends Error {
  final String? _message;

  LateError([this._message]);

  // The constructor names have been deliberately shortened to reduce the size
  // of unminified code as used by DDC.

  @pragma("vm:entry-point")
  LateError.fieldADI(String fieldName)
      : _message =
            "Field '$fieldName' has been assigned during initialization.";

  LateError.localADI(String localName)
      : _message =
            "Local '$localName' has been assigned during initialization.";

  @pragma("vm:entry-point")
  LateError.fieldNI(String fieldName)
      : _message = "Field '${fieldName}' has not been initialized.";

  LateError.localNI(String localName)
      : _message = "Local '${localName}' has not been initialized.";

  LateError.fieldAI(String fieldName)
      : _message = "Field '${fieldName}' has already been initialized.";

  LateError.localAI(String localName)
      : _message = "Local '${localName}' has already been initialized.";

  String toString() {
    var message = _message;
    return (message != null)
        ? "LateInitializationError: $message"
        : "LateInitializationError";
  }
}

class ReachabilityError extends Error {
  final String? _message;

  ReachabilityError([this._message]);

  String toString() {
    var message = _message;
    return (message != null)
        ? "ReachabilityError: $message"
        : "ReachabilityError";
  }
}

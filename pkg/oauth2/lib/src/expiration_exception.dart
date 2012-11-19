// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library expiration_exception;

import 'dart:io';

/// An exception raised when attempting to use expired OAuth2 credentials.
class ExpirationException implements Exception {
  /// The expired credentials.
  final Credentials credentials;

  /// Creates an ExpirationException.
  ExpirationException(this.credentials);

  /// Provides a string description of the ExpirationException.
  String toString() =>
    "OAuth2 credentials have expired and can't be refreshed.";
}

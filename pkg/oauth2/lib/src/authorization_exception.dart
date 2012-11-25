// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library authorization_exception;

import 'dart:io';
import 'dart:uri';

/// An exception raised when OAuth2 authorization fails.
class AuthorizationException implements Exception {
  /// The name of the error. Possible names are enumerated in [the spec][].
  ///
  /// [the spec]: http://tools.ietf.org/html/draft-ietf-oauth-v2-31#section-5.2
  final String error;

  /// The description of the error, provided by the server. Defaults to null.
  final String description;

  /// A URI for a page that describes the error in more detail, provided by the
  /// server. Defaults to null.
  final Uri uri;

  /// Creates an AuthorizationException.
  AuthorizationException(this.error, this.description, this.uri);

  /// Provides a string description of the AuthorizationException.
  String toString() {
    var header = 'OAuth authorization error ($error)';
    if (description != null) {
      header = '$header: $description';
    } else if (uri != null) {
      header = '$header: $uri';
    }
    return '$header.';
  }
}

// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

/// A class for converting between internal analyzer file paths/references and
/// URIs used by clients.
///
/// The simplest form of this class simple translates between file paths and
/// `file://` URIs but depending on client capabilities some paths/URIs may be
/// re-written to support features like virtual files for macros.
class ClientUriConverter {
  final path.Context _context;

  /// Creates a converter that does nothing besides translation between file
  /// paths and `file://` URIs.
  ClientUriConverter.noop(this._context);

  /// Converts a URI provided by the client into a file path/reference that can
  /// be used by the analyzer.
  String fromClientUri(Uri uri) {
    return _context.fromUri(uri);
  }

  /// Converts a file path/reference from the analyzer into a URI to be sent to
  /// the client.
  Uri toClientUri(String filePath) {
    return _context.toUri(filePath);
  }
}

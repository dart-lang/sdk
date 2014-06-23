// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.exception;

import 'package:source_maps/source_maps.dart';

/// An exception thrown by a [StringScanner] that failed to parse a string.
class StringScannerException extends SpanFormatException {
  /// The source string being parsed.
  final String string;

  /// The URL of the source file being parsed.
  ///
  /// This may be `null`, indicating that the source URL is unknown.
  final Uri sourceUrl;

  StringScannerException(String message, this.string, this.sourceUrl, Span span)
      : super(message, span);
}
